from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import Base, engine
from routes_items import router as items_router
from routes_inventory import router as inventory_router
from routes_safety import router as safety_router
from routes_ml import router as ml_router
from routes_eval import router as eval_router
from routes_metrics import router as metrics_router
from routes_experiments import router as experiments_router
from routes_summary import router as summary_router
import models

app = FastAPI(title="Inventory & Safety Management System API")

# For flutter, in order to call the API
app.add_middleware(
    CORSMiddleware, 
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create the database tables
Base.metadata.create_all(bind=engine)

@app.get("/health")
def health():
    return {"status": "ok"}

# Register routers
app.include_router(items_router)
app.include_router(inventory_router)
app.include_router(safety_router)
app.include_router(ml_router)
app.include_router(eval_router)
app.include_router(metrics_router)
app.include_router(experiments_router)
app.include_router(summary_router)