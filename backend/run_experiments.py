import csv
import time
import requests

BASE_URL = "http://127.0.0.1:8000"

CONTAMINATIONS = [0.05, 0.10, 0.20]
REPEATS = 5

def main():
    rows = []   
    for c in CONTAMINATIONS:
        for r in range(REPEATS):
            # train
            requests.post(f"{BASE_URL}/ml/train", params={"contamination": c})
            
            # metrics
            metrics = requests.get(f"{BASE_URL}/metrics/ml-vs-baseline").json()
            metrics["contamination"] = c
            metrics["repeat"] = r + 1
            metrics["timestamp"] = int(time.time())
            rows.append(metrics)
            
            print("c=", c, "repeat=", r+1, "F1=", metrics.get("f1_score"))
            
    # write csv
    with open("experiments.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
        
    print("Saved experiments.csv")

if __name__ == "__main__":
    main()