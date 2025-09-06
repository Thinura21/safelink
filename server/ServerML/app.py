from fastapi import FastAPI, UploadFile, File
import uvicorn
import numpy as np
import tensorflow as tf
from PIL import Image
import json

app = FastAPI()

# ---- Load model ----
MODEL_PATH = "accident_severity_effv2b2_mixup.keras"
CLASS_PATH = "class_names.json"

print("Loading model...")
model = tf.keras.models.load_model(MODEL_PATH, compile=False)
print("Model loaded")

try:
    with open(CLASS_PATH, "r") as f:
        CLASS_NAMES = json.load(f)
except:
    CLASS_NAMES = ["low", "medium", "high"]


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Load image
    image = Image.open(file.file).convert("RGB").resize((300, 300))
    arr = np.asarray(image, dtype=np.float32) / 255.0
    arr = np.expand_dims(arr, axis=0)

    # Predict
    probs = model.predict(arr)[0]
    idx = int(np.argmax(probs))
    conf = float(probs[idx])
    label = CLASS_NAMES[idx]

    return {
        "label": label,
        "confidence": conf,
        "probs": {CLASS_NAMES[i]: float(probs[i]) for i in range(len(CLASS_NAMES))}
    }


if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
