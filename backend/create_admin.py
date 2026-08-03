from auth import hash_password
from database import Base, SessionLocal, engine
from models import User

# Creates the users table without deleting existing data.
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    existing = (
        db.query(User)
        .filter(User.username == "admin")
        .first()
    )

    if existing:
        print("Admin user already exists.")
    else:
        admin = User(
            username="admin",
            full_name="System Administrator",
            hashed_password=hash_password("Admin123!"),
            role="admin",
            is_active=True,
        )

        db.add(admin)
        db.commit()

        print("Admin user created.")
        print("Username: admin")
        print("Temporary password: Admin123!")
finally:
    db.close()