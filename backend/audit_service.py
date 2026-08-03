import json
from typing import Any

from sqlalchemy.orm import Session

from models import AuditLog, User


def record_audit_log(
    db: Session,
    *,
    user: User,
    action: str,
    entity_type: str,
    entity_id: int | None,
    description: str,
    old_values: dict[str, Any] | None = None,
    new_values: dict[str, Any] | None = None,
) -> AuditLog:
    audit_log = AuditLog(
        user_id=user.id,
        username=user.username,
        action=action.upper(),
        entity_type=entity_type,
        entity_id=entity_id,
        description=description,
        old_values=(
            json.dumps(old_values, default=str)
            if old_values is not None
            else None
        ),
        new_values=(
            json.dumps(new_values, default=str)
            if new_values is not None
            else None
        ),
    )

    db.add(audit_log)

    return audit_log