from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import Base, SessionLocal, engine
from routes_items import router as items_router
from routes_inventory import router as inventory_router
from routes_safety import router as safety_router
from routes_ml import router as ml_router, train_ml_model
from routes_eval import router as eval_router
from routes_metrics import router as metrics_router
from routes_experiments import router as experiments_router
from routes_summary import router as summary_router
from routes_rules import router as rules_router
from routes_auth import router as auth_router
from routes_audit import router as audit_router

import models


Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    db = SessionLocal()

    try:
        result = train_ml_model(
            db=db,
            contamination=0.10,
        )

        print(
            "Machine-learning model trained on startup: "
            f"{result['samples']} samples, "
            f"contamination={result['contamination']}."
        )
    except ValueError as exc:
        print(
            "Automatic ML training was skipped: "
            f"{exc}"
        )
    except Exception as exc:
        print(
            "Automatic ML training failed: "
            f"{exc}"
        )
    finally:
        db.close()

    yield


app = FastAPI(
    title="Inventory & Safety Management System API",
    lifespan=lifespan,
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {
        "status": "ok",
    }


app.include_router(items_router)
app.include_router(inventory_router)
app.include_router(safety_router)
app.include_router(ml_router)
app.include_router(eval_router)
app.include_router(metrics_router)
app.include_router(experiments_router)
app.include_router(summary_router)
app.include_router(rules_router)
app.include_router(auth_router)
app.include_router(audit_router)