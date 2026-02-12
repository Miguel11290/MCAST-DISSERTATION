from datetime import datetime
import numpy as np

HAZARD_MAP = {
    "oxidizer": 3.0,
    "explosive": 4.0,
    "fuel": 2.0,
    "binder": 1.0,
}

def hazard_to_num(h: str | None) -> float:
    if not h:
        return 0.0
    return HAZARD_MAP.get(h.strip().lower(), 0.0)

def storage_days(received_at: datetime) -> int:
    return (datetime.utcnow() - received_at).days

def build_feature_vector(lot, item) -> list[float]:
    # Features are intentionally simply + explainable for now, but can be expanded in the future
    sd = storage_days(lot.received_at)

    max_safe = item.max_safe_quantity if item.max_safe_quantity is not None else 0.0
    ratio = (lot.quantity / max_safe) if max_safe and max_safe > 0 else 0.0

    # location feature: stable numeric encoding of the location string, can be expanded in the future to include more info about the location
    loc = (lot.location or "").strip().lower()
    loc_num = float(abs(hash(loc)) % 1000) /1000.0 # 0..0.999

    return [
        float(lot.quantity),    # raw quantity
        float(max_safe),        # safe limit
        float(ratio),           # quantity vs safe
        float(sd),              # storage duration
        float(hazard_to_num(item.hazard_class)) , # hazard class as numeric
        float(loc_num),         # location encoding
    ]

FEATURE_NAMES = ["quantity", "max_safe_quantity", "qty_ratio", "storage_days", "hazard_class_num", "location_num"]