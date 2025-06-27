#!/bin/bash

# Auto-build script for makonome
PROJECT_DIR="/Users/miro/projects/makonome"
cd "$PROJECT_DIR"

echo "🔍 Watching for changes in makonome/..."

# Use fswatch to monitor file changes
fswatch -o makonome/ | while read f; do
    echo "📝 Files changed, rebuilding..."
    
    # Build, install and launch using the working one-liner
    if xcodebuild -project makonome.xcodeproj -scheme makonome -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/makonome-build && xcrun simctl install booted /tmp/makonome-build/Build/Products/Debug-iphonesimulator/makonome.app && xcrun simctl launch booted com.mirocosic.makonome > /dev/null; then
        echo "✅ Build, install and launch successful 🚀"
    else
        echo "❌ Build, install or launch failed"
    fi
    
    echo "👀 Watching for more changes..."
done