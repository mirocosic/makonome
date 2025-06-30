//
//  MetronomeManager.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import Foundation
import AVFoundation

class MetronomeManager: ObservableObject {
    static let shared = MetronomeManager()
    
    @Published var isPlaying = false
    @Published var beatCount = 0
    @Published var barCount = 1
    
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
            // Generate normal click sound (800Hz sine wave)
            normalClickPlayer = try createTonePlayer(frequency: 800, duration: 0.1)
            normalClickPlayer?.prepareToPlay()
            
            // Generate accent click sound (1200Hz sine wave)
            accentClickPlayer = try createTonePlayer(frequency: 1200, duration: 0.1)
            accentClickPlayer?.prepareToPlay()
            
            print("🔊 Click sounds generated successfully")
        } catch {
            print("Failed to create click sounds: \(error)")
        }
    }
    
    private func createTonePlayer(frequency: Double, duration: Double) throws -> AVAudioPlayer {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)
        
        // Create audio buffer
        var audioData = Data()
        
        for frame in 0..<frameCount {
            let sample = sin(2.0 * Double.pi * frequency * Double(frame) / sampleRate)
            let scaledSample = Int16(sample * 32767.0)
            
            var littleEndianSample = scaledSample.littleEndian
            audioData.append(Data(bytes: &littleEndianSample, count: MemoryLayout<Int16>.size))
        }
        
        // Create WAV header
        let wavHeader = createWAVHeader(dataSize: audioData.count, sampleRate: Int(sampleRate))
        let wavData = wavHeader + audioData
        
        return try AVAudioPlayer(data: wavData)
    }
    
    private func createWAVHeader(dataSize: Int, sampleRate: Int) -> Data {
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(UInt32(36 + dataSize).littleEndian.data)
        header.append("WAVE".data(using: .ascii)!)
        
        // Format chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(UInt32(16).littleEndian.data) // PCM chunk size
        header.append(UInt16(1).littleEndian.data)  // PCM format
        header.append(UInt16(1).littleEndian.data)  // Mono
        header.append(UInt32(sampleRate).littleEndian.data)
        header.append(UInt32(sampleRate * 2).littleEndian.data) // Byte rate
        header.append(UInt16(2).littleEndian.data)  // Block align
        header.append(UInt16(16).littleEndian.data) // Bits per sample
        
        // Data chunk
        header.append("data".data(using: .ascii)!)
        header.append(UInt32(dataSize).littleEndian.data)
        
        return header
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

// MARK: - Extensions for WAV generation
extension FixedWidthInteger {
    var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}