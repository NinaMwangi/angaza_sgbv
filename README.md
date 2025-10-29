# 🌍 Angaza SGBV Platform

**Angaza** is a mobile + web platform designed to support survivors and responders of Sexual and Gender-Based Violence (SGBV).  
It combines **offline safety triggers**, **trusted contacts**, **SMS fallback**, and **Firebase-powered incident tracking** with a web-based **dashboard** for visualization and response.

---

##  1. Mobile App (Flutter)

### Overview
The **Angaza mobile app** is a lightweight safety companion that:
- Works **offline**, with **SMS fallback** if the internet is unavailable.
- Allows users to register **trusted contacts**.
- Triggers emergency SOS via:
  - In-app **SOS button**
  - **Dormancy model** (detects inactivity)
  - **Hardware shortcuts** (Quick Settings tile / power button)
- Optionally records **audio evidence**.
- Syncs incidents to **Firebase Firestore** + **Cloud Storage** (if online).
- Supports **dark/light themes** and a **decoy Notes interface** for discretion.

---

###  Installation and Setup

#### 1. Prerequisites
- **Flutter SDK ≥ 3.19**
- **Java JDK 17+**
- **Android SDK (API 34)**
- **Firebase Project**
  - Enable **Authentication → Anonymous**
  - Enable **Firestore** and **Storage**
  - Download `google-services.json` → `mobile/android/app/`
- Create `firebase_options.dart` using:
  ```bash
  flutterfire configure
  ```

#### 2. Install Dependencies
From the `mobile` folder:
```bash
flutter pub get
```

#### 3. Run App
```bash
flutter run
```
or choose a device in VS Code → **Run → Start Debugging**.

---

### 📲 Usage Guide

####  Decoy Mode
- Launches as **Notes**.
- Long-press the header or tap **Angaza** in the title to open the **SOS interface**.

####  SOS Mode
1. Add **Trusted Contacts** via the people icon.
2. Tap **SOS** — app will:
   - Send an SMS to all contacts (offline mode)
   - Log the incident locally (Hive)
   - Sync to Firebase (if connected)
3. Incident details: timestamp, location, contacts, and optional audio recording.

#### ⚡ Shortcuts
- Add **Quick Settings Tile** (Android) → “SOS”
- Homescreen **Widget** → triggers SOS instantly
- **Dormancy Model** (ONNX) auto-activates SOS when abnormal inactivity is detected

####  Theme
Toggle dark/light mode using the brightness icon in the top bar.

####  History
View previous incidents under “History.”

---

###  Firebase Integration (MVP)
- **Firestore Collection:** `incidents`
- **Storage Folder:** `audio/`
- **Auth:** Anonymous user auto-created at startup
- **Env Config:** `mobile/lib/core/env/env.dart`
  ```dart
  class Env {
    static const String? apiBase = null; // fallback to SMS
    static const bool useFirebaseSync = true;
    static const String incidentsCollection = 'incidents';
    static const String audioFolder = 'audio';
  }
  ```

---

##  2. Dashboard (Web / Admin)

### Overview
The **Angaza Dashboard** is built in Flutter Web. It:
- Displays **incidents** as map markers (clustered by region).
- Allows **admin login** via Firebase Auth.
- Shows **aggregate data** from Firestore in real time.
- Will later support **analytics and filtering**.

---

###  Setup and Run
From the `dashboard` folder:
```bash
flutter pub get
flutter run -d chrome
```

- Sign in using your Firebase **admin** account (email/password).
- View the live **incidents map** with clustering and metadata.
- Clicking a marker reveals:
  - Reporter ID (anonymous)
  - Coordinates
  - Timestamp
  - Contacted persons
  - Optional audio recording (clickable link)

---

###  Firestore Structure
| Collection | Fields |
|-------------|--------|
| **incidents** | `id`, `timestamp`, `lat`, `lng`, `contacts`, `audioUrl`, `synced`, `deviceId`, `notes` |

---

##  3. Machine Learning Integration

### Dormancy Detection (ONNX)
- Runs an **ONNX model** (`best_classification_model.onnx`) locally.
- Detects prolonged inactivity (from accelerometer/gyroscope).
- If high dormancy risk detected → triggers SOS automatically.
- Model served via `onnxruntime` (offline inference).

### Next Steps
- Integrate **audio transcription (Whisper)** for post-incident ASR.
- Log anonymized **inactivity trends** for predictive analysis.

---

##  4. Project Structure

```
angaza_sgbv/
├── mobile/
│   ├── lib/
│   │   ├── app.dart
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── env/env.dart
│   │   │   ├── firebase_options.dart
│   │   │   └── theme_controller.dart
│   │   ├── features/
│   │   │   ├── sos/
│   │   │   ├── contacts/
│   │   │   ├── incidents/
│   │   │   └── decoy_notes/
│   └── android/
│       └── app/build.gradle
│
├── dashboard/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── ui/map_page.dart
│   │   ├── ui/login_page.dart
│   │   └── core/firebase_initializer.dart
│   └── web/
│       └── index.html
│
├── ml/
│   ├── convert/
│   ├── models/
│   └── notebooks/
└── README.md
```

---

##  5. How to Test MVP End-to-End

1. **Open mobile app**
   - Trigger SOS → SMS + Firestore write.
2. **Check Firebase**
   - Confirm new doc in `/incidents`.
3. **Open dashboard**
   - Log in → verify incident appears on map.
4. **(Optional)** Toggle dark mode → both apps adapt theme.

---

##  6. Pending Development

| Area | Description | Priority |
|------|--------------|-----------|
|  Audio | Offline recording + upload to Firebase Storage | 🔥 |
|  Dormancy | Improve ONNX model inference; reduce false positives | 🔥 |
|  Dashboard | Filtering + analytics by date/region | 🔥 |
|  Auth | Secure endpoints + roles (admin, agent, anonymous) | ⚙️ |
|  Map | Add heatmaps, clustering improvements | ⚙️ |
|  ASR | Integrate Whisper for audio-to-text (Swahili/English) | ⚙️ |
|  Backend | Optional REST API for SMS/incident routing | ⚙️ |
|  Packaging | Release signing configs, icons, splash screens | 🧩 |
|  Docs | System architecture, design diagrams | 🧩 |

---

##  Credits
Developed by **Nina Mwangi** and contributors  
Supervised under **Angaza SGBV Project (2025)**  
Powered by **Flutter**, **Firebase**, and **ONNXRuntime**

---

##  License
This project is licensed under the **MIT License** — see `LICENSE` file for details.
