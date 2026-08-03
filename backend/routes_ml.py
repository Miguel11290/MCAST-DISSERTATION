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
    qty, max_safe, ratio, storage_days, hazard_num, location_num = features
    signals: list[str] = []

    if max_safe > 0 and ratio > 1.0:
        signals.append("Quantity exceeds safe limit (ratio > 1.0)")

    if storage_days > 30:
        signals.append("Long storage duration (> 30 days)")

    if qty > 100:
        signals.append("High quantity value")

    if hazard_num >= 3.0:
        signals.append("Higher hazard class category")

    return signals[:3]


def train_ml_model(
    db: Session,
    contamination: float = 0.10,
) -> dict:
    if contamination <= 0 or contamination > 0.5:
        raise ValueError(
            "Contamination must be greater than 0 and no greater than 0.5."
        )

    lots = db.query(models.InventoryLot).all()

    if len(lots) < 10:
        raise ValueError(
            "Not enough lots to train. At least 10 inventory lots are required."
        )

    feature_vectors: list[list[float]] = []

    for lot in lots:
        item = (
            db.query(models.Item)
            .filter(models.Item.id == lot.item_id)
            .first()
        )

        if item is None:
            continue

        feature_vectors.append(
            build_feature_vector(lot, item)
        )

    if len(feature_vectors) < 10:
        raise ValueError(
            "Not enough valid lot-item pairs to train the model."
        )

    MODEL.train(
        feature_vectors,
        contamination=contamination,
    )

    return {
        "trained": True,
        "samples": len(feature_vectors),
        "contamination": contamination,
        "features": FEATURE_NAMES,
    }


@router.post("/train")
def train_model(
    contamination: float = 0.10,
    db: Session = Depends(get_db),
):
    try:
        return train_ml_model(
            db=db,
            contamination=contamination,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc


@router.get(
    "/anomalies/lots",
    response_model=list[schemas.MLAnomalyResult],
)
def detect_anomalies(
    db: Session = Depends(get_db),
):
    if not MODEL.is_trained:
        raise HTTPException(
            status_code=400,
            detail="Model not trained. Call POST /ml/train first.",
        )

    lots = (
        db.query(models.InventoryLot)
        .order_by(models.InventoryLot.id.desc())
        .all()
    )

    feature_vectors: list[list[float]] = []
    metadata: list[tuple[int, int, list[float]]] = []

    for lot in lots:
        item = (
            db.query(models.Item)
            .filter(models.Item.id == lot.item_id)
            .first()
        )

        if item is None:
            continue

        features = build_feature_vector(lot, item)

        feature_vectors.append(features)
        metadata.append(
            (
                lot.id,
                item.id,
                features,
            )
        )

    if not feature_vectors:
        return []

    labels, scores = MODEL.predict(feature_vectors)

    results: list[schemas.MLAnomalyResult] = []

    for (
        lot_id,
        item_id,
        features,
    ), label, score in zip(
        metadata,
        labels,
        scores,
    ):
        is_anomaly = label == -1
        signals = simple_explanations(features)

        if is_anomaly:
            top_features = top_feature_contributions(
                feature_vectors,
                features,
                k=3,
            )

            signals.extend(
                f"Top deviation: {feature}"
                for feature in top_features
            )

        results.append(
            schemas.MLAnomalyResult(
                lot_id=lot_id,
                item_id=item_id,
                is_anomaly=is_anomaly,
                anomaly_score=float(score),
                top_signals=signals[:5],
            )
        )

    return results