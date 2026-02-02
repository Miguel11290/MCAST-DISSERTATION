from database import SessionLocal, Base, engine
import models

def run():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Clear old data
    db.query(models.InventoryLot).delete()
    db.query(models.Item).delete()
    db.commit()

    items = [
        models.Item(name="Sample Oxidizer", hazard_class="oxidizer", unit="kg", max_safe_quantity=50),
        models.Item(name="Sample Fuel", hazard_class="fuel", unit="kg", max_safe_quantity=25),
        models.Item(name="Binder", hazard_class="binder", unit="kg", max_safe_quantity=100),
    ]

    db.add_all(items)
    db.commit()

    # refresh ids
    for i in items:
        db.refresh(i)

    lots = [
        models.InventoryLot(item_id=items[0].id, quantity=10, location="Store A"),
        models.InventoryLot(item_id=items[0].id, quantity=60, location="Store A"),  # intentionally exceeds max_safe_quantity (unsafe scenario)
        models.InventoryLot(item_id=items[1].id, quantity=5, location="Store B"),
        models.InventoryLot(item_id=items[2].id, quantity=20, location="Store C"),
    ]

    db.add_all(lots)
    db.commit()
    db.close()
    print("Seed completed.")

if __name__ == "__main__":
    run()