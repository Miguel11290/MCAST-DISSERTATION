from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models
import schemas
from safety_rules import get_storage_limit, days_since

router = APIRouter(prefix="/safety", tags=["safety"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def evaluate_lot(lot: models.InventoryLot, item: models.Item) -> schemas.SafetyCheckResult:
    reasons: list[str] = []
    status = "SAFE"

    #Storage duration rule
    storage_days = days_since(lot.received_at)
    storage_limit = get_storage_limit(item.hazard_class)

    if storage_days > storage_limit:
        status = "WARNING"
        reasons.append(f"Storage duration exceeded limit ({storage_days} > {storage_limit} days)")

    # Quantity threshold rule
    if item.max_safe_quantity is not None:
        if lot.quantity > item.max_safe_quantity:
            status = "UNSAFE"
            reasons.append(f"Lot quantity exceeds max safe quantity ({lot.quantity} > {item.max_safe_quantity})")

    # Missing classification warining
    if not item.hazard_class:
        if status == "SAFE":
            status = "WARNING"
        reasons.append("Item hazard class is not specified")

    return schemas.SafetyCheckResult(
        lot_id=lot.id,
        item_id=item.id,
        status=status,
        reasons=reasons,
        quantity=lot.quantity,
        max_safe_quantity=item.max_safe_quantity,
        received_at=lot.received_at,
        storage_days=storage_days
    )

@router.get("/lots", response_model=list[schemas.SafetyCheckResult])
def evaluate_all_lots(db: Session = Depends(get_db)):
    lots = db.query(models.InventoryLot).order_by(models.InventoryLot.id.desc()).all()
    results = []

    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue
        results.append(evaluate_lot(lot, item))

    return results

@router.get("/lots/{lot_id}", response_model=schemas.SafetyCheckResult)
def evaluate_single_lot(lot_id: int, db: Session = Depends(get_db)):
    lot = db.query(models.InventoryLot).filter(models.InventoryLot.id == lot_id).first()
    if not lot:
        raise HTTPException(status_code=404, detail="Lot not found")
    
    item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found for this lot")
    
    return evaluate_lot(lot, item)