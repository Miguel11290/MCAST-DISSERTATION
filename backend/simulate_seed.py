import random
from datetime import datetime, timedelta
from database import SessionLocal, Base, engine
import models

def run(n_items=20, n_lots=300):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    db.query(models.InventoryLot).delete()
    db.query(models.Item).delete()
    db.commit()

    hazard_classes = ["oxidizer", "fuel", "binder", "explosive", None]
    locations = ["Store A", "Store B", "Store C", "Bay 1", "Bay 2"]

    # Create items if none exist
    existing_items = db.query(models.Item).count()
    if existing_items < n_items:
        for i in range(n_items):
            hc = random.choice(hazard_classes)
            max_safe = random.choice([25, 50, 75, 100, None])
            item = models.Item(
                name = f"SimItem_{i+1}",
                description = "Simulated item",
                hazard_class = hc,
                unit = "kg",
                max_safe_quantity = max_safe
            )
            db.add(item)
        db.commit()

    items = db.query(models.Item).all()

    # Create inventory lots
    for _ in range(n_lots):
        item = random.choice(items)
        loc = random.choice(locations)

        # Generate received date within last 90 days
        days_ago = random.randint(0, 90)
        received_at = datetime.now() - timedelta(days=days_ago)

        # Normal quantities
        base_qty = random.uniform(1, 40)

        # Inject unsafe scenarios
        scenario = random.random()
        qty = base_qty

        # 10%: overstock beyond max safe quantity (if defined)
        if scenario < 0.10 and item.max_safe_quantity:
            qty = item.max_safe_quantity * random.uniform(1.1, 2.0)

        # 10%: extreme quantity anomaly
        elif scenario < 0.20:
            qty = random.uniform(120, 250)
        
        # else: normal quantity with some noise
        else:
            qty = base_qty
            
        lot = models.InventoryLot(
            item_id = item.id,
            quantity = float(qty),
            location = loc,
            received_at = received_at
        )
        db.add(lot)
    db.commit()
    db.close()
    print(f"Created {n_lots} simulated lots")


if __name__ == "__main__":
    run()