# Vyanjak — AI Speech Rehabilitation App

> A clinical-grade AI-powered communication assistant for stroke survivors with Anomic Aphasia.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/Gemini_AI-4285F4?style=flat&logo=google&logoColor=white)

---

## The Problem

Every year, over 15 million people worldwide suffer a stroke. A significant number develop **Anomic Aphasia** — a neurological condition where the person is fully conscious, intelligent, and knows exactly what they want to say, but cannot retrieve the word from memory.

Imagine trying to ask for water but being completely unable to say the word "water." You know what it is. You can picture it. But the word just won't come. This is the daily reality for millions of aphasia patients and their caregivers.

Current solutions are expensive clinical tools, require therapist presence, or are simply flashcard apps with no real intelligence. None of them work in real-time during everyday life.

---

## The Solution — Vyanjak

Vyanjak (व्यंजक — meaning "expressive" in Sanskrit) is a real-time AI cognitive prosthetic that sits on the patient's phone. When they struggle to find a word, the app listens, understands the struggle, and speaks the word for them — instantly.

It uses **Google Gemini 2.5 Flash** to analyze the patient's audio hesitations and environmental context together, predicting the exact word they are trying to say with high accuracy. It then shows a visual image of the word and speaks it aloud — giving the patient both audio and visual confirmation.

Beyond real-time assistance, Vyanjak tracks every session, identifies which words the patient struggles with most, measures weekly recovery progress, and generates a clinical PDF report the patient can share directly with their speech-language pathologist.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Android) |
| AI Backend | Python FastAPI |
| AI Engine | Google Gemini 2.5 Flash |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Image Fetching | Pexels API |
| Deployment | Render (Backend) + Firebase (Auth + DB) |

---

## Screenshots

### Login & Signup
> *Screenshot: Login screen with email/password fields and Google Sign-In button*

![Login Screen](screenshots/login.png)

> *Screenshot: Signup screen with name, email, password fields*

![Signup Screen](screenshots/signup.png)

---

### Dashboard
> *Screenshot: Home screen showing vocal clarity score ring, and three mode tiles — AI Speech Bridge, Targeted Practice, Clinical Analytics*

![Dashboard](screenshots/dashboard.png)

---

### AI Speech Bridge — Manual Mode
> *Screenshot: Dark navy screen with glowing teal orb, Manual/Auto toggle at top, context dropdown (Kitchen/Bedroom etc), session stats at bottom showing attempts and accuracy*

![Bridge Mode](screenshots/bridge_mode.png)

---

### AI Speech Bridge — Auto Detect Mode
> *Screenshot: Same screen with Auto Detect selected, status text showing "SPEECH DETECTED" in teal, orb pulsing*

![Auto Mode](screenshots/auto_mode.png)

---

### Word Reveal
> *Screenshot: White screen showing large Pexels image of predicted object, giant uppercase word text (e.g. "KETTLE"), "Tap to hear" button, Yes/No confirmation buttons, and alternative word chips*

![Word Reveal](screenshots/word_reveal.png)

---

### Targeted Practice
> *Screenshot: Flashcard screen with Pexels image, progress bar, hidden word reveal area, Hear and Say it buttons at bottom, score counter in top right*

![Practice Session](screenshots/practice.png)

---

### Practice Summary
> *Screenshot: Session complete screen showing Score, Accuracy, Attempts tiles and full list of words with correct/incorrect icons*

![Practice Summary](screenshots/practice_summary.png)

---

### Clinical Analytics
> *Screenshot: Analytics screen with 4 stat cards, weekly bar chart, Struggle Words list with HIGH/MED/LOW priority tags, Most Requested words section*

![Analytics](screenshots/analytics.png)

---

### PDF Report
> *Screenshot: Native Android share sheet appearing after tapping Generate Report, showing options to share via WhatsApp, email, save to files*

![PDF Report](screenshots/pdf_report.png)

---

> **To add screenshots:** Take screenshots on your phone while running the app → save them in a `screenshots/` folder in the repo root → push to GitHub. The images will automatically appear above.

---

## Live Deployment

| Service | URL |
|---|---|
| Backend API | `https://your-render-url.onrender.com` |
| API Docs | `https://your-render-url.onrender.com/docs` |
| Database | Cloud Firestore (Firebase) |
| Auth | Firebase Authentication |

> **Important:** Backend may take 50 seconds to wake up on first request due to Render free tier cold start. Please open the API docs URL once before testing the app to wake it up.

---

## Try the App

### Option 1 — Download APK (Recommended, No Setup Needed)
1. Download APK from [Google Drive](#) ← replace with your drive link
2. Install on any Android phone
3. If prompted, enable "Install from unknown sources"
4. Sign up with email or Google
5. Everything works — backend and database are already live

### Option 2 — Build from Source (For Local Development)

#### Prerequisites
- Flutter SDK 3.x
- Python 3.11+
- Android Studio
- Firebase project with Auth + Firestore enabled

#### Backend — Run Locally
```bash
cd Backend/vyanjak_backend
pip install -r requirements.txt
```

Create a `.env` file with your own key:
GEMINI_API_KEY=your_gemini_api_key_from_aistudio.google.com

Start server:
```bash
uvicorn main:app --reload
```

> Note: The backend is already deployed and running at the Render URL above. You only need to run it locally if you want to modify the backend code.

#### Flutter — Run Locally
```bash
cd Flutter
flutter pub get
```

Add your own `google-services.json` to `Flutter/android/app/` from your Firebase project.

Run:
```bash
flutter run
```

---

## Project Structure
Vyanjak/
├── Backend/
│   └── vyanjak_backend/
│       ├── main.py              # FastAPI app + Gemini integration
│       ├── requirements.txt     # Python dependencies
│       ├── Procfile             # Start command
│       └── .gitignore
└── Flutter/
└── lib/
├── core/
│   ├── constants/       # App theme, API keys
│   ├── network/         # Gemini + Pexels services
│   ├── sensors/         # Audio recording, motion detection
│   └── services/        # Firebase auth, Firestore, VAD
├── features/
│   ├── auth/            # Login + Signup screens
│   ├── dashboard/       # Home screen
│   ├── bridge_mode/     # AI Speech Bridge + Word Reveal
│   ├── practice_mode/   # Flashcard practice session
│   └── analytics/       # Clinical analytics + PDF report
└── widgets/             # Reusable UI components

---

## How It Works
User speaks or hesitates trying to find a word
↓
Flutter captures audio via device microphone
↓
Audio + environment context sent to FastAPI on Render
↓
Backend uploads audio to Google Gemini 2.5 Flash
↓
Gemini analyzes hesitation patterns + context
↓
Returns predicted word + alternatives + confidence score
↓
Flutter displays word with Pexels image + speaks via TTS
↓
User taps Yes/No → result saved to Firestore
↓
Analytics tracks patterns → PDF report for therapist

---

## API Reference
POST https://your-render-url.onrender.com/predict
Form Data:

audio: .m4a audio file (patient's voice recording)
context: string (e.g. "Kitchen — objects around me")

Response:
{
"primary_guess": "KETTLE",
"alternatives": ["MUG", "POT"],
"confidence_score": 0.87
}

---

## Google Technologies Used

| Technology | Purpose |
|---|---|
| Google Gemini 2.5 Flash | Core AI — multimodal audio + context word prediction |
| Firebase Authentication | Secure user login — Email/Password + Google Sign-In |
| Cloud Firestore | Real-time cloud database — sessions, analytics, struggle words |

---

## Environment Variables

### Backend (already configured on Render — evaluators need nothing)
GEMINI_API_KEY = configured securely on server

### Flutter
- Pexels API key → `lib/core/constants/keys.dart`
- Firebase config → `android/app/google-services.json`
  (not pushed to GitHub for security — add your own for local development)

---

## Team

**Krish Aggarwal**
Built for Google Solution Challenge — Build with AI Hackathon 2025

---

## License
MIT
