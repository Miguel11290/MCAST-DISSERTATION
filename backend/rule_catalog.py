"""Traceable rule metadata used by the safety engine and frontend.

The sources describe the regulatory/operational basis of each rule. Numerical
values remain configurable prototype parameters unless a competent authority or
approved operating procedure specifies an exact limit.
"""

from typing import Any

RULE_CATALOG: list[dict[str, Any]] = [
    {
        "id": "quantity_limit",
        "name": "Maximum Quantity",
        "severity": "UNSAFE",
        "description": "Flags a lot whose quantity exceeds the configured maximum safe quantity for its item.",
        "source_type": "Configurable operational parameter",
        "source": "Maltese explosives legislation, approved factory procedures and stakeholder-informed practice",
        "configurable": True,
        "legal_determination": False,
    },
    {
        "id": "storage_duration",
        "name": "Storage Duration",
        "severity": "WARNING",
        "description": "Flags material stored longer than the configured review period for its hazard class.",
        "source_type": "Configurable operational parameter",
        "source": "Operational guidance and stakeholder-informed practice; requires site-specific validation",
        "configurable": True,
        "legal_determination": False,
    },
    {
        "id": "missing_hazard_class",
        "name": "Missing Hazard Classification",
        "severity": "WARNING",
        "description": "Flags an item when its hazard classification has not been recorded.",
        "source_type": "Traceability requirement",
        "source": "EU Directive 2013/29/EU and Maltese pyrotechnic article requirements",
        "configurable": False,
        "legal_determination": False,
    },
    {
        "id": "incompatible_storage",
        "name": "Incompatible Storage",
        "severity": "UNSAFE",
        "description": "Flags lots in the same location when their configured storage groups are incompatible.",
        "source_type": "Operational safety rule",
        "source": "Recognised segregation principles, industry guidance and stakeholder-informed practice",
        "configurable": True,
        "legal_determination": False,
    },
]

RULES_BY_ID = {rule["id"]: rule for rule in RULE_CATALOG}


def get_rule(rule_id: str) -> dict[str, Any]:
    return RULES_BY_ID[rule_id]
