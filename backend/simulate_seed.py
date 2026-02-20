import random
from datetime import datetime, timedelta
from database import SessionLocal, Base, engine
import models

# Realistic item names found in fireworks manufacturing (NO recipes)
REAL_ITEMS = [
    # Oxidizers
    ("Potassium Nitrate", "oxidizer", 75),
    ("Potassium Perchlorate", "oxidizer", 60),
    ("Barium Nitrate", "oxidizer", 50),
    ("Strontium Nitrate", "oxidizer", 50),
    ("Sodium Nitrate", "oxidizer", 70),

    # Fuels / Metals
    ("Aluminum Powder", "fuel", 40),
    ("Magnesium Powder", "fuel", 35),
    ("Charcoal", "fuel", 90),
    ("Sulfur", "fuel", 80),
    ("Titanium Granules", "fuel", 45),

    # Binders / Additives
    ("Dextrin", "binder", 120),
    ("Red Gum", "binder", 120),
    ("Parlon (Chlorinated Rubber)", "binder", 100),

    # Other common materials / salts (still safe to name)
    ("Copper(II) Chloride", "color_agent", 30),
    ("Calcium Chloride", "other", 40),
    ("Strontium Carbonate", "color_agent", 40),

    # Packaging / components (for variety)
    ("Paper Tubes", "binder", 200),
    ("Fuse (Safety Fuse)", "binder", 150),
    ("Clay (Bentonite)", "binder", 250),
    ("Dextrin-Coated Rice Hulls", "binder", 120),
]

LOCATIONS = ["Store A", "Store B", "Store C", "Bay 1", "Bay 2"]


def sample_normal_quantity(hazard_class: str, max_safe: float | None) -> float:
    """
    More realistic normal quantity ranges depending on hazard type.
    This helps ML learn structure, not pure randomness.
    """
    if hazard_class == "oxidizer":
        qty = random.uniform(5, 55)
    elif hazard_class == "fuel":
        qty = random.uniform(2, 35)
    elif hazard_class == "binder":
        qty = random.uniform(10, 120)
    elif hazard_class == "explosive":
        qty = random.uniform(1, 20)
    else:
        qty = random.uniform(1, 40)

    # keep most normal values below max_safe if it exists
    if max_safe and qty > max_safe:
        qty = random.uniform(0.4 * max_safe, 0.9 * max_safe)

    return float(qty)


def run(n_items=20, n_lots=300):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Reset dataset (keeps experiments reproducible)
    db.query(models.InventoryLot).delete()
    db.query(models.Item).delete()
    db.commit()

    # Use first n_items from REAL_ITEMS (or all if less)
    selected = REAL_ITEMS[:n_items] if n_items <= len(REAL_ITEMS) else REAL_ITEMS

    # Create items
    for name, hazard, max_safe in selected:
        item = models.Item(
            name=name,
            description="Simulated industrial component (synthetic dataset)",
            hazard_class=hazard,
            unit="kg",
            max_safe_quantity=float(max_safe) if max_safe is not None else None
        )
        db.add(item)
    db.commit()

    items = db.query(models.Item).all()

    # Create lots
    for _ in range(n_lots):
        item = random.choice(items)
        loc = random.choice(LOCATIONS)

        # received date within last 90 days
        days_ago = random.randint(0, 90)
        received_at = datetime.utcnow() - timedelta(days=days_ago)

        # normal quantity based on hazard class
        qty = sample_normal_quantity(item.hazard_class or "", item.max_safe_quantity)

        # Inject anomalies (good for evaluation)
        scenario = random.random()

        # 10%: overstock beyond max safe quantity
        if scenario < 0.10 and item.max_safe_quantity:
            qty = float(item.max_safe_quantity * random.uniform(1.1, 2.0))

        # next 10%: extreme outlier quantity (pure anomaly)
        elif scenario < 0.20:
            qty = float(random.uniform(120, 250))

        # Create the lot
        lot = models.InventoryLot(
            item_id=item.id,
            quantity=float(qty),
            location=loc,
            received_at=received_at
        )
        db.add(lot)

    db.commit()
    db.close()
    print(f"Created {len(items)} items and {n_lots} simulated lots.")


if __name__ == "__main__":
    run()
