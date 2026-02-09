from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None
    hazard_class: Optional[str] = None
    unit: Optional[str] = None
    max_safe_quantity: Optional[float] = None # week 3 addition

class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    hazard_class: Optional[str] = None
    unit: Optional[str] = None
    max_safe_quantity: Optional[float] = None  

class ItemRead(ItemCreate):
    id: int

    class Config:
        orm_mode = True
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

    class Config:
        orm_mode = True
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

    class Config:
        orm_mode = True
        from_attributes = True