from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None
    hazard_class: Optional[str] = None
    unit: Optional[str] = None
    max_safe_quantity: Optional[float] = None # week 3 addition
    storage_group: Optional[str] = None # week 3 addition

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

class InventoryLotCreate(BaseModel):
    item_id: int
    quantity: float
    location: Optional[str] = None

class InventoryLotRead(BaseModel):
    id: int
    item_id: int
    quantity: float
    location: Optional[str] = None
    received_at: datetime
    scenario_type: str | None = None

    class Config:
        from_attributes = True

class SafetyCheckResult(BaseModel):
    lot_id: int
    item_id: int
    status: str # "safe", "warning", "danger"
    reasons: list[str]
    quantity: float
    max_safe_quantity: float | None = None
    received_at: datetime
    storage_days: int
    location: str | None = None
    conflicting_lot_ids: list[int] = []
    triggered_rule_ids: list[str] = []
    scenario_type: str | None = None

    class Config:
        from_attributes = True

class MLAnomalyResult(BaseModel):
    lot_id: int
    item_id: int
    is_anomaly: bool
    anomaly_score: float
    top_signals: list[str] # e.g. ["quantity_ratio", "storage_days"]

    class Config:
        from_attributes = True
        
class UserCreate(BaseModel):
    username: str
    full_name: Optional[str] = None
    password: str
    role: str = "viewer"  # default role
    
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