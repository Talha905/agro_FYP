# AgroSaathi — Complete Execution & Setup Guide

This guide provides instructions to run the **AgroSaathi** application, including the **FastAPI ML & AI Backend** and the **Flutter Mobile App**.

---

## 📌 Repository Architecture

```text
agro_FYP/
├── backend/                  ← FastAPI Python Backend (ML & Gemini AI)
│   ├── app.py                ← Endpoints: /predict-disease, /recommend-crop, /generate-growth-plan
│   ├── model.pkl             ← Crop Recommendation Random Forest Model
│   ├── plant_disease_model.tflite ← Plant Disease Detection TFLite Model
│   ├── class_indices.json    ← Plant Disease Class Labels
│   └── requirements.txt      ← Python Dependencies
│
└── agrosaathi/               ← Integrated Flutter Application
    ├── lib/
    │   ├── constants/        ← Colors, Themes, Multilingual Dictionary (EN, HI, MR)
    │   ├── models/           ← UserModel, GrowthPlan, ListingModel, BidModel, Recommendation, NotificationItem
    │   ├── services/         ← Firebase Auth/Firestore, ML ApiService, Local & In-App Notifications
    │   ├── screens/          ← Dashboard (5 Tabs), Home, Advisor, Disease Scanner, Marketplace, Profile
    │   └── widgets/          ← Reusable Design System Components
    └── pubspec.yaml          ← App Dependencies & Asset Configurations
```

---

## 🚀 Part 1: Running the Python Backend (FastAPI + ML + Gemini AI)

The backend provides 3 primary services:
1. **Plant Disease Detection**: `/predict-disease` using TFLite model.
2. **Crop Recommender**: `/recommend-crop` using ML model (`model.pkl`).
3. **AI Growth Planner**: `/generate-growth-plan` using Google Gemini AI.

### Step 1: Navigate to `backend/`
```powershell
cd backend
```

### Step 2: Install Dependencies
```powershell
pip install -r requirements.txt
```

### Step 3: (Optional) Set Gemini API Key
To enable AI growth plan generation via Gemini API:
```powershell
$env:GEMINI_API_KEY="YOUR_GEMINI_API_KEY_HERE"
```

### Step 4: Start the FastAPI Server
```powershell
python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

Server will run on `http://localhost:8000`.  
> *Note for Android Emulator*: Access the backend using `http://10.0.2.2:8000`.

---

## 📱 Part 2: Running the Flutter Mobile Application

### Step 1: Navigate to `agrosaathi/`
```powershell
cd agrosaathi
```

### Step 2: Install Flutter Dependencies
```powershell
flutter pub get
```

### Step 3: Check Connected Devices / Start Android Emulator
```powershell
flutter devices
```

### Step 4: Launch the Mobile Application
```powershell
flutter run
```

---

## 🌾 Part 3: Application Features & Walkthrough

1. **Dashboard & Quick Actions**:
   - Access live weather updates, active crop growth plans, daily tips, and quick links to all modules.
   - Switch language anytime using the language chip in the top app bar (`EN`, `HI`, `MR`).

2. **Smart Crop Advisory & Recommender**:
   - Select soil type, season, water availability, and farm size to get ranked crop recommendations with expected yield, profit, revenue, and cost breakdowns.

3. **AI & Template Growth Planner**:
   - Create custom crop tracking plans with 5 growth stages (`sowing`, `germination`, `vegetative`, `flowering`, `maturity`).
   - Local device push reminders will automatically schedule irrigation, fertilizer, and pest control notifications.

4. **Plant Disease Scanner**:
   - Take a photo or upload an image to diagnose crop diseases, check confidence scores, and get treatment advice via the FastAPI backend.

5. **Marketplace & Bids**:
   - Post crop listings for sale (`listings` collection).
   - Place, accept, or reject bids (`listings/{listingId}/bids` subcollection).
   - Generate and print PDF sales invoices (`InvoiceScreen`).

6. **In-App Notifications**:
   - Tap the bell icon in the dashboard app bar to view real-time bid updates, pest reminders, and status notifications.

---

## 🛠 Commit & Branch Information
- Integrated Branch: `develop`
- Git Remote Repository: `https://github.com/Talha905/agro_FYP.git`
