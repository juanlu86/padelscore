# PadelScore 🎾🏆

A premium Padel match tracking system with real-time synchronization between Apple Watch, iPhone, and Web.

## 🚀 Project Overview

PadelScore is designed for competitive players who want a high-visibility, distraction-free scoring experience.

- **iPhone App**: Manage matches, view detailed summaries, and sync with the Watch.
- **Watch App**: High-impact scoring with oversized fonts and "tall" typography for maximum court-side visibility.
- **Web App**: Live match dashboard (Firebase Hosting).
- **PadelCore**: Shared Swift logic and scoring rules (Standard, Golden Point, Star Point).
- **Backend**: Firebase Cloud Functions and Firestore for real-time data sync.

---

## 🏗️ Project Structure

- `PadelCore/`: Shared Swift package for match logic and state management.
- `XcodePadel/`: The Apple ecosystem project containing:
  - `PadeliOS`: iPhone companion app.
  - `PadeliOS Watch App`: The primary scoring interface.
- `PadelWeb/`: Next.js-based web dashboard.
- `functions/`: Firebase Cloud Functions (Node.js/TypeScript).
- `firebase.json`: Infrastructure configuration.

---

## 🛠️ Setup & Execution

### 1. Backend (Firebase)

The backend uses Firebase Emulators for development and standard Firebase services for production.

**Prerequisites**:
- Node.js (v18+)
- Firebase CLI (`npm install -g firebase-tools`)
- Java (Required for Firebase Emulators)

**Steps to start the backend locally**:
1. Open your terminal in the **project root** directory (where `firebase.json` is).
2. Install functions dependencies:
   ```bash
   cd functions && npm install && cd ..
   ```
3. Start the Firebase Emulators:
   ```bash
   firebase emulators:start
   ```
   *Note: Hosting has been moved to port **5005** to avoid macOS AirPlay conflicts. The Emulator UI will be available at `http://127.0.0.1:4000`.*

---

### 2. iOS & WatchOS App

**Prerequisites**:
- Xcode 15.0+
- macOS

**Steps**:
1. Open `XcodePadel/XcodePadel.xcodeproj` in Xcode.
2. Select the `PadeliOS` or `PadeliOS Watch App` scheme.
3. Choose a simulator or a physical device.
4. Press `Cmd + R` to run.

---

### 3. Web Dashboard

**Prerequisites**:
- Node.js

**Steps**:
1. Open your terminal in the **project root**.
2. Navigate to the web directory and install dependencies:
   ```bash
   cd PadelWeb && npm install
   ```
3. Start the development server from within the `PadelWeb` folder:
   ```bash
   npm run dev
   ```
   *The web dashboard will be available at `http://localhost:3000`.*

---

## 📏 Scoring Systems

PadelScore supports three major padel scoring systems:
1. **Standard**: Traditional deuce/advantage.
2. **Golden Point**: Sudden death at the first deuce.
3. **Star Point**: Two deuces allowed; the third deuce is a sudden death "Star Point".

---

## 🤝 Contributing

This project is verified via unit tests in `PadelCoreTests`.
