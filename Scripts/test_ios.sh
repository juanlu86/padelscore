#!/bin/bash
set -e

# Configuration
PROJECT="XcodePadel/PadeliOS/PadeliOS.xcodeproj"
SCHEME="PadeliOS"
DESTINATION="platform=iOS Simulator,name=iPhone 17"

echo "🚀 Running PadeliOS Tests (Fast Mode)..."
echo "ℹ️  Skipping UI Tests & Parallel Execution for speed."

xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -parallel-testing-enabled NO \
    -skip-testing:PadeliOSUITests \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

echo "✅ All Unit Tests Passed!"
