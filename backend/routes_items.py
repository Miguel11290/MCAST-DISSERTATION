from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from audit_service import record_audit_log
from auth import get_current_user, require_roles
from database import SessionLocal
from models import User
import models
import schemas

router = APIRouter(
    prefix="/items",
    tags=["items"],
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def item_to_dict(item: models.Item) -> dict:
    return {
        "id": item.id,
        "name": item.name,
        "description": item.description,
        "hazard_class": item.hazard_class,
        "unit": item.unit,
        "max_safe_quantity": item.max_safe_quantity,
        "storage_group": item.storage_group,
    }


@router.post(
    "/",
    response_model=schemas.ItemRead,
    status_code=status.HTTP_201_CREATED,
)
def create_item(
    item: schemas.ItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(
            "admin",
            "inventory_officer",
        )
    ),
):
    db_item = models.Item(
        name=item.name,
        description=item.description,
        hazard_class=item.hazard_class,
        unit=item.unit,
        max_safe_quantity=item.max_safe_quantity,
        storage_group=item.storage_group,
    )

    try:
        db.add(db_item)
        db.flush()

        record_audit_log(
            db,
            user=current_user,
            action="CREATE",
            entity_type="Item",
            entity_id=db_item.id,
            description=f"Created item '{db_item.name}'.",
            new_values=item_to_dict(db_item),
        )

        db.commit()
        db.refresh(db_item)

        return db_item

    except Exception:
        db.rollback()
        raise


@router.get(
    "/",
    response_model=list[schemas.ItemRead],
)
def list_items(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return (
        db.query(models.Item)
        .order_by(models.Item.id.desc())
        .all()
    )


@router.get(
    "/{item_id}",
    response_model=schemas.ItemRead,
)
def get_item(
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

    return item


@router.put(
    "/{item_id}",
    response_model=schemas.ItemRead,
)
def update_item(
    item_id: int,
    payload: schemas.ItemUpdate,
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
        .filter(models.Item.id == item_id)
        .first()
    )

    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found.",
        )

    old_values = item_to_dict(item)

    update_data = payload.model_dump(
        exclude_unset=True,
        exclude_none=True,
    )

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No update values were provided.",
        )

    try:
        for field, value in update_data.items():
            setattr(item, field, value)

        db.flush()

        record_audit_log(
            db,
            user=current_user,
            action="UPDATE",
            entity_type="Item",
            entity_id=item.id,
            description=f"Updated item '{item.name}'.",
            old_values=old_values,
            new_values=item_to_dict(item),
        )

        db.commit()
        db.refresh(item)

        return item

    except Exception:
        db.rollback()
        raise


@router.delete(
    "/{item_id}",
    status_code=status.HTTP_200_OK,
)
def delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("admin")
    ),
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

    old_values = item_to_dict(item)
    item_name = item.name

    try:
        db.delete(item)

        record_audit_log(
            db,
            user=current_user,
            action="DELETE",
            entity_type="Item",
            entity_id=item_id,
            description=f"Deleted item '{item_name}'.",
            old_values=old_values,
        )

        db.commit()

        return {
            "deleted": True,
            "item_id": item_id,
        }

    except Exception:
        db.rollback()
        raise