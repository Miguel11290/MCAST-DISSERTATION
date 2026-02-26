# Simulates inventory over time and measures detection delay:
# 1. baseline rule triggers exactly when unsafe condition starts (delay ~ 0)
# 2. ML triggers when anomaly score crosses threshold (delay may be > 0 depending on how quickly it detects the change)

import random
from datetime import datetime, timedelta
import numpy as np

from ml_model import LotAnomalyModel
from ml_features import FEATURE_NAMES

def generate_timeline(days=60):
    # simple timeline: quantity increases over time; unsafe begins at day_unsafe
    day_unsafe = random.randint(20, 40)
    max_safe = random.choice([40, 60, 80])
    
    qty = 10.0
    series = []
    for d in range(days):
        if d < day_unsafe:
            qty += random.uniform(-1, 2)
        else:
            qty += random.uniform(2, 6) # unsafe growth
            
        storage_days = d
        ratio = qty / max_safe
        hazard_num = random.choice([2.0, 3.0, 4.0]) # simulate different hazard classes
        
        x = [qty, max_safe, ratio, storage_days, hazard_num, 0.2] # location constant
        series.append((x))
        
    return series, day_unsafe

def baseline_detect_day(series):
    for d, x in enumerate(series):
        qty, max_safe, ratio, sd, hazard, loc = x
        if max_safe > 0 and qty > max_safe:
            return d
        
    return None

def ml_detect_day(model, series, threshold):
    # anomaly_strength = -score (higher = more anomalous)
    labels, scores = model.predict(series)
    strength = [-s for s in scores]
    for d, st in enumerate(strength):
        if st >= threshold:
            return d
    return None

def run_experiment(runs=30, days=60, contamination=0.10):
    delays = []
    model = LotAnomalyModel()
    
    # Train model on normal-ish data first
    trainX = []
    for _ in range(80):
        series, day_unsafe = generate_timeline(days=days)
        # only first 20 days as "normal training" data
        trainX.extend(series[:20])
    model.train(trainX, contamination=contamination)
    
    # Choose threshold from training distribution (90th percentile anomaly_strength)
    _, train_scores = model.predict(trainX)
    train_strength = np.array([-s for s in train_scores])
    threshold = float(np.percentile(train_strength, 90))
    
    for _ in range(runs):
        series, day_unsafe = generate_timeline(days=days)
        base_day = baseline_detect_day(series) # should align with unsafe start
        ml_day = ml_detect_day(model, series, threshold)
        
        if base_day is None or ml_day is None:
            continue
        
        base_delay = base_day - day_unsafe
        ml_delay = ml_day - day_unsafe
        delays.append({"baseline_delay": base_delay, "ml_delay": ml_delay})
        
    return delays

if __name__ == "__main__":
    delays = run_experiment(runs=50)
    b = [d["baseline_delay"] for d in delays]
    m = [d["ml_delay"] for d in delays]
    print("Runs:", len(delays))
    print("Baseline delay avg:", sum(b)/len(b) if b else None)
    print("ML delay avg:", sum(m)/len(m) if m else None)
