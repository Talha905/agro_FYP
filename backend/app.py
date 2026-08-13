from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import numpy as np
import pickle
import os
from PIL import Image
import io

app = FastAPI(title="AgroSaathi ML Backend", version="1.0.0")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load TFLite Model for Plant Disease Detection
disease_interpreter = None
try:
    import tensorflow as tf
    if os.path.exists("model.tflite"):
        disease_interpreter = tf.lite.Interpreter(model_path="model.tflite")
        disease_interpreter.allocate_tensors()
        print("Loaded Disease Detection model.tflite successfully.")
except Exception as e:
    print(f"Warning: Could not load model.tflite: {e}")

# Load Crop Recommendation Model (RandomForest)
crop_model = None
try:
    if os.path.exists("model.pkl"):
        with open("model.pkl", "rb") as f:
            crop_model = pickle.load(f)
        print("Loaded Crop Recommendation model.pkl successfully.")
except Exception as e:
    print(f"Warning: Could not load model.pkl: {e}")

DISEASE_CLASSES = [
    "Apple___Apple_scab", "Apple___Black_rot", "Apple___Cedar_apple_rust", "Apple___healthy",
    "Blueberry___healthy", "Cherry___Powdery_mildew", "Cherry___healthy",
    "Corn___Cercospora_leaf_spot Gray_leaf_spot", "Corn___Common_rust", "Corn___Northern_Leaf_Blight", "Corn___healthy",
    "Grape___Black_rot", "Grape___Esca_(Black_Measles)", "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)", "Grape___healthy",
    "Orange___Haunglongbing_(Citrus_greening)", "Peach___Bacterial_spot", "Peach___healthy",
    "Pepper,_bell___Bacterial_spot", "Pepper,_bell___healthy",
    "Potato___Early_blight", "Potato___Late_blight", "Potato___healthy",
    "Raspberry___healthy", "Soybean___healthy", "Squash___Powdery_mildew",
    "Strawberry___Leaf_scorch", "Strawberry___healthy",
    "Tomato___Bacterial_spot", "Tomato___Early_blight", "Tomato___Late_blight",
    "Tomato___Leaf_Mold", "Tomato___Septoria_leaf_spot", "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot", "Tomato___Tomato_Yellow_Leaf_Curl_Virus", "Tomato___Tomato_mosaic_virus", "Tomato___healthy"
]

class CropRecommendationRequest(BaseModel):
    soilType: str
    season: str
    waterAvailability: str
    district: Optional[str] = "Pune, Maharashtra"
    farmSizeAcres: Optional[float] = 1.0
    nitrogen: Optional[float] = None
    phosphorus: Optional[float] = None
    potassium: Optional[float] = None
    ph: Optional[float] = None
    temperature: Optional[float] = None
    humidity: Optional[float] = None

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "disease_model_loaded": disease_interpreter is not None,
        "crop_model_loaded": crop_model is not None
    }

@app.post("/predict")
async def predict_disease(file: UploadFile = File(...)):
    if disease_interpreter is None:
        return {"error": "Disease detection model is not loaded."}
    
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert('RGB')
        image = image.resize((224, 224))
        img_array = np.array(image, dtype=np.float32) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        input_details = disease_interpreter.get_input_details()
        output_details = disease_interpreter.get_output_details()

        disease_interpreter.set_tensor(input_details[0]['index'], img_array)
        disease_interpreter.invoke()
        predictions = disease_interpreter.get_tensor(output_details[0]['index'])[0]

        predicted_idx = int(np.argmax(predictions))
        confidence = float(predictions[predicted_idx])
        predicted_class = DISEASE_CLASSES[predicted_idx] if predicted_idx < len(DISEASE_CLASSES) else "Unknown"

        return {
            "success": True,
            "disease": predicted_class,
            "confidence": round(confidence * 100, 2)
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.post("/recommend_crop")
def recommend_crop(req: CropRecommendationRequest):
    try:
        # 1. Agro-climatic parameters derived from season & district if not explicitly provided
        season_lower = req.season.lower()
        if "rabi" in season_lower or "winter" in season_lower:
            default_temp = 20.5
            default_hum = 55.0
            default_rain = 45.0
        elif "zaid" in season_lower or "summer" in season_lower:
            default_temp = 31.5
            default_hum = 70.0
            default_rain = 50.0
        else:  # kharif / monsoon
            default_temp = 26.5
            default_hum = 82.0
            default_rain = 195.0

        # Adjust rainfall based on water availability
        if req.waterAvailability == "high":
            default_rain = max(default_rain, 180.0)
        elif req.waterAvailability == "low":
            default_rain = min(default_rain, 55.0)

        # 2. Typical NPK defaults based on soil type
        soil_npk = {
            "black": (85.0, 48.0, 42.0, 7.2),
            "alluvial": (90.0, 44.0, 40.0, 6.8),
            "red": (70.0, 38.0, 36.0, 6.2),
            "clay": (78.0, 42.0, 40.0, 7.0),
            "sandy": (55.0, 28.0, 30.0, 6.5),
            "loamy": (88.0, 42.0, 44.0, 6.7),
            "laterite": (60.0, 32.0, 34.0, 5.8),
        }
        def_n, def_p, def_k, def_ph = soil_npk.get(req.soilType.lower(), (80.0, 42.0, 40.0, 6.8))

        N = req.nitrogen if req.nitrogen is not None else def_n
        P = req.phosphorus if req.phosphorus is not None else def_p
        K = req.potassium if req.potassium is not None else def_k
        ph = req.ph if req.ph is not None else def_ph
        temp = req.temperature if req.temperature is not None else default_temp
        hum = req.humidity if req.humidity is not None else default_hum
        rainfall = default_rain

        recommendations = []

        if crop_model is not None:
            features = np.array([[N, P, K, temp, hum, ph, rainfall]])
            probs = crop_model.predict_proba(features)[0]
            top_indices = np.argsort(probs)[::-1][:4]

            crop_metadata = {
                "rice": {"name": "Rice (Paddy)", "yieldPerAcre": 22.0, "price": 2250, "cost": 18000, "water": "high", "risk": "low", "days": 135, "window": "June - July"},
                "wheat": {"name": "Wheat", "yieldPerAcre": 18.5, "price": 2350, "cost": 14000, "water": "medium", "risk": "low", "days": 120, "window": "Nov - Dec"},
                "cotton": {"name": "Cotton", "yieldPerAcre": 10.5, "price": 7120, "cost": 24000, "water": "medium", "risk": "medium", "days": 165, "window": "June - July"},
                "maize": {"name": "Maize (Corn)", "yieldPerAcre": 25.0, "price": 2150, "cost": 16000, "water": "medium", "risk": "low", "days": 100, "window": "June - July or Oct - Nov"},
                "chickpea": {"name": "Chickpea (Gram)", "yieldPerAcre": 9.0, "price": 5450, "cost": 11000, "water": "low", "risk": "low", "days": 105, "window": "Oct - Nov"},
                "pigeonpeas": {"name": "Pigeon Pea (Tur)", "yieldPerAcre": 8.5, "price": 7000, "cost": 13000, "water": "low", "risk": "medium", "days": 160, "window": "June - July"},
                "banana": {"name": "Banana", "yieldPerAcre": 280.0, "price": 1550, "cost": 75000, "water": "high", "risk": "medium", "days": 300, "window": "Feb - March or June - July"},
                "grapes": {"name": "Grapes", "yieldPerAcre": 90.0, "price": 4500, "cost": 95000, "water": "medium", "risk": "high", "days": 140, "window": "Oct - Nov (Pruning)"},
                "watermelon": {"name": "Watermelon", "yieldPerAcre": 160.0, "price": 950, "cost": 28000, "water": "medium", "risk": "low", "days": 85, "window": "Jan - March"},
                "muskmelon": {"name": "Muskmelon", "yieldPerAcre": 120.0, "price": 1400, "cost": 26000, "water": "medium", "risk": "low", "days": 90, "window": "Jan - March"},
                "pomegranate": {"name": "Pomegranate", "yieldPerAcre": 55.0, "price": 6200, "cost": 60000, "water": "low", "risk": "medium", "days": 180, "window": "Jan - Feb or June - July"},
                "orange": {"name": "Orange / Mandarin", "yieldPerAcre": 70.0, "price": 3800, "cost": 45000, "water": "medium", "risk": "medium", "days": 240, "window": "June - July"},
                "mango": {"name": "Mango", "yieldPerAcre": 50.0, "price": 5500, "cost": 40000, "water": "low", "risk": "low", "days": 365, "window": "June - Aug"},
                "papaya": {"name": "Papaya", "yieldPerAcre": 220.0, "price": 1200, "cost": 50000, "water": "medium", "risk": "medium", "days": 270, "window": "Feb - March or June - July"},
                "coconut": {"name": "Coconut", "yieldPerAcre": 45.0, "price": 4200, "cost": 30000, "water": "high", "risk": "low", "days": 365, "window": "May - June"},
                "jute": {"name": "Jute", "yieldPerAcre": 14.0, "price": 4800, "cost": 17000, "water": "high", "risk": "low", "days": 120, "window": "March - May"},
                "blackgram": {"name": "Black Gram (Urad)", "yieldPerAcre": 7.5, "price": 6600, "cost": 11500, "water": "low", "risk": "low", "days": 90, "window": "June - July or Feb - March"},
                "lentil": {"name": "Lentil (Masoor)", "yieldPerAcre": 8.0, "price": 6000, "cost": 11000, "water": "low", "risk": "low", "days": 110, "window": "Oct - Nov"},
                "mungbean": {"name": "Mung Bean (Moong)", "yieldPerAcre": 7.0, "price": 7200, "cost": 11000, "water": "low", "risk": "low", "days": 75, "window": "June - July or Feb - March"},
                "mothbeans": {"name": "Moth Bean (Matki)", "yieldPerAcre": 6.0, "price": 6500, "cost": 9500, "water": "low", "risk": "low", "days": 80, "window": "June - July"},
                "kidneybeans": {"name": "Kidney Bean (Rajma)", "yieldPerAcre": 8.5, "price": 7500, "cost": 15000, "water": "medium", "risk": "medium", "days": 115, "window": "Oct - Nov"},
                "coffee": {"name": "Coffee", "yieldPerAcre": 10.0, "price": 18000, "cost": 45000, "water": "medium", "risk": "medium", "days": 300, "window": "June - Dec"},
                "apple": {"name": "Apple", "yieldPerAcre": 90.0, "price": 5000, "cost": 90000, "water": "medium", "risk": "medium", "days": 180, "window": "Dec - Feb"},
            }

            for rank, idx in enumerate(top_indices):
                crop_slug = str(crop_model.classes_[idx]).lower()
                prob = float(probs[idx])
                
                # Dynamic realistic match score calculation
                if prob >= 0.70:
                    suitability = int(88 + min(11, (prob - 0.70) * 35))
                elif prob >= 0.20:
                    suitability = int(76 + (prob - 0.20) * 24)
                elif prob > 0.0:
                    suitability = int(65 + (prob) * 55)
                else:
                    suitability = max(50, 78 - rank * 8)

                meta = crop_metadata.get(crop_slug, {
                    "name": crop_slug.capitalize(),
                    "yieldPerAcre": 15.0,
                    "price": 3000,
                    "cost": 15000,
                    "water": "medium",
                    "risk": "low",
                    "days": 110,
                    "window": "Optimal planting season"
                })

                farm_multiplier = req.farmSizeAcres if (req.farmSizeAcres and req.farmSizeAcres > 0) else 1.0
                est_yield = meta["yieldPerAcre"] * farm_multiplier
                est_revenue = est_yield * meta["price"]
                est_cost = meta["cost"] * farm_multiplier
                profit = max(0.0, est_revenue - est_cost)

                recommendations.append({
                    "cropId": crop_slug,
                    "cropName": meta["name"],
                    "estimatedProfit": profit,
                    "waterRequirement": meta["water"],
                    "riskLevel": meta["risk"],
                    "confidenceScore": round(prob, 3),
                    "suitabilityScore": suitability,
                    "growthDurationDays": meta["days"],
                    "sowingWindow": meta["window"],
                    "agronomicTips": f"ML Model match ({suitability}%) based on {req.soilType.capitalize()} soil and {req.season.capitalize()} season.",
                    "estimatedYieldQuintal": round(est_yield, 1),
                    "estimatedRevenue": round(est_revenue, 0),
                    "estimatedCost": round(est_cost, 0)
                })

        return {
            "success": True,
            "count": len(recommendations),
            "recommendations": recommendations
        }
    except Exception as e:
        return {"success": False, "error": str(e)}