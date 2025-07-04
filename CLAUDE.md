# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Makonome is a SwiftUI iOS application that provides comprehensive practice session management and metronome functionality. The app features a tabbed interface with three main sections: Metronome, Practice, and Settings. The app focuses on helping musicians track their practice sessions with advanced metronome features, daily reminders, and detailed session history. The project uses the modern Swift Testing framework for unit tests.

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
  - `MainTabView.swift` - Tab-based navigation with Metronome, Practice, and Settings tabs
  - **Metronome Components:**
    - `MetronomeView.swift` - Main metronome interface with advanced features
    - `BPMScrollWheel.swift` & `SimpleBPMScrollWheel.swift` - Alternative BPM input methods
    - `BeatsPerBarPickerSheet.swift` - Beats per bar selection
    - `SubdivisionPickerSheet.swift` - Note subdivision selection
    - `GapTrainerPickerSheet.swift` - Gap trainer configuration
    - `TempoChangerPickerSheet.swift` - Tempo changer configuration
  - **Practice Session Components:**
    - `PracticeSessionView.swift` - Main practice session interface
    - `SessionManager.swift` - Practice session management and persistence
    - `PracticeSession.swift` - Practice session data model
    - `SessionHistoryView.swift` - Practice session history browser
  - **Settings and Management:**
    - `SettingsView.swift` - Application settings and preferences
    - `PresetView.swift` - Preset management for metronome settings
    - `ThemeManager.swift` - Theme management (light/dark/system)
    - `NotificationManager.swift` - Daily practice reminder notifications
  - **Utilities:**
    - `UsageTracker.swift` - Usage tracking functionality
  - **Assets:**
    - `Assets.xcassets/` - App icons and visual assets
    - Audio files: `click.mp3`, `click1.mp3`, `clave.mp3`, `clave1.mp3`
- `makonomeTests/` - Unit tests using Swift Testing framework
- `makonomeUITests/` - UI automation tests
- `auto-build.sh` - Development script for live reloading

### Key Features
- **Advanced Metronome**: Full-featured metronome with note subdivisions, tempo control, multiple sounds (click/clave), Gap Trainer, and Tempo Changer
- **Practice Sessions**: Comprehensive session management with goal setting, history tracking, and progress monitoring
- **Daily Reminders**: Configurable push notifications to encourage regular practice
- **Audio Enhancement**: Background playback, volume control, haptic feedback, and audio interruption handling
- **Theme Management**: Light, dark, and system theme support
- **Usage Tracking**: Detailed session and total usage tracking with persistence
- **Presets**: Save and manage metronome configurations with beat patterns

### Practice Session System
The app includes a comprehensive practice session management system:
- **Session Tracking**: Start, pause, and complete practice sessions with automatic timing
- **Goal Setting**: Set target practice durations and track progress
- **Session History**: View detailed history of all practice sessions with dates and durations
- **Progress Monitoring**: Track daily and total practice time
- **Session Integration**: Seamlessly integrate with metronome presets and settings
- **Persistence**: All session data is automatically saved and restored

### Daily Reminders & Notifications
- **Push Notifications**: Configurable daily practice reminders
- **Permission Management**: Automatic notification permission handling
- **Customizable Timing**: Set preferred reminder times
- **Developer Mode**: Test notifications for development

### Advanced Metronome Features
- **Gap Trainer**: Alternating normal/muted phases to test internal timing
- **Tempo Changer**: Gradually increases BPM during practice sessions
- **Multiple Sounds**: Click and Clave sounds with separate accent files
- **Volume Control**: Independent volume adjustment with live feedback
- **Haptic Feedback**: Configurable haptic intensity for tactile beats
- **Note Subdivisions**: Quarter, eighth, sixteenth, triplet, and quintuplet patterns
- **Background Audio**: Continuous playback with audio interruption handling
- **Beat Patterns**: Complex accent patterns for various time signatures

### Frameworks and Dependencies
- **SwiftUI**: Primary UI framework
- **AVFoundation**: Audio playback for metronome clicks and background audio
- **UserNotifications**: Push notifications for practice reminders
- **Foundation**: Core framework for data management and UserDefaults
- **Swift Testing**: Modern testing framework with `@Test` annotations

### SwiftUI Architecture
- Uses standard SwiftUI app lifecycle with `WindowGroup`
- Environment objects for theme management across views
- Views follow SwiftUI declarative patterns with `View` protocol
- Preview support enabled with `#Preview` macro
- Tab-based navigation with SF Symbols icons

### Background Audio Capabilities
- **Background Playback**: App continues playing metronome when backgrounded
- **Audio Interruption Handling**: Graceful handling of phone calls and other audio interruptions
- **Background Task Management**: Maintains timing accuracy during background execution
- **Audio Session Configuration**: Optimized for reliable background audio performance
- **Info.plist Configuration**: Includes required background audio modes

## Development Notes

- The project uses modern Swift features including the new Swift Testing framework
- SwiftUI previews are configured for rapid development iteration
- Standard iOS app structure with separate test targets for unit and UI testing
- Theme management is handled through environment objects
- All data persistence uses UserDefaults with JSON encoding for complex structures
- Audio system uses multiple AVAudioPlayer instances for different sounds
- Notification permissions are handled automatically with user-friendly prompts
- Bundle identifier: `com.mirocosic.makonome`