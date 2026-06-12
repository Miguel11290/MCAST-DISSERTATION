from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
import models
from ml_model import MODEL
from routes_safety import evaluate_lot

router = APIRouter(prefix="/summary", tags=["summary"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        
@router.get("/overview")
def overview_summary(db: Session = Depends(get_db)):
    lots = db.query(models.InventoryLot).all()
    
    total = 0
    safe = 0
    warning = 0
    unsafe = 0
    conflicts = 0   
    ml_anomalies = 0
    
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue
        
        total += 1
        base = evaluate_lot(lot, item)
        
        if base.status == "SAFE":
            safe += 1
        elif base.status == "WARNING":
            warning += 1
        elif base.status == "UNSAFE":
            unsafe += 1
            
        if base.conflicting_lot_ids:
            conflicts += 1
            
        if MODEL.is_trained:
            from ml_features import build_feature_vector
            feats = build_feature_vector(lot, item)
            labels, _ = MODEL.predict([feats])
            if labels[0] == -1:
                ml_anomalies += 1
                
    return {
        "total_lots": total,
        "safe": safe,
        "warning": warning,
        "unsafe": unsafe,
        "conflicts": conflicts,
        "ml_anomalies": ml_anomalies
    }