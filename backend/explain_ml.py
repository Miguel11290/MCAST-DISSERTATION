import numpy as np
from ml_features import FEATURE_NAMES

def top_feature_contributions(X: list[list[float]], x: list[float], k: int = 3) -> list[str]:
    # Proxy explainability:
    # 1. Compute median and IQR for each feature over dataset X
    # 2. Score each feature by robust deviation from median
    
    X_np = np.array(X, dtype=float)
    x_np = np.array(x, dtype=float)
    
    med = np.median(X_np, axis=0)
    q1 = np.percentile(X_np, 25, axis=0)
    q3 = np.percentile(X_np, 75, axis=0)
    iqr = (q3 - q1)
    iqr[iqr == 0] = 1e-6 # prevent division by zero
    
    dev = np.abs((x_np - med) / iqr) # robust deviation
    idx = np.argsort(-dev)[:k]
    
    return [FEATURE_NAMES[i] for i in idx]