from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)

from database import Base


class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    hazard_class = Column(String, nullable=True)
    unit = Column(String, nullable=True)
    max_safe_quantity = Column(Float, nullable=True)
    storage_group = Column(String, nullable=True)


class InventoryLot(Base):
    __tablename__ = "inventory_lots"

    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(
        Integer,
        ForeignKey("items.id"),
        index=True,
        nullable=False,
    )
    quantity = Column(Float, nullable=False)
    location = Column(String, nullable=True)
    received_at = Column(DateTime, default=datetime.utcnow)
    scenario_type = Column(String, nullable=True)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(
        String,
        unique=True,
        index=True,
        nullable=False,
    )
    full_name = Column(String, nullable=True)
    hashed_password = Column(String, nullable=False)
    role = Column(
        String,
        nullable=False,
        default="viewer",
    )
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        index=True,
        nullable=False,
    )

    username = Column(
        String,
        index=True,
        nullable=False,
    )

    action = Column(
        String,
        index=True,
        nullable=False,
    )

    entity_type = Column(
        String,
        index=True,
        nullable=False,
    )

    entity_id = Column(
        Integer,
        index=True,
        nullable=True,
    )

    description = Column(
        String,
        nullable=False,
    )

    old_values = Column(
        Text,
        nullable=True,
    )

    new_values = Column(
        Text,
        nullable=True,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        index=True,
    )