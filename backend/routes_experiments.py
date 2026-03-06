from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
import models

from ml_features import build_feature_vector
from ml_model import LotAnomalyModel

router = APIRouter(prefix="/experiments", tags=["experiments"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        
@router.get("/contamination")
def experiment_contamination(db: Session = Depends(get_db)):
    contamination_values = [0.02, 0.05, 0.10, 0.15, 0.20]
    
    lots = db.query(models.InventoryLot).all()
    
    X = []
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue
        X.append(build_feature_vector(lot, item))
        
    results = []
    
    for c in contamination_values:
        model = LotAnomalyModel()
        model.train(X, contamination=c)        
        
        labels, scores = model.predict(X)
        
        anomaly_count = sum(1 for l in labels if l == -1)
        
        results.append({
            "contamination": c,
            "total_lots": len(labels),
            "anomalies_detected": anomaly_count
        })
        
    return results

@router.get("/dataset-size")
def experiment_dataset_size(db: Session = Depends(get_db)):
    lots = db.query(models.InventoryLot).all()
    sizes = [20, 50, 100, 200]
    
    results = []
    
    for size in sizes:
        subset = lots[:size]
        
        X = []
        for lot in subset:
            item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
            if not item:
                continue
            X.append(build_feature_vector(lot, item))
            
        if len(X) < 10:
            continue
        
        model = LotAnomalyModel()
        model.train(X, contamination=0.10)
        
        labels, scores = model.predict(X)
        
        anomaly_count = sum(1 for l in labels if l == -1)
        
        results.append({
            "dataset_size": size,
            "anomalies_detected": anomaly_count
        })
        
    return results
