#!/bin/bash

# Auto-build script for makonome
PROJECT_DIR="/Users/miro/projects/makonome"
cd "$PROJECT_DIR"

echo "🔍 Watching for changes in makonome/..."

# Use fswatch to monitor file changes
fswatch -o makonome/ | while read f; do
    echo "📝 Files changed, rebuilding..."
    
    # Build with proper configuration
    xcodebuild -project makonome.xcodeproj -scheme makonome -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build
    
    if [ $? -eq 0 ]; then
        echo "✅ Build successful"
        
        # Find the app bundle
        ACTUAL_APP_PATH=$(find $HOME/Library/Developer/Xcode/DerivedData -name "makonome.app" -path "*/Debug-iphonesimulator/*" | head -1)
        
        if [ -n "$ACTUAL_APP_PATH" ]; then
            echo "📱 Installing and launching app..."
            
            # Install to simulator
            xcrun simctl install booted "$ACTUAL_APP_PATH"
            
            # Launch the app
            xcrun simctl launch booted com.mirocosic.makonome > /dev/null
            
            echo "🚀 App launched successfully"
        else
            echo "⚠️  Could not find app bundle"
        fi
    else
        echo "❌ Build failed"
    fi
    
    echo "👀 Watching for more changes..."
done