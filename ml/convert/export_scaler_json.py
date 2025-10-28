import json, joblib, argparse

ap = argparse.ArgumentParser()
ap.add_argument("--scaler", required=True, help="Path to feature_scaler.pkl")
ap.add_argument("--out", required=True, help="Path to scaler.json")
args = ap.parse_args()

scaler = joblib.load(args.scaler)
assert hasattr(scaler, "mean_") and hasattr(scaler, "scale_"), "Not a StandardScaler-like object"

with open(args.out, "w", encoding="utf-8") as f:
    json.dump({"mean": scaler.mean_.tolist(), "std": scaler.scale_.tolist()}, f)

print(f"[✓] Saved JSON: {args.out}")
