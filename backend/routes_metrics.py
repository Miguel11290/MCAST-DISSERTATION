from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models

from routes_safety import evaluate_lot
from ml_features import build_feature_vector
from ml_model import MODEL
import numpy as np

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
    
@router.get("/roc-sweep")
def roc_sweep(db: Session = Depends(get_db), points: int = 15):
    # Produces a ROC-like sweep by thresholding anomaly scores
    # Isolation Forest scores are "normality" scores (higher is more normal), so invert it to get anomaly_strength
    if not MODEL.is_trained:
        raise HTTPException(status_code=400, detail="Train ML first: POST /ml/train")
    
    lots = db.query(models.InventoryLot).all()

    y_true = []
    anomaly_strength = []
    
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue
        
        base = evaluate_lot(lot, item)
        y_true.append(1 if base.status == "UNSAFE" else 0)
        
        feats = build_feature_vector(lot, item)
        label, score = MODEL.predict([feats])
        # score: higher normal -> invert to anomaly strength
        anomaly_strength.append(float(-score[0]))
        
    if len(anomaly_strength) < 5:
        return {"error": "Not enough data"}
    
    strengths = np.array(anomaly_strength)
    thresholds = np.linspace(strengths.min(), strengths.max(), num=max(points, 5))
    
    curve = []
    for t in thresholds:
        TP = FP = TN = FN = 0
        for gt, s in zip(y_true, strengths):
            pred = 1 if s >= t else 0
            if gt == 1 and pred == 1:
                TP += 1
            elif gt == 0 and pred == 1:
                FP += 1
            elif gt == 0 and pred == 0:
                TN += 1
            elif gt == 1 and pred == 0:
                FN += 1
                
        tpr = TP/(TP + FN) if (TP + FN) else 0.0
        fpr = FP/(FP + TN) if (FP + TN) else 0.0
        curve.append({"threshold": float(t), "TPR": float(tpr), "FPR": float(fpr)})
        
    return {"points": curve}