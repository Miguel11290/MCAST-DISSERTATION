from pydantic import BaseModel

class ItemCreate(BaseModel):
    name: str
    description: str | None = None
    hazard_class: str | None = None
    unit: str | None = None

class ItemRead(ItemCreate):
    id: int

    class Config:
        orm_mode = True