from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models
import schemas

from ml_features import build_feature_vector, FEATURE_NAMES
from ml_model import MODEL
from explain_ml import top_feature_contributions

router = APIRouter(prefix="/ml", tags=["ml"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def simple_explanations(features: list[float]) -> list[str]:
    # Lightweight explanations. Uses feature values to generate human-readable hints
    qty, max_safe, ratio, sd, hazard_num, loc_num = features
    signals = []

    if max_safe > 0 and ratio > 1.0:
        signals.append("Quantity exceeds safe limit (ratio > 1.0)")
    if sd > 30:
        signals.append("Long storage duration (> 30 days)")
    if qty > 0 and qty > 100:
        signals.append("High quantity value")
    if hazard_num >= 3.0:
        signals.append("Higher hazard class category")

    return signals[:3]  # limit to top 3 signals


@router.post("/train")
def train_model(contamination: float = 0.10, db: Session = Depends(get_db)):
    lots = db.query(models.InventoryLot).all()
    if len(lots) < 10:
        raise HTTPException(status_code=400, detail="Not enough lots to train (need at least ~10). Seed more data first.")

    X = []
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue
        X.append(build_feature_vector(lot, item))

    if len(X) < 10:
        raise HTTPException(status_code=400, detail="Not enough valid lot-item pairs to train.")

    MODEL.train(X, contamination=contamination)
    return {"trained": True, "samples": len(X), "contamination": contamination, "features": FEATURE_NAMES}


@router.get("/anomalies/lots", response_model=list[schemas.MLAnomalyResult])
def detect_anomalies(db: Session = Depends(get_db)):
    if not MODEL.is_trained:
        raise HTTPException(status_code=400, detail="Model not trained. Call POST /ml/train first.")

    lots = db.query(models.InventoryLot).order_by(models.InventoryLot.id.desc()).all()

    X = []
    meta = []
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue
        feats = build_feature_vector(lot, item)
        X.append(feats)
        meta.append((lot.id, item.id, feats))

    if not X:
        return []

    labels, scores = MODEL.predict(X)

    results = []
    for (lot_id, item_id, feats), label, score in zip(meta, labels, scores):
        is_anom = (label == -1)

        signals = simple_explanations(feats)

        # Explainability (Option C): add top deviating features (robust deviation)
        # Only attach when flagged as anomaly to keep output clean.
        if is_anom:
            top_feats = top_feature_contributions(X, feats, k=3)
            signals.extend([f"Top deviation: {f}" for f in top_feats])

        results.append(
            schemas.MLAnomalyResult(
                lot_id=lot_id,
                item_id=item_id,
                is_anomaly=is_anom,
                anomaly_score=float(score),
                top_signals=signals[:5],  # cap output
            )
        )

    return results