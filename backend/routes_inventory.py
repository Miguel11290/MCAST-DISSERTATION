from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models
import schemas

router = APIRouter(prefix="/inventory", tags=["inventory"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/lots/", response_model=schemas.InventoryLotRead)
def create_lot(payload: schemas.InventoryLotCreate, db: Session = Depends(get_db)):
    item = db.query(models.Item).filter(models.Item.id == payload.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    lot = models.InventoryLot(
        item_id = payload.item_id,
        quantity = payload.quantity,
        location = payload.location,
    )
    db.add(lot)
    db.commit()
    db.refresh(lot)
    return lot

@router.get("/lots", response_model=list[schemas.InventoryLotRead])
def list_lots(db: Session = Depends(get_db)):
    return db.query(models.InventoryLot).order_by(models.InventoryLot.id.desc()).all()

@router.get("/lots/by-item/{item_id}", response_model=list[schemas.InventoryLotRead])
def list_lots_by_item(item_id: int, db: Session = Depends(get_db)):
    return db.query(models.InventoryLot).filter(models.InventoryLot.item_id == item_id).order_by(models.InventoryLot.id.desc()).all()