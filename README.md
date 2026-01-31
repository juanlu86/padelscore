# PadelScore 🎾🏆

A premium Padel match tracking system with real-time synchronization between Apple Watch, iPhone, and Web.

## 🚀 Project Overview

PadelScore is designed for competitive players who want a high-visibility, distraction-free scoring experience.

- **iPhone App**: Manage matches, link to real-time courts via QR/Code, and sync with the Watch.
- **Watch App**: High-impact scoring with oversized fonts and "tall" typography. Primary input device.
- **Web App**: Admin dashboard for court management and live match spectator views.
- **PadelCore**: Shared Swift logic (Scoring rules: Standard, Golden Point, Star Point).
- **Backend**: Firestore-driven real-time sync with "Pending Update" safety.

---

## 🏗️ Project Structure

- `PadelCore/`: Shared Swift package (logic/state).
- `XcodePadel/`: 
  - `PadeliOS`: iPhone app (QR Pair, Court Management).
  - `PadeliOS Watch App`: Wearable scoring interface.
- `PadelWeb/`: Next.js Admin & Spectator dashboard.
- `functions/`: Cloud Functions for match lifecycle hooks.

---

## 🛠️ Setup & Execution

### 1. Backend & Web (Firebase)
The project uses the **Firebase Emulator Suite** for local parity.

**Prerequisites**: Node.js (v18+), Firebase CLI, Java.

**Steps**:
1. `npm install` in `functions` and `PadelWeb`.
2. Start emulators: `firebase emulators:start` (Hosting on **5005**).
3. Start Web Dev: `cd PadelWeb && npm run dev`.

### 2. iOS & WatchOS (Xcode)
**Steps**:
1. Open `XcodePadel/XcodePadel.xcodeproj`.
2. Select `PadeliOS` scheme -> Run on Simulator.
3. **QR Pairing**: In Simulator, use "Link Court" -> "Simulate Scan" to pair with a test court ID.

---

## 📏 Scoring Systems

1. **Standard**: Deuce/Advantage.
2. **Golden Point**: Sudden death at 40-40.
3. **Star Point**: Sudden death at the 3rd deuce.

---

## 🧪 Testing & Verification

- **Sync**: Logic includes a **Pending Update Queue** to prevent Watch-to-Web data loss during rapid scoring.
