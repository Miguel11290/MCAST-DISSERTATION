from datetime import datetime, timezone
import hashlib

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
    now = datetime.now(timezone.utc)
    value = received_at if received_at.tzinfo else received_at.replace(tzinfo=timezone.utc)
    return max(0, (now - value).days)


def _stable_location_value(location: str | None) -> float:
    normalised = (location or "").strip().lower().encode("utf-8")
    digest = hashlib.sha256(normalised).digest()
    number = int.from_bytes(digest[:4], "big")
    return float(number % 1000) / 1000.0


def build_feature_vector(lot, item) -> list[float]:
    sd = storage_days(lot.received_at)
    max_safe = item.max_safe_quantity if item.max_safe_quantity is not None else 0.0
    ratio = (lot.quantity / max_safe) if max_safe and max_safe > 0 else 0.0

    return [
        float(lot.quantity),
        float(max_safe),
        float(ratio),
        float(sd),
        float(hazard_to_num(item.hazard_class)),
        _stable_location_value(lot.location),
    ]


FEATURE_NAMES = [
    "quantity",
    "max_safe_quantity",
    "qty_ratio",
    "storage_days",
    "hazard_class_num",
    "location_num",
]
