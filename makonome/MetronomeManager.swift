//
//  MetronomeManager.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import Foundation
import AVFoundation

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
    
    
    // Private implementation details
    private var timer: Timer?
    private var lastBeatTime: Date?
    private var gapTrainerCurrentCycle = 1
    private var gapTrainerInNormalPhase = true
    private var tempoChangerStartingBar = 1
    private let usageTracker = UsageTracker.shared
    
    // Audio players for metronome clicks
    private var normalClickPlayer: AVAudioPlayer?
    private var accentClickPlayer: AVAudioPlayer?
    
    private init() {
        setupClickSounds()
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
        
        timer?.invalidate()
        timer = nil
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
        timer?.invalidate()
        startRegularTimer()
        
        print("🎵 Updated tempo to \(bpm) BPM while playing")
    }
    
    private func setupAudio() {
        do {
            // Use .playback category with .mixWithOthers option to play even when muted
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session configured to bypass mute switch")
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
                        timer?.invalidate()
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
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.playBeat()
        }
    }
    
    private func calculateInterval(bpm: Double, subdivision: NoteSubdivision) -> TimeInterval {
        let baseInterval = 60.0 / bpm
        return baseInterval / subdivision.multiplier
    }
    
    private func playClick() {
        // Check gap trainer muting first
        if isGapTrainerEnabled && !gapTrainerInNormalPhase {
            return
        }
        
        guard !isMuted else { return }
        
        let beatState = beatStates[beatCount] ?? .normal
        
        switch beatState {
        case .muted:
            return
        case .accented:
            playAccentClick()
        case .normal:
            playNormalClick()
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
            
            print("🔊 \(sound.rawValue) sounds loaded successfully from MP3 files")
        } catch {
            print("Failed to load metronome sounds: \(error)")
        }
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
}

