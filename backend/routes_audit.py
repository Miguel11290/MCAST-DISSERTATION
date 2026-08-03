from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from auth import require_roles
from database import SessionLocal
from models import AuditLog, User
import schemas

router = APIRouter(
    prefix="/audit-logs",
    tags=["audit logs"],
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


@router.get(
    "/",
    response_model=list[schemas.AuditLogRead],
)
def list_audit_logs(
    action: str | None = Query(default=None),
    entity_type: str | None = Query(default=None),
    username: str | None = Query(default=None),
    limit: int = Query(default=200, ge=1, le=1000),
    db: Session = Depends(get_db),
    _: User = Depends(
        require_roles(
            "admin",
            "safety_officer",
        )
    ),
):
    query = db.query(AuditLog)

    if action:
        query = query.filter(
            AuditLog.action == action.upper(),
        )

    if entity_type:
        query = query.filter(
            AuditLog.entity_type == entity_type,
        )

    if username:
        query = query.filter(
            AuditLog.username == username,
        )

    return (
        query
        .order_by(AuditLog.created_at.desc())
        .limit(limit)
        .all()
    )