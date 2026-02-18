from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models

from routes_safety import evaluate_lot
from ml_features import build_feature_vector
from ml_model import MODEL

router = APIRouter(prefix="/metrics", tags=["metrics"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/ml-vs-baseline")
def ml_vs_baseline_metrics(db: Session = Depends(get_db)):
    if not MODEL.is_trained:
        raise HTTPException(status_code=400, detail="Train ML first: POST /ml/train")
    
    lots = db.query(models.InventoryLot).all()

    TP = FP = TN = FN = 0

    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue

        base = evaluate_lot(lot, item)
        y_true = (base.status == "UNSAFE") # proxy ground truth based on baseline

        feats = build_feature_vector(lot, item)
        label, score = MODEL.predict([feats])
        y_pred = (label[0] == -1)

        if y_true and y_pred:
            TP += 1
        elif (not y_true) and y_pred:
            FP += 1
        elif (not y_true) and (not y_pred):
            TN += 1
        elif y_true and (not y_pred):
            FN += 1

    precision = TP / (TP + FP) if (TP + FP) else 0.0
    recall = TP / (TP + FN) if (TP + FN) else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) else 0.0
    accuracy = (TP + TN) / (TP + TN + FP + FN) if (TP + TN + FP + FN) else 0.0

    return {
        "TP": TP, "FP": FP, "TN": TN, "FN": FN,
        "precision": precision,
        "recall": recall,
        "f1_score": f1,
        "accuracy": accuracy
    }