from collections import Counter
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
import models
from ml_model import MODEL
from routes_safety import evaluate_lot
from ml_features import build_feature_vector

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
    enriched = []
    for lot in lots:
        item = db.query(models.Item).filter(models.Item.id == lot.item_id).first()
        if item:
            enriched.append((lot, item))

    by_location: dict[str, list[tuple[models.InventoryLot, models.Item]]] = {}
    for lot, item in enriched:
        by_location.setdefault(lot.location or "UNKNOWN", []).append((lot, item))

    counts = Counter()
    location_risk = Counter()
    triggered_rules = Counter()
    ml_anomalies = 0

    for lot, item in enriched:
        context = by_location.get(lot.location or "UNKNOWN", [])
        result = evaluate_lot(lot, item, location_context=context)
        counts[result.status.lower()] += 1
        if result.status in {"WARNING", "UNSAFE"}:
            location_risk[lot.location or "UNKNOWN"] += 1
        triggered_rules.update(result.triggered_rule_ids)

        if MODEL.is_trained:
            labels, _ = MODEL.predict([build_feature_vector(lot, item)])
            if labels[0] == -1:
                ml_anomalies += 1

    highest_risk_location = location_risk.most_common(1)
    most_triggered_rule = triggered_rules.most_common(1)

    return {
        "total_lots": len(enriched),
        "safe": counts["safe"],
        "warning": counts["warning"],
        "unsafe": counts["unsafe"],
        "conflicts": triggered_rules["incompatible_storage"],
        "ml_anomalies": ml_anomalies,
        "highest_risk_location": highest_risk_location[0][0] if highest_risk_location else None,
        "most_triggered_rule": most_triggered_rule[0][0] if most_triggered_rule else None,
        "rule_trigger_counts": dict(triggered_rules),
        "model_trained": MODEL.is_trained,
    }
