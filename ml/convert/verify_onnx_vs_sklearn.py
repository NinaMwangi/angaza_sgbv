import argparse, joblib, numpy as np, onnxruntime as ort

def infer_n_features(sk):
    if hasattr(sk, "n_features_in_"):
        return int(sk.n_features_in_)
    try:
        for _, step in sk.named_steps.items():
            if hasattr(step, "n_features_in_"):
                return int(step.n_features_in_)
    except Exception:
        pass
    return None

ap = argparse.ArgumentParser()
ap.add_argument("--model", required=True, help="Path to .pkl (ideally Pipeline)")
ap.add_argument("--onnx", required=True, help="Path to .onnx (exported with probs)")
args = ap.parse_args()

sk = joblib.load(args.model)
n_feats = infer_n_features(sk)

sess = ort.InferenceSession(args.onnx, providers=["CPUExecutionProvider"])
onnx_in = sess.get_inputs()[0]
if n_feats is None and isinstance(onnx_in.shape[1], int):
    n_feats = int(onnx_in.shape[1])
assert n_feats is not None, "Could not infer feature width"

# Random but deterministic input
rng = np.random.RandomState(0)
x = rng.randn(1, n_feats).astype(np.float32)

# Sklearn pipeline handles its own preprocessing
sk_probs = sk.predict_proba(x)[0]

# ONNX inference
outputs = sess.run(None, {onnx_in.name: x})

# Find probability-like tensor: rank-2, float, shape [1, n_classes]
probs = None
for out in outputs:
    arr = np.array(out)
    if arr.ndim == 2 and arr.shape[0] == 1 and arr.dtype.kind in ("f", "d"):
        probs = arr[0]
        break
assert probs is not None, (
    "Could not locate probability tensor in ONNX outputs. "
    "Re-export with options={model: {'zipmap': False}}."
)

print("Sklearn probs:", np.round(sk_probs, 4))
print("ONNX   probs:", np.round(probs, 4))
print("ΔL1:", float(np.sum(np.abs(sk_probs - probs))))
