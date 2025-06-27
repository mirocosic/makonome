# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Makonome is a SwiftUI iOS application that provides metronome and stopwatch functionality. The app features a tabbed interface with three main sections: Stopwatch, Metronome, and Settings. The project uses the modern Swift Testing framework for unit tests.

## Development Commands

### Auto-Build Script (Recommended)
Start the auto-build watcher that rebuilds and relaunches the app on file changes:
```bash
./auto-build.sh &
```
This command should be run at the start of each development session to enable live reloading.

### Building and Running
- Open the project in Xcode: `open makonome.xcodeproj`
- Build from command line: `xcodebuild -project makonome.xcodeproj -scheme makonome build`
- Run tests: `xcodebuild test -project makonome.xcodeproj -scheme makonome -destination 'platform=iOS Simulator,name=iPhone 16'`

### Command Line Build and Run
To build and run the app on iOS Simulator from command line:
```bash
# List available simulators
xcrun simctl list devices available

# Build, install and launch on simulator (all in one command)
xcodebuild -project makonome.xcodeproj -scheme makonome -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/makonome-build && xcrun simctl install booted /tmp/makonome-build/Build/Products/Debug-iphonesimulator/makonome.app && xcrun simctl launch booted com.mirocosic.makonome

# Or step by step:
# 1. Build for simulator
xcodebuild -project makonome.xcodeproj -scheme makonome -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/makonome-build

# 2. Install app on booted simulator
xcrun simctl install booted /tmp/makonome-build/Build/Products/Debug-iphonesimulator/makonome.app

# 3. Launch app
xcrun simctl launch booted com.mirocosic.makonome
```

### Testing
- Unit tests use the Swift Testing framework with `@Test` annotations
- Test files are located in `makonomeTests/`
- UI tests are in `makonomeUITests/`

## Architecture

### Project Structure
- `makonome/` - Main application source code
  - `makonomeApp.swift` - App entry point using `@main` with ThemeManager integration
  - `MainTabView.swift` - Tab-based navigation with three main views
  - `MetronomeView.swift` - Metronome functionality with AVFoundation audio
  - `StopwatchView.swift` - Stopwatch functionality
  - `SettingsView.swift` - Application settings and preferences
  - `PresetView.swift` - Preset management for metronome settings
  - `ThemeManager.swift` - Theme management (light/dark/system)
  - `UsageTracker.swift` - Usage tracking functionality
  - `Assets.xcassets/` - App icons and visual assets
- `makonomeTests/` - Unit tests using Swift Testing framework
- `makonomeUITests/` - UI automation tests

### Key Features
- **Metronome**: Full-featured metronome with note subdivisions, tempo control, and audio playback
- **Stopwatch**: Standard stopwatch functionality with lap timing
- **Theme Management**: Light, dark, and system theme support
- **Usage Tracking**: Session and total usage tracking
- **Presets**: Save and manage metronome configurations

### Frameworks and Dependencies
- **SwiftUI**: Primary UI framework
- **AVFoundation**: Audio playback for metronome clicks
- **Foundation**: Core framework for data management and UserDefaults
- **Swift Testing**: Modern testing framework with `@Test` annotations

### SwiftUI Architecture
- Uses standard SwiftUI app lifecycle with `WindowGroup`
- Environment objects for theme management across views
- Views follow SwiftUI declarative patterns with `View` protocol
- Preview support enabled with `#Preview` macro
- Tab-based navigation with SF Symbols icons

## Development Notes

- The project uses modern Swift features including the new Swift Testing framework
- SwiftUI previews are configured for rapid development iteration
- Standard iOS app structure with separate test targets for unit and UI testing
- Theme management is handled through environment objects
- Usage tracking persists data using UserDefaults