from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from audit_service import record_audit_log
from auth import get_current_user, require_roles
from database import SessionLocal
from models import User
import models
import schemas

router = APIRouter(
    prefix="/inventory",
    tags=["inventory"],
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def lot_to_dict(lot: models.InventoryLot) -> dict:
    return {
        "id": lot.id,
        "item_id": lot.item_id,
        "quantity": lot.quantity,
        "location": lot.location,
        "received_at": (
            lot.received_at.isoformat()
            if lot.received_at is not None
            else None
        ),
        "scenario_type": lot.scenario_type,
    }


@router.post(
    "/lots/",
    response_model=schemas.InventoryLotRead,
    status_code=status.HTTP_201_CREATED,
)
def create_lot(
    payload: schemas.InventoryLotCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(
            "admin",
            "inventory_officer",
        )
    ),
):
    item = (
        db.query(models.Item)
        .filter(models.Item.id == payload.item_id)
        .first()
    )

    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found.",
        )

    lot = models.InventoryLot(
        item_id=payload.item_id,
        quantity=payload.quantity,
        location=payload.location,
    )

    try:
        db.add(lot)
        db.flush()

        record_audit_log(
            db,
            user=current_user,
            action="CREATE",
            entity_type="InventoryLot",
            entity_id=lot.id,
            description=(
                f"Created inventory lot {lot.id} "
                f"for item '{item.name}'."
            ),
            new_values=lot_to_dict(lot),
        )

        db.commit()
        db.refresh(lot)

        return lot

    except Exception:
        db.rollback()
        raise


@router.get(
    "/lots",
    response_model=list[schemas.InventoryLotRead],
)
def list_lots(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return (
        db.query(models.InventoryLot)
        .order_by(models.InventoryLot.id.desc())
        .all()
    )


@router.get(
    "/lots/by-item/{item_id}",
    response_model=list[schemas.InventoryLotRead],
)
def list_lots_by_item(
    item_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    item = (
        db.query(models.Item)
        .filter(models.Item.id == item_id)
        .first()
    )

    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found.",
        )

    return (
        db.query(models.InventoryLot)
        .filter(models.InventoryLot.item_id == item_id)
        .order_by(models.InventoryLot.id.desc())
        .all()
    )


@router.get(
    "/lots/{lot_id}",
    response_model=schemas.InventoryLotRead,
)
def get_lot(
    lot_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    lot = (
        db.query(models.InventoryLot)
        .filter(models.InventoryLot.id == lot_id)
        .first()
    )

    if lot is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inventory lot not found.",
        )

    return lot


@router.put(
    "/lots/{lot_id}",
    response_model=schemas.InventoryLotRead,
)
def update_lot(
    lot_id: int,
    payload: schemas.InventoryLotUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(
            "admin",
            "inventory_officer",
        )
    ),
):
    lot = (
        db.query(models.InventoryLot)
        .filter(models.InventoryLot.id == lot_id)
        .first()
    )

    if lot is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inventory lot not found.",
        )

    old_values = lot_to_dict(lot)

    update_data = payload.model_dump(
        exclude_unset=True,
        exclude_none=True,
    )

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No update values were provided.",
        )

    if "item_id" in update_data:
        item = (
            db.query(models.Item)
            .filter(models.Item.id == update_data["item_id"])
            .first()
        )

        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not found.",
            )

    try:
        for field, value in update_data.items():
            setattr(lot, field, value)

        db.flush()

        record_audit_log(
            db,
            user=current_user,
            action="UPDATE",
            entity_type="InventoryLot",
            entity_id=lot.id,
            description=f"Updated inventory lot {lot.id}.",
            old_values=old_values,
            new_values=lot_to_dict(lot),
        )

        db.commit()
        db.refresh(lot)

        return lot

    except Exception:
        db.rollback()
        raise


@router.delete(
    "/lots/{lot_id}",
    status_code=status.HTTP_200_OK,
)
def delete_lot(
    lot_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("admin")
    ),
):
    lot = (
        db.query(models.InventoryLot)
        .filter(models.InventoryLot.id == lot_id)
        .first()
    )

    if lot is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inventory lot not found.",
        )

    old_values = lot_to_dict(lot)

    try:
        db.delete(lot)

        record_audit_log(
            db,
            user=current_user,
            action="DELETE",
            entity_type="InventoryLot",
            entity_id=lot_id,
            description=f"Deleted inventory lot {lot_id}.",
            old_values=old_values,
        )

        db.commit()

        return {
            "deleted": True,
            "lot_id": lot_id,
        }

    except Exception:
        db.rollback()
        raise