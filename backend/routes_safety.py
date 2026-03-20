from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models
import schemas
from safety_rules import get_storage_limit, days_since
from compatibility_rules import are_incompatible

router = APIRouter(prefix="/safety", tags=["safety"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def evaluate_lot(
    lot: models.InventoryLot,
    item: models.Item,
    location_context: list[tuple[models.InventoryLot, models.Item]] | None = None
) -> schemas.SafetyCheckResult:
    reasons: list[str] = []
    conflicting_lot_ids: list[int] = []
    status = "SAFE"

    # Storage duration rule
    storage_days = days_since(lot.received_at)
    storage_limit = get_storage_limit(item.hazard_class)

    if storage_days > storage_limit:
        status = "WARNING"
        reasons.append(
            f"Storage duration exceeded limit ({storage_days} > {storage_limit} days)"
        )

    # Quantity threshold rule
    if item.max_safe_quantity is not None:
        if lot.quantity > item.max_safe_quantity:
            status = "UNSAFE"
            reasons.append(
                f"Lot quantity exceeds max safe quantity ({lot.quantity} > {item.max_safe_quantity})"
            )

    # Missing classification warning
    if not item.hazard_class:
        if status == "SAFE":
            status = "WARNING"
        reasons.append("Item hazard class is not specified")

    # Compatibility rule: same location, incompatible storage groups
    if location_context:
        for other_lot, other_item in location_context:
            if other_lot.id == lot.id:
                continue

            if are_incompatible(item.storage_group, other_item.storage_group):
                status = "UNSAFE"
                reasons.append(
                    f"Incompatible storage group with lot {other_lot.id} in same location"
                )
                conflicting_lot_ids.append(other_lot.id)

    return schemas.SafetyCheckResult(
        lot_id=lot.id,
        item_id=item.id,
        status=status,
        reasons=reasons,
        quantity=lot.quantity,
        max_safe_quantity=item.max_safe_quantity,
        received_at=lot.received_at,
        storage_days=storage_days,
        location=lot.location,
        conflicting_lot_ids=conflicting_lot_ids
    )


@router.get("/lots", response_model=list[schemas.SafetyCheckResult])
def evaluate_all_lots(db: Session = Depends(get_db)):
    lots = db.query(models.InventoryLot).order_by(models.InventoryLot.id.desc()).all()

    enriched_lots: list[tuple[models.InventoryLot, models.Item]] = []
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if item:
            enriched_lots.append((lot, item))

    # Group lots by location
    lots_by_location: dict[str, list[tuple[models.InventoryLot, models.Item]]] = {}
    for lot, item in enriched_lots:
        location_key = lot.location or "UNKNOWN"
        if location_key not in lots_by_location:
            lots_by_location[location_key] = []
        lots_by_location[location_key].append((lot, item))

    results = []
    for lot, item in enriched_lots:
        location_key = lot.location or "UNKNOWN"
        location_context = lots_by_location.get(location_key, [])
        results.append(evaluate_lot(lot, item, location_context=location_context))

    return results


@router.get("/lots/{lot_id}", response_model=schemas.SafetyCheckResult)
def evaluate_single_lot(lot_id: int, db: Session = Depends(get_db)):
    lot = db.query(models.InventoryLot).filter(models.InventoryLot.id == lot_id).first()
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found")

    item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found for this lot")

    # Build location context for this lot only
    same_location_lots = db.query(models.InventoryLot).filter(
        models.InventoryLot.location == lot.location
    ).all()

    location_context: list[tuple[models.InventoryLot, models.Item]] = []
    for other_lot in same_location_lots:
        other_item = db.query(models.Item).filter(
            models.Item.id == other_lot.item_id
        ).first()
        if other_item:
            location_context.append((other_lot, other_item))

    return evaluate_lot(lot, item, location_context=location_context)