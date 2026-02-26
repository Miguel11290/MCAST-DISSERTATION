import numpy as np
from sklearn.ensemble import IsolationForest

class LotAnomalyModel:
    def __init__(self):
        self.model = None
        self.is_trained = False
        self.contamination = 0.10  # default expected anomaly percentage

    def train(self, X: list[list[float]], contamination: float = 0.10):
        self.contamination = float(contamination)
        X_np = np.array(X, dtype=float)

        # contamination = expected anomaly percentage
        self.model = IsolationForest(n_estimators=200, contamination=self.contamination, random_state=42)
        self.model.fit(X_np)
        self.is_trained = True

    def predict(self, X: list[list[float]]):
        if not self.is_trained or self.model is None:
            raise RuntimeError("Model is not trained yet")
        
        X_np = np.array(X, dtype=float)

        # IsolationForest:
        # - predict() returns 1 for normal, -1 for anomaly
        labels = self.model.predict(X_np)

        # decision_function: higher = more normal, lower = more anomalous
        scores = self.model.decision_function(X_np)

        return labels.tolist(), scores.tolist()
    
MODEL = LotAnomalyModel()