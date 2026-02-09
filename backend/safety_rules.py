from datetime import datetime

DEFAULT_STORAGE_DAYS = 30

HAZARD_STORAGE_DAYS = {
    "oxidizer": 21,
    "fuel": 30,
    "explosive": 14,
    "binder": 60,
}

def get_storage_limit(hazard_class: str | None) -> int:
    if not hazard_class:
        return DEFAULT_STORAGE_DAYS
    key = hazard_class.strip().lower()
    return HAZARD_STORAGE_DAYS.get(key, DEFAULT_STORAGE_DAYS)

def days_since(dt: datetime) -> int:
    return (datetime.now() - dt).days