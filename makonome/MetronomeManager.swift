//
//  MetronomeManager.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import Foundation
import AVFoundation
import UIKit

enum MetronomeSound: String, CaseIterable, Codable {
    case click = "Click"
    case clave = "Clave"
    
    var normalSoundFile: String {
        switch self {
        case .click: return "click"
        case .clave: return "clave"
        }
    }
    
    var accentSoundFile: String {
        switch self {
        case .click: return "click1"
        case .clave: return "clave1"
        }
    }
}

class MetronomeManager: ObservableObject {
    static let shared = MetronomeManager()
    
    @Published var isPlaying = false
    @Published var beatCount = 0
    @Published var barCount = 1
    @Published var selectedSound: MetronomeSound = {
        let savedString = UserDefaults.standard.string(forKey: "MetronomeSelectedSound") ?? ""
        return MetronomeSound(rawValue: savedString) ?? .click
    }()
    
    // Metronome settings - loaded from UserDefaults
    var bpm: Double {
        get {
            let savedBPM = UserDefaults.standard.double(forKey: "MetronomeBPM")
            return savedBPM != 0 ? savedBPM : 120
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MetronomeBPM")
            updateTempoWhilePlaying()
        }
    }
    
    var beatsPerBar: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: "MetronomeBeatsPerBar")
            return saved != 0 ? saved : 4
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MetronomeBeatsPerBar")
        }
    }
    
    var subdivision: NoteSubdivision {
        get {
            let savedString = UserDefaults.standard.string(forKey: "MetronomeSubdivision") ?? ""
            return NoteSubdivision(rawValue: savedString) ?? .quarter
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "MetronomeSubdivision")
        }
    }
    
    var isMuted: Bool {
        get {
            UserDefaults.standard.bool(forKey: "MetronomeIsMuted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MetronomeIsMuted")
        }
    }
    
    var beatStates: [Int: BeatState] {
        get {
            guard let savedData = UserDefaults.standard.data(forKey: "MetronomeBeatStates"),
                  let decoded = try? JSONDecoder().decode([Int: BeatState].self, from: savedData) else {
                return [:]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "MetronomeBeatStates")
            }
        }
    }
    
    var isGapTrainerEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "GapTrainerEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "GapTrainerEnabled") }
    }
    
    var gapTrainerNormalBars: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: "GapTrainerNormalBars")
            return saved != 0 ? saved : 4
        }
        set { UserDefaults.standard.set(newValue, forKey: "GapTrainerNormalBars") }
    }
    
    var gapTrainerMutedBars: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: "GapTrainerMutedBars")
            return saved != 0 ? saved : 4
        }
        set { UserDefaults.standard.set(newValue, forKey: "GapTrainerMutedBars") }
    }
    
    var isTempoChangerEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "TempoChangerEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "TempoChangerEnabled") }
    }
    
    var tempoChangerBPMIncrement: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: "TempoChangerBPMIncrement")
            return saved != 0 ? saved : 2
        }
        set { UserDefaults.standard.set(newValue, forKey: "TempoChangerBPMIncrement") }
    }
    
    var tempoChangerBarInterval: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: "TempoChangerBarInterval")
            return saved != 0 ? saved : 4
        }
        set { UserDefaults.standard.set(newValue, forKey: "TempoChangerBarInterval") }
    }
    
    var isHapticFeedbackEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "HapticFeedbackEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "HapticFeedbackEnabled") }
    }
    
    var hapticIntensity: String {
        get { UserDefaults.standard.string(forKey: "HapticIntensity") ?? "medium" }
        set { UserDefaults.standard.set(newValue, forKey: "HapticIntensity") }
    }
    
    var volume: Float {
        get { 
            if UserDefaults.standard.object(forKey: "MetronomeVolume") == nil {
                // Key doesn't exist, return default
                return 0.8
            } else {
                // Key exists, return the stored value (could be 0.0)
                return UserDefaults.standard.float(forKey: "MetronomeVolume")
            }
        }
        set { 
            UserDefaults.standard.set(newValue, forKey: "MetronomeVolume")
            updateAudioPlayerVolumes()
        }
    }
    
    
    // Private implementation details
    private var timer: DispatchSourceTimer?
    private var lastBeatTime: Date?
    private var gapTrainerCurrentCycle = 1
    private var gapTrainerInNormalPhase = true
    private var tempoChangerStartingBar = 1
    private let usageTracker = UsageTracker.shared
    
    // Audio players for metronome clicks
    private var normalClickPlayer: AVAudioPlayer?
    private var accentClickPlayer: AVAudioPlayer?
    private var wasPlayingBeforeInterruption = false
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Haptic feedback generators
    private var lightHapticGenerator: UIImpactFeedbackGenerator?
    private var mediumHapticGenerator: UIImpactFeedbackGenerator?
    private var heavyHapticGenerator: UIImpactFeedbackGenerator?
    
    private init() {
        setupClickSounds()
        setupInterruptionHandling()
        setupHapticGenerators()
    }
    
    func updateSelectedSound(_ newSound: MetronomeSound) {
        selectedSound = newSound
        UserDefaults.standard.set(newSound.rawValue, forKey: "MetronomeSelectedSound")
        setupClickSounds() // Reload sounds when selection changes
    }
    
    // MARK: - Public Methods
    
    func startMetronome() {
        guard !isPlaying else { return }
        
        print("🎵 Starting metronome at BPM: \(bpm)")
        setupAudio()
        startBackgroundTask()
        isPlaying = true
        usageTracker.startTracking()
        
        // Reset gap trainer state
        if isGapTrainerEnabled {
            gapTrainerCurrentCycle = 1
            gapTrainerInNormalPhase = true
        }
        
        // Reset tempo changer state
        if isTempoChangerEnabled {
            tempoChangerStartingBar = barCount
        }
        
        playBeat()
        startRegularTimer()
    }
    
    func stopMetronome() {
        guard isPlaying else { return }
        
        timer?.cancel()
        timer = nil
        endBackgroundTask()
        isPlaying = false
        usageTracker.stopTracking()
        beatCount = 0
        barCount = 1
        lastBeatTime = nil
        
        print("🎵 Stopped metronome")
    }
    
    func toggleMetronome() {
        if isPlaying {
            stopMetronome()
        } else {
            startMetronome()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateTempoWhilePlaying() {
        guard isPlaying else { return }
        
        // Restart the timer with the new BPM
        timer?.cancel()
        startRegularTimer()
        
        print("🎵 Updated tempo to \(bpm) BPM while playing")
    }
    
    private func setupAudio() {
        setupAudioSession(forRecording: false)
    }
    
    func setupAudioSession(forRecording: Bool) {
        do {
            if forRecording {
                // Use .playAndRecord category for both metronome and microphone input
                try AVAudioSession.sharedInstance().setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.duckOthers, .allowBluetooth, .defaultToSpeaker]
                )
                print("🔊 Audio session configured for recording and playback")
            } else {
                // Use .playback category for background audio with comprehensive options
                try AVAudioSession.sharedInstance().setCategory(
                    .playback, 
                    mode: .default, 
                    options: [.duckOthers, .allowBluetooth]
                )
                print("🔊 Audio session configured for reliable background playback")
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func playBeat() {
        beatCount += 1
        if beatCount > beatsPerBar {
            beatCount = 1
            barCount += 1
            
            // Tempo changer logic
            if isTempoChangerEnabled {
                let barsCompleted = barCount - tempoChangerStartingBar
                if barsCompleted > 0 && barsCompleted % tempoChangerBarInterval == 0 {
                    let newBPM = min(bpm + Double(tempoChangerBPMIncrement), 400.0)
                    if newBPM != bpm {
                        print("🎵 Tempo Changer: Increasing BPM from \(bpm) to \(newBPM)")
                        bpm = newBPM
                        print("🎵 Tempo Changer: Saved BPM \(bpm) to UserDefaults")
                        // Update timer with new tempo for next beats
                        timer?.cancel()
                        startRegularTimer()
                    }
                }
            }
            
            // Gap trainer logic
            if isGapTrainerEnabled {
                gapTrainerCurrentCycle += 1
                
                if gapTrainerInNormalPhase {
                    if gapTrainerCurrentCycle > gapTrainerNormalBars {
                        gapTrainerInNormalPhase = false
                        gapTrainerCurrentCycle = 1
                    }
                } else {
                    if gapTrainerCurrentCycle > gapTrainerMutedBars {
                        gapTrainerInNormalPhase = true
                        gapTrainerCurrentCycle = 1
                    }
                }
            }
        }
        
        playClick()
        lastBeatTime = Date()
    }
    
    private func startRegularTimer() {
        let interval = calculateInterval(bpm: bpm, subdivision: subdivision)
        
        // Stop any existing timer
        timer?.cancel()
        
        // Create a new dispatch timer
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now() + interval, repeating: interval)
        timer?.setEventHandler { [weak self] in
            self?.playBeat()
        }
        timer?.resume()
    }
    
    private func calculateInterval(bpm: Double, subdivision: NoteSubdivision) -> TimeInterval {
        let baseInterval = 60.0 / bpm
        return baseInterval / subdivision.multiplier
    }
    
    private func playClick() {
        // Check gap trainer muting first
        if isGapTrainerEnabled && !gapTrainerInNormalPhase {
            // Trigger haptic even during gap trainer muted phase
            triggerHapticFeedback()
            return
        }
        
        let beatState = beatStates[beatCount] ?? .normal
        
        // Handle muted beats - no audio but still haptic
        if beatState == .muted {
            triggerHapticFeedback()
            return
        }
        
        // Handle normal and accented beats - play audio if not muted AND volume > 0
        if !isMuted && volume > 0 {
            switch beatState {
            case .accented:
                playAccentClick()
            case .normal:
                playNormalClick()
            case .muted:
                break // Already handled above
            }
        }
        
        // Trigger haptic for all non-muted beats
        switch beatState {
        case .accented:
            triggerHapticFeedback(isAccented: true)
        case .normal:
            triggerHapticFeedback()
        case .muted:
            break // Already handled above
        }
    }
    
    // MARK: - Audio Generation
    
    private func setupClickSounds() {
        do {
            let sound = selectedSound
            
            // Load normal sound from MP3 file
            guard let normalSoundURL = Bundle.main.url(forResource: sound.normalSoundFile, withExtension: "mp3") else {
                print("Failed to find \(sound.normalSoundFile).mp3 file")
                return
            }
            normalClickPlayer = try AVAudioPlayer(contentsOf: normalSoundURL)
            normalClickPlayer?.prepareToPlay()
            
            // Load accent sound from MP3 file
            guard let accentSoundURL = Bundle.main.url(forResource: sound.accentSoundFile, withExtension: "mp3") else {
                print("Failed to find \(sound.accentSoundFile).mp3 file")
                return
            }
            accentClickPlayer = try AVAudioPlayer(contentsOf: accentSoundURL)
            accentClickPlayer?.prepareToPlay()
            
            // Set initial volume
            updateAudioPlayerVolumes()
            
            print("🔊 \(sound.rawValue) sounds loaded successfully from MP3 files")
        } catch {
            print("Failed to load metronome sounds: \(error)")
        }
    }
    
    private func updateAudioPlayerVolumes() {
        normalClickPlayer?.volume = volume
        accentClickPlayer?.volume = volume
    }
    
    
    private func playNormalClick() {
        normalClickPlayer?.stop()
        normalClickPlayer?.currentTime = 0
        normalClickPlayer?.play()
    }
    
    private func playAccentClick() {
        accentClickPlayer?.stop()
        accentClickPlayer?.currentTime = 0
        accentClickPlayer?.play()
    }
    
    // MARK: - Haptic Feedback
    
    private func setupHapticGenerators() {
        lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
        mediumHapticGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
        
        // Prepare generators for more responsive feedback
        lightHapticGenerator?.prepare()
        mediumHapticGenerator?.prepare()
        heavyHapticGenerator?.prepare()
    }
    
    private func triggerHapticFeedback(isAccented: Bool = false) {
        guard isHapticFeedbackEnabled else { return }
        
        // Skip haptic feedback at very high tempos to prevent performance issues
        let effectiveBPM = bpm * subdivision.multiplier
        guard effectiveBPM <= 300 else { return }
        
        let generator: UIImpactFeedbackGenerator?
        
        if isAccented {
            // Always use heavy haptic for accented beats regardless of setting
            generator = heavyHapticGenerator
        } else {
            // Use user's selected intensity for normal beats
            switch hapticIntensity {
            case "light":
                generator = lightHapticGenerator
            case "heavy":
                generator = heavyHapticGenerator
            default: // "medium"
                generator = mediumHapticGenerator
            }
        }
        
        generator?.impactOccurred()
    }
    
    // MARK: - Audio Interruption Handling
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio interruption began (e.g., phone call)
            if isPlaying {
                wasPlayingBeforeInterruption = true
                stopMetronome()
                print("🔊 Audio interrupted - metronome stopped")
            }
            
        case .ended:
            // Audio interruption ended
            if wasPlayingBeforeInterruption {
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        // Reactivate audio session and resume playback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.resumeAfterInterruption()
                        }
                    }
                }
                wasPlayingBeforeInterruption = false
            }
            
        @unknown default:
            break
        }
    }
    
    private func resumeAfterInterruption() {
        do {
            // Reactivate audio session
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Resume metronome
            startMetronome()
            print("🔊 Audio interruption ended - metronome resumed")
        } catch {
            print("🔊 Failed to resume after interruption: \(error)")
            // Try again with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.resumeAfterInterruption()
            }
        }
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        endBackgroundTask() // End any existing task first
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "MetronomePlayback") { [weak self] in
            // Called when background time is about to expire
            print("🔊 Background task expired - stopping metronome")
            self?.stopMetronome()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}

