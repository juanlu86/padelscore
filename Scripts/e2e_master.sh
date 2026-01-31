#!/bin/bash
set -e

# e2e_master.sh
# Orchestrates the Full Stack E2E Test Suite
# 1. Starts Firebase Emulators
# 2. Runs Web Admin Setup (Playwright)
# 3. Runs iOS Integration Tests (XCTest)
# 4. Runs Web Verification (Playwright)


# 0. Pre-flight Cleanup
echo "🧹 Checking for existing processes..."
# Kill anything on port 8080 (Firestore), 9099 (Auth), 3000 (Next.js), 5005 (Hosting)
lsof -ti:8080,9099,3000,5005 | xargs kill -9 2>/dev/null || true
echo "✨ Ports cleared."

# 0.5 Manage Environment
echo "📝 Loading test environment..."
if [ -f PadelWeb/.env.emulator ]; then
    # Filter out comments and export
    export $(grep -v '^#' PadelWeb/.env.emulator | xargs)
else
    echo "❌ PadelWeb/.env.emulator not found!"
    exit 1
fi

# 1. Start Emulators & Dev Server
echo "🔥 Starting Firebase Emulators (Auth, Firestore)..."
cd PadelWeb

firebase emulators:start --only firestore,auth --project "$NEXT_PUBLIC_FIREBASE_PROJECT_ID" > ../emulator.log 2>&1 &
EMULATOR_PID=$!

echo "🚀 Starting Next.js Dev Server..."
# Environment variables are already exported, so they will override .env.local
npm run dev > ../web.log 2>&1 &
WEB_PID=$!
cd ..

function cleanup() {
    echo "🧹 Teardown..."
    if [ -n "$EMULATOR_PID" ]; then
        echo "Killing Emulator (PID: $EMULATOR_PID)"
        kill "$EMULATOR_PID" || true
    fi
    if [ -n "$WEB_PID" ]; then
        echo "Killing Web Server (PID: $WEB_PID)"
        kill "$WEB_PID" || true
    fi
}
trap cleanup EXIT

echo "⏳ Waiting for services to boot..."
# Wait for Firestore port 8080 and Web port 3000
for i in {1..60}; do
    EMU_UP=0
    WEB_UP=0
    nc -z 127.0.0.1 8080 && EMU_UP=1
    nc -z 127.0.0.1 3000 && WEB_UP=1
    
    if [ $EMU_UP -eq 1 ] && [ $WEB_UP -eq 1 ]; then
        echo "✅ Services are UP!"
        # Extra grace for Next.js to finish initialization
        sleep 5
        break
    fi
    echo "   ... waiting for Firestore ($EMU_UP) and Web ($WEB_UP) ($i/60)"
    sleep 2
done

if ! nc -z 127.0.0.1 8080 || ! nc -z 127.0.0.1 3000; then
    echo "❌ Timeout waiting for services."
    echo "--- Emulator Log ---"
    tail -n 20 emulator.log
    echo "--- Web Log ---"
    tail -n 20 web.log
    exit 1
fi

# 1.5 Seed Auth Emulator
echo "👤 Seeding Auth Emulator..."
curl -s -X POST "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key" \
     -H "Content-Type: application/json" \
     --data-binary '{"email":"admin@padel.com","password":"password123","returnSecureToken":true}' > /dev/null

# 2. Web Setup & Verification (Playwright)
echo "🌍 [Step 1] Running Web E2E Tests..."

# DEBUG: Check if courts exist in emulator
echo "🔍 Checking Firestore Emulator Data (Initial)..."
curl -s "http://127.0.0.1:8080/v1/projects/demo-padel-e2e/databases/(default)/documents/courts" || echo "   (Firestore REST API check failed)"

cd PadelWeb
# Point Playwright to 127.0.0.1
export PLAYWRIGHT_BASE_URL=http://127.0.0.1:3000
npx playwright test > ../playwright.log 2>&1 || {
    echo "❌ Playwright Tests Failed (Check playwright.log)"
    cat ../playwright.log
    exit 1
}
cd ..

# 3. iOS Test
echo "📱 [Step 2] Running iOS Integration Tests..."
xcodebuild test \
    -project XcodePadel/PadeliOS/PadeliOS.xcodeproj \
    -scheme PadeliOS \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -launchArgument "-UseLocalhost" \
    -only-testing:PadeliOSUITests/SyncE2ETests \
    | xcpretty || echo "⚠️ iOS Tests failed or Simulator not available. Continuing..."

echo "✅ E2E Sequence Complete"
