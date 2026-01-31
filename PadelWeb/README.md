# PadelWeb  Dashboard 🖥️

This is the web interface for the PadelScore ecosystem, built with Next.js and Firebase.

## 🌟 Key Features

### 1. Admin Panel (`/admin`)
- **Court Management**: Create and manage physical courts (labeled identifiers).
- **Control Center**: Reset courts, update court names, and monitor active matches.
- **Link QR Codes**: Generates the pairing links needed for the iOS app.

### 2. Spectator Dashboard (`/court/[courtId]`)
- **Real-time Viewing**: Zero-latency scoring updates via Firestore.
- **TV Optimized**: High-contrast, large typography designed for court-side displays.
- **Auto-Sync**: Automatically updates when a new match is linked to the court.

## 🛠️ Development

### Setup
1. Ensure the Firebase Emulator is running (see root README).
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```

### Deployment
Deployment is handled via Firebase Hosting (Standard). **Do not use App Hosting.**
1. Build the project:
   ```bash
   npm run build
   ```
2. Deploy to Firebase:
   ```bash
   firebase deploy --only hosting
   ```

## 🧪 Testing
Run Playwright/Vitest tests (if configured):
```bash
npm test
```
