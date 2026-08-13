# AgroSaathi — Complete Step-by-Step Run & Execution Guide

This guide walks you through running both the **Backend ML/AI Server** and the **Flutter Mobile App** on your machine and Android Emulator.

---

## 📌 Project Architecture Overview

```text
agro_FYP/
├── backend/                  ← FastAPI Python Server (ML Crop Recommender + Disease Detection)
│   ├── app.py                ← Endpoints: /recommend_crop, /predict, /health
│   ├── model.pkl             ← Trained Crop Recommendation RandomForestClassifier (7 features)
│   └── model.tflite          ← TensorFlow Lite Plant Disease Model
│
└── agrosaathi/               ← Flutter Mobile Application (Person A, B, C, D Modules)
    ├── lib/
    │   ├── constants/        ← Theme, Colors, Multilingual Dictionaries (EN, HI, MR)
    │   ├── models/           ← Crop, Weather, Recommendation, GrowthPlan, User models
    │   ├── services/         ← Recommender Engine, Localization, Weather, Firebase Auth & Firestore
    │   ├── screens/          ← Dashboard, Crop Advisor, Home, Profile, Notifications, Login
    │   └── widgets/          ← Reusable, overflow-safe UI components
    └── test/                 ← Unit & Integration test suites
```

---

## 🚀 Part 1: Starting the Python ML Backend

The FastAPI backend powers the Crop Recommender (`/recommend_crop` using `model.pkl`) and Plant Disease Detection (`/predict` using `model.tflite`).

### Step 1: Open a Terminal & Navigate to `backend`
```powershell
cd c:\Users\thele\OneDrive\Desktop\FYP2\agro_FYP\backend
```

### Step 2: Install Required Dependencies (If not already installed)
```powershell
pip install fastapi uvicorn scikit-learn numpy pillow tensorflow
```

### Step 3: Run the FastAPI Server with Uvicorn
```powershell
python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

You should see:
```text
Loaded Crop Recommendation model.pkl successfully.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

> **Note for Android Emulator**: The Flutter app communicates with the backend via `http://10.0.2.2:8000`, which automatically routes to `localhost:8000` on your host PC.

---

## 📱 Part 2: Running the Flutter App on Android Emulator

### Step 1: Add Flutter to your Environment Path (if needed)
In PowerShell:
```powershell
$env:Path += ";C:\Users\thele\flutter\bin"
```

### Step 2: Check Connected Devices / Start Android Emulator
```powershell
flutter devices
```
If your Android emulator (`Small_Phone` or standard emulator) is already running in Android Studio or VS Code, it will be detected automatically.

### Step 3: Navigate to the Flutter Project
```powershell
cd c:\Users\thele\OneDrive\Desktop\FYP2\agro_FYP\agrosaathi
```

### Step 4: Get Packages
```powershell
flutter pub get
```

### Step 5: Launch the Application
```powershell
flutter run
```

---

## 🧪 Part 3: Testing App Features & Verification

### 1. Instant Demo Login (Zero SMS Delay)
1. On the Login Screen, tap the button: **"Instant Demo Login (Ramesh Patil)"**.
2. It immediately logs in as a verified farmer from Pune, Maharashtra (2.5 acres, Black soil, Canal/Borewell water).

### 2. Instant Language Switching (English, Hindi, Marathi)
1. In the top AppBar, tap the **Language Chip** (e.g., `EN`, `HI`, or `MR`).
2. Select **English**, **हिन्दी (Hindi)**, or **मराठी (Marathi)**.
3. Observe how the entire dashboard, weather forecast, farming advisory, navigation tabs, and form labels re-render instantly without app restarts or layout overflows.

### 3. Smart Crop Recommender (Person A Core Module)
1. Tap the **"Crop Advisor"** (or **"फसल सलाहकार"** / **"पीक सल्लागार"**) tab.
2. Try the **1-Tap Quick Presets**:
   - **Nashik • Black Soil • Rabi** → Recommends Wheat, Chickpea, Grapes with projected revenue & profit.
   - **Vidarbha • Kharif Cotton** → Recommends Cotton, Soybean, Pigeonpeas.
   - **Pune • Summer Vegetables** → Recommends Watermelon, Muskmelon, Papaya.
3. Or enter your custom soil type, season, water availability, and farm size.
4. Tap **"Get Crop Recommendations"**.
5. View the ranked results with suitability match %, risk level, and financial breakdown (Expected Yield, Revenue, Cultivation Cost, Net Profit).
6. Tap **"Start Growth Plan for this Crop"** to seamlessly transition into the Growth Planner timeline!

### 4. Live Agro-Weather Card & Agricultural Advisory
- Tap the tuning icon (⚙️ / 🎛️) on the weather card to switch districts (*Pune, Nashik, Nagpur, Kolhapur, Aurangabad*).
- Notice how the weather metrics and agricultural advisory (*irrigation guidance, spraying alert, rain alert*) update in real-time in your chosen language.

### 5. Running Automated Unit Tests
To verify all test cases from the command line:
```powershell
cd c:\Users\thele\OneDrive\Desktop\FYP2\agro_FYP\agrosaathi
flutter test test/person_a_modules_test.dart
```

---

## 🛠 Troubleshooting & Tips

- **RenderFlex Overflow**: All text fields, stat columns, weather cards, and module grids are configured with responsive `Expanded`, `Flexible`, and text truncation so they fit on any screen size from small phones (320px width) to tablets.
- **Backend Offline Fallback**: If the FastAPI backend is not running, the mobile app automatically falls back to its built-in on-device agronomic scoring engine with zero errors or disruption to the farmer!
