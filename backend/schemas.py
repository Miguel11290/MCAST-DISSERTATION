from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


# ============================================================
# Items
# ============================================================

class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None
    hazard_class: Optional[str] = None
    unit: Optional[str] = None
    max_safe_quantity: Optional[float] = None
    storage_group: Optional[str] = None


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    hazard_class: Optional[str] = None
    unit: Optional[str] = None
    max_safe_quantity: Optional[float] = None
    storage_group: Optional[str] = None


class ItemRead(ItemCreate):
    id: int

    class Config:
        from_attributes = True


# ============================================================
# Inventory Lots
# ============================================================

class InventoryLotCreate(BaseModel):
    item_id: int
    quantity: float
    location: Optional[str] = None


class InventoryLotUpdate(BaseModel):
    item_id: Optional[int] = None
    quantity: Optional[float] = None
    location: Optional[str] = None
    received_at: Optional[datetime] = None
    scenario_type: Optional[str] = None


class InventoryLotRead(BaseModel):
    id: int
    item_id: int
    quantity: float
    location: Optional[str] = None
    received_at: datetime
    scenario_type: Optional[str] = None

    class Config:
        from_attributes = True


# ============================================================
# Safety
# ============================================================

class SafetyCheckResult(BaseModel):
    lot_id: int
    item_id: int
    status: str

    reasons: List[str]

    quantity: float
    max_safe_quantity: Optional[float] = None

    received_at: datetime
    storage_days: int

    location: Optional[str] = None

    conflicting_lot_ids: List[int] = Field(
        default_factory=list,
    )

    triggered_rule_ids: List[str] = Field(
        default_factory=list,
    )

    scenario_type: Optional[str] = None

    class Config:
        from_attributes = True


# ============================================================
# Machine Learning
# ============================================================

class MLAnomalyResult(BaseModel):
    lot_id: int
    item_id: int

    is_anomaly: bool
    anomaly_score: float

    top_signals: List[str] = Field(
        default_factory=list,
    )

    class Config:
        from_attributes = True


class AuditLogRead(BaseModel):
    id: int
    user_id: int
    username: str
    action: str
    entity_type: str
    entity_id: Optional[int] = None
    description: str
    old_values: Optional[str] = None
    new_values: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# ============================================================
# Authentication / Users
# ============================================================

class UserCreate(BaseModel):
    username: str
    full_name: Optional[str] = None
    password: str
    role: str = "viewer"


class UserRead(BaseModel):
    id: int
    username: str
    full_name: Optional[str] = None
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str


class LoginRequest(BaseModel):
    username: str
    password: str