# Cultural Information Assistant — SorSU × CTU Can Tho Exchange

This project is built using:
- **Python (FastAPI)**: REST API & grounded retrieval engine with source citations
- **PostgreSQL**: Relational database (`cultural_db`)
- **Flutter (Dart)**: Complete cross-platform mobile application
- **JavaScript (HTML/CSS)**: Admin Dashboard & Planner + Mobile Web runner

---

## 1. Quick Start (Web & Admin Console)

The backend server is already configured to serve the complete application.

### Step 1: Start the Backend Server
Double-click `run_server.bat` or run in terminal:
```powershell
cd "c:\Users\USER\Desktop\CULTURAL APP"
python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

### Step 2: Open in your Browser
- **Mobile Participant App**: [http://localhost:8000/app/](http://localhost:8000/app/)
- **Coordinator & Admin Console**: [http://localhost:8000/admin/](http://localhost:8000/admin/)
- **API Documentation**: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 2. Test Login Accounts (Invite Codes)

Enter any of the following invite codes on the login screen:
- **`SORSU-STU-01`**: Student Mika Reyes (SorSU · Cohort A)
- **`SORSU-PROF-01`**: Professor Dr. Eduardo Santos (SorSU Faculty Delegation)
- **`ADMIN-CTU-01`**: Admin / Coordinator (SorSU × CTU Joint Secretariat)

---

## 3. How to Run the Flutter Mobile App

The full Flutter codebase is located in `flutter_app/`.

### Prerequisites:
- Flutter SDK installed ([flutter.dev](https://flutter.dev))
- An Android emulator, physical phone connected via USB, or Chrome browser

### Steps to Run:
```bash
cd "c:\Users\USER\Desktop\CULTURAL APP\flutter_app"
flutter pub get
flutter run
```
To run on Chrome directly:
```bash
flutter run -d chrome
```

---

## 4. Database Setup & Re-seeding

To reset or re-seed the PostgreSQL database with the 20-day exchange itinerary, 6 approved Can Tho cultural articles, coordinates, and QR codes:
```bash
python backend/seed_data.py
```
*(Or double-click `seed_db.bat`)*

---

## 5. Key Features to Explore

1. **AI Guide ("Ask the guide")**:
   - Schedule question: *"What time is the floating market trip?"* -> grounded answer with `[1 Itinerary · Day 3]` stub.
   - Cultural question: *"Why is Cai Rang famous?"* -> grounded answer with `[A1 Chinh (2024)]` stub.
   - Unsupported question: *"What's a good restaurant near the hotel?"* -> refusal card `Not in my sources` + `Contact your coordinator` button.
   - Tap **"How I answered ⌵"** to inspect the step-by-step reasoning and audit steps.
   - Toggle **Online / Offline** to test offline schedule fallback.
2. **Interactive Map**:
   - Visual schematic showing Hau River, CTU main gate, Cai Rang market, Binh Thuy ancient house, and current location trajectory.
3. **Culture Tab**:
   - Categories: Markets, Heritage, Music, Food, Words.
   - One-click copy for Vietnamese vocabulary (*chợ nổi*).
   - Article detail with Overview, Facts, Words, and Sources tabs.
4. **Scan View**:
   - Landmark camera viewfinder with corner focus brackets and verified summary.
5. **Admin Console & Planner**:
   - Open [http://localhost:8000/admin/](http://localhost:8000/admin/).
   - Inspect Day 3 activities, drag handles, audience tags (`Everyone`, `SorSU only`, `Staff only`).
   - Add new draft activities with `+ Add activity`.
   - Review pending professor requests in the `Approvals (2)` tab.
   - Click `Publish v5` to publish changes to the live student app.
