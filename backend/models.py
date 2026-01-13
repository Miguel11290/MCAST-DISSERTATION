from sqlalchemy import Column, Integer, String, Float, DateTime
from database import Base
from datetime import datetime

class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    hazard_class = Column(String, nullable=False)
    unit = Column(String, nullable=False)


class InventoryLot(Base):
    __tablename__ = "inventory_lots"

    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(Integer, index=True)
    quantity = Column(Float, nullable=False)
    location = Column(String, nullable=True)
    received_at = Column(DateTime, default=datetime.utcnow)