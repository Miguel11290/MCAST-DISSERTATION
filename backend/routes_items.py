from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models
import schemas

router = APIRouter(prefix="/items", tags=["items"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.ItemRead)
def create_item(item: schemas.ItemCreate, db: Session = Depends(get_db)):
    db_item = models.Item(
        name = item.name,
        description = item.description,
        hazard_class = item.hazard_class,
        unit = item.unit,
        max_safe_quantity = item.max_safe_quantity,
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@router.get("/", response_model=list[schemas.ItemRead])
def list_items(db: Session = Depends(get_db)):
    return db.query(models.Item).order_by(models.Item.id.desc()).all()

@router.get("/{item_id}", response_model=schemas.ItemRead)
def get_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@router.put("/{item_id}", response_model=schemas.ItemRead)
def update_item(item_id: int, payload: schemas.ItemUpdate, db: Session = Depends(get_db)):
    item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    if payload.name is not None:
        item.name = payload.name
    if payload.description is not None:
        item.description = payload.description
    if payload.hazard_class is not None:
        item.hazard_class = payload.hazard_class
    if payload.unit is not None:
        item.unit = payload.unit
    if payload.max_safe_quantity is not None:
        item.max_safe_quantity = payload.max_safe_quantity

    db.commit()
    db.refresh(item)
    return item

@router.delete("/{item_id}")
def delete_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"deleted": True}