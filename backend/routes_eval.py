from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
from pydantic import BaseModel
import models

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


class EvalRow(BaseModel):
    lot_id: int
    item_id: int
    item_name: str
    location: str | None = None
    conflicting_lot_ids: list[int] = []
    baseline_status: str
    baseline_reasons: list[str]
    triggered_rule_ids: list[str] = []
    ml_is_anomaly: bool | None = None
    ml_score: float | None = None
    ml_signals: list[str] | None = None

    class Config:
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

    # Build enriched list
    enriched_lots: list[tuple[models.InventoryLot, models.Item]] = []
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if item:
            enriched_lots.append((lot, item))

    # Group by location so compatibility checks can run
    lots_by_location: dict[str, list[tuple[models.InventoryLot, models.Item]]] = {}
    for lot, item in enriched_lots:
        location_key = lot.location or "UNKNOWN"
        if location_key not in lots_by_location:
            lots_by_location[location_key] = []
        lots_by_location[location_key].append((lot, item))

    results = []
    ml_ready = MODEL.is_trained

    for lot, item in enriched_lots:
        location_key = lot.location or "UNKNOWN"
        location_context = lots_by_location.get(location_key, [])

        # IMPORTANT: pass location_context here
        base = evaluate_lot(lot, item, location_context=location_context)

        ml_is_anomaly = None
        ml_score = None
        ml_signals = None

        if ml_ready:
            feats = build_feature_vector(lot, item)
            labels, scores = MODEL.predict([feats])
            ml_is_anomaly = labels[0] == -1
            ml_score = float(scores[0])
            ml_signals = simple_explanations(feats)

        results.append(
            EvalRow(
                lot_id=lot.id,
                item_id=item.id,
                item_name=item.name,
                location=base.location,
                conflicting_lot_ids=base.conflicting_lot_ids,
                baseline_status=base.status,
                baseline_reasons=base.reasons,
                triggered_rule_ids=base.triggered_rule_ids,
                ml_is_anomaly=ml_is_anomaly,
                ml_score=ml_score,
                ml_signals=ml_signals,
            )
        )

    return results