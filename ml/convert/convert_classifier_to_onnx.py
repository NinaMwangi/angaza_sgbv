import argparse, joblib
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier

def infer_n_features(model, fallback=76):
    # Try direct estimator
    if hasattr(model, "n_features_in_"):
        return int(model.n_features_in_)
    # Try pipeline steps
    if isinstance(model, Pipeline):
        for _, step in model.named_steps.items():
            if hasattr(step, "n_features_in_"):
                return int(step.n_features_in_)
    # Last resort: user-supplied constant
    return fallback

def build_options(model):
    """
    Ensure ONNX includes predict_proba tensor (not ZipMap dict).
    Map options to the *classifier estimator* (inside pipeline or bare).
    """
    if isinstance(model, Pipeline):
        # Find the last estimator step (commonly named 'clf')
        last_step_name, last_step = list(model.named_steps.items())[-1]
        return {last_step: {"zipmap": False}}
    # Bare estimator
    return {model: {"zipmap": False}}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="Path to .pkl (Pipeline or estimator)")
    ap.add_argument("--out", required=True, help="Output .onnx path")
    ap.add_argument("--opset", type=int, default=13)
    ap.add_argument("--fallback_n", type=int, default=76, help="Fallback feature width if none inferred")
    args = ap.parse_args()

    model = joblib.load(args.model)
    n_feats = infer_n_features(model, fallback=args.fallback_n)
    opts = build_options(model)

    onx = convert_sklearn(
        model,
        initial_types=[("input", FloatTensorType([None, n_feats]))],
        target_opset=args.opset,
        options=opts,
    )

    with open(args.out, "wb") as f:
        f.write(onx.SerializeToString())
    print(f"[✓] Saved ONNX → {args.out}  (n_features={n_feats}, opset={args.opset})")

if __name__ == "__main__":
    main()
