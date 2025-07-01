# Metronome Timing Jitter Fix - Upgrade Plan

## Problem Statement
The current metronome implementation experiences timing jitter, especially at faster tempos. This is caused by AVAudioPlayer's inherent latency and timing inconsistencies.

## Root Cause Analysis
The current implementation uses AVAudioPlayer which has fundamental timing issues:
- ~10ms overhead per `play()` call that accumulates over time
- Competes with SwiftUI updates on main thread causing delays
- No sample-accurate timing guarantees
- Timer-based approach (even with CADisplayLink) cannot achieve professional precision

## Research Findings
- Professional metronome apps achieve ±20μs timing accuracy
- AVAudioEngine with sample-accurate scheduling is the industry standard
- Core Audio buffer-based approach eliminates timing drift
- AVAudioPlayer is insufficient for precision timing applications

## Solution: Replace AVAudioPlayer with AVAudioEngine

### Phase 1: Core Audio Engine Setup
1. **Replace AVAudioPlayer with AVAudioEngine + AVAudioPlayerNode**
   - Create AVAudioEngine instance with mixer and output nodes
   - Use AVAudioPlayerNode for sample-accurate playback
   - Load audio files into AVAudioPCMBuffer for zero-latency access

### Phase 2: Precise Timing Implementation  
2. **Implement Buffer-Based Scheduling**
   - Pre-calculate exact sample positions for each beat
   - Schedule audio buffers at precise sample times using `scheduleBuffer(at:)`
   - Use `AVAudioTime` with sample-accurate positioning

### Phase 3: Timing Engine Redesign
3. **Replace CADisplayLink with Audio-Driven Timing**
   - Use audio thread callbacks instead of display link
   - Calculate beat positions based on sample rate (44.1kHz/48kHz)
   - Achieve professional metronome timing precision

### Phase 4: Buffer Management
4. **Implement Continuous Audio Stream**
   - Create looping buffers with precise silence intervals
   - Schedule multiple buffers ahead of time to prevent gaps
   - Handle tempo changes by recalculating buffer schedules dynamically

## Technical Implementation Details

### Key Components to Change
- **MetronomeManager.swift**: Complete rewrite of audio system
- **Audio Session**: Configure for low-latency audio processing
- **Buffer Management**: Pre-load and schedule audio buffers
- **Timing Calculation**: Sample-accurate beat positioning

### Code Architecture
```swift
// New components needed:
- AVAudioEngine (main audio processing)
- AVAudioPlayerNode (for each click type)
- AVAudioPCMBuffer (pre-loaded audio data)
- Sample-accurate scheduling logic
- Buffer completion handlers for continuous playback
```

## Expected Outcomes
- **Eliminate timing jitter** at all tempos (40-400 BPM)
- **Achieve professional-grade timing** precision (±20μs accuracy)
- **Maintain compatibility** with existing metronome features
- **Improve performance**, especially at high tempos and subdivisions
- **Reduce CPU usage** through efficient buffer management

## Implementation Complexity
- **Complexity Level**: Medium-High (requires Core Audio knowledge)
- **Estimated Time**: 2-3 hours for complete implementation
- **Risk Level**: Low (can fallback to current system if needed)
- **Dependencies**: No additional frameworks required (Core Audio is built-in)

## Migration Strategy
1. Keep current AVAudioPlayer implementation as fallback
2. Implement new AVAudioEngine system alongside existing code
3. Add feature flag to switch between implementations
4. Test thoroughly across different devices and iOS versions
5. Remove old implementation once new system is proven stable

## Testing Plan
- Test timing accuracy across full BPM range (40-400)
- Verify all subdivisions work correctly
- Test gap trainer and tempo changer features
- Validate on multiple device types (iPhone, iPad)
- Measure actual timing precision with audio analysis tools

## Future Enhancements
Once the core timing is fixed, additional professional features could be added:
- **Visual metronome** with sample-accurate animations
- **MIDI sync** capability for professional music production
- **Custom time signatures** beyond current 16-beat limit
- **Polyrhythm support** for advanced practice

---
*Created: June 30, 2025*
*Status: Planning Phase*