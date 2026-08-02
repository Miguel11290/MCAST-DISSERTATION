from datetime import datetime, timezone

DEFAULT_STORAGE_DAYS = 30

# Prototype defaults. They are configurable operational review periods, not
# universal statutory limits. Validate them for the intended licensed site.
HAZARD_STORAGE_DAYS = {
    "oxidizer": 21,
    "fuel": 30,
    "explosive": 14,
    "binder": 60,
}


def get_storage_limit(hazard_class: str | None) -> int:
    if not hazard_class:
        return DEFAULT_STORAGE_DAYS
    return HAZARD_STORAGE_DAYS.get(hazard_class.strip().lower(), DEFAULT_STORAGE_DAYS)


def days_since(dt: datetime) -> int:
    now = datetime.now(timezone.utc)
    value = dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    return max(0, (now - value).days)
