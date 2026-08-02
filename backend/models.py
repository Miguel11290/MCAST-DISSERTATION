from sqlalchemy import Column, ForeignKey, Integer, String, Float, DateTime, Boolean
from database import Base
from datetime import datetime

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
    item_id = Column(Integer, ForeignKey("items.id"), index=True, nullable=False)
    quantity = Column(Float, nullable=False)
    location = Column(String, nullable=True)
    received_at = Column(DateTime, default=datetime.utcnow)
    scenario_type = Column(String, nullable=True)
    
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=True)
    hashed_password = Column(String, nullable=False)
    role = Column(String, nullable=False, default="viewer") 
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)