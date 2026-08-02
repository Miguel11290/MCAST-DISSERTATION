from fastapi import APIRouter
from rule_catalog import RULE_CATALOG
from safety_rules import DEFAULT_STORAGE_DAYS, HAZARD_STORAGE_DAYS
from compatibility_rules import INCOMPATIBLE_GROUPS

router = APIRouter(prefix="/rules", tags=["rules"])


@router.get("")
def list_rules():
    """Return traceable rule definitions and the current prototype configuration."""
    return {
        "disclaimer": (
            "This prototype provides decision support only. Configurable thresholds "
            "must be validated against the applicable licence, approved operating "
            "procedures, competent-authority guidance and site-specific conditions."
        ),
        "rules": RULE_CATALOG,
        "configuration": {
            "default_storage_days": DEFAULT_STORAGE_DAYS,
            "hazard_storage_days": HAZARD_STORAGE_DAYS,
            "incompatible_storage_groups": {
                key: sorted(value) for key, value in INCOMPATIBLE_GROUPS.items()
            },
        },
    }
