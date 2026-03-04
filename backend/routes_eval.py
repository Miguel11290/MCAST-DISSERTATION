from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
import models
import schemas

from routes_safety import evaluate_lot
from ml_features import build_feature_vector
from ml_model import MODEL

router = APIRouter(prefix="/eval", tags=["evaluation"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class EvalRow(schemas.BaseModel):
    lot_id: int
    item_id: int
    item_name: str
    baseline_status: str
    baseline_reasons: list[str]
    ml_is_anomaly: bool | None
    ml_score: float | None
    ml_signals: list[str] | None

    class Config:
        orm_mode = True
        from_attributes = True

def simple_explanations(features: list[float]) -> list[str]:
    qty, max_safe, ratio, sd, hazard_num, loc_num = features
    signals = []
    if max_safe > 0 and ratio > 1.0:
        signals.append("Quantity exceeds safe limit (ratio > 1.0)")
    if sd > 30:
        signals.append("Long storage duration (> 30 days)")
    if qty > 100:
        signals.append("High quantity value")
    return signals[:3]

@router.get("/lots", response_model=list[EvalRow])
def compare_baseline_vs_ml(db: Session = Depends(get_db)):
    lots = db.query(models.InventoryLot).order_by(models.InventoryLot.id.desc()).all()
    results = []

    ml_ready = MODEL.is_trained

    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if not item:
            continue

        # baseline
        base = evaluate_lot(lot, item)

        # ml evaluation
        ml_is_anomaly = None
        ml_score = None
        ml_signals = None

        if ml_ready:
            feats = build_feature_vector(lot, item)
            label, score = MODEL.predict([feats])
            ml_is_anomaly = (label[0] == -1)
            ml_score = float(score[0])
            ml_signals = simple_explanations(feats)

        results.append(EvalRow(
            lot_id=lot.id,
            item_id=item.id,
            item_name=item.name,
            baseline_status=base.status,
            baseline_reasons=base.reasons,
            ml_is_anomaly=ml_is_anomaly,
            ml_score=ml_score,
            ml_signals=ml_signals
        ))

    return results