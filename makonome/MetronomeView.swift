//
//  MetronomeView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI
import AVFoundation

enum NoteSubdivision: String, CaseIterable, Codable {
    case quarter = "Quarter Notes"
    case eighth = "Eighth Notes"
    case sixteenth = "Sixteenth Notes"
    case triplets = "Triplets"
    
    var symbol: String {
        switch self {
        case .quarter: return "♩"
        case .eighth: return "♫"
        case .sixteenth: return "♬"
        case .triplets: return "♪♪♪"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .quarter: return 1.0
        case .eighth: return 2.0
        case .sixteenth: return 4.0
        case .triplets: return 3.0
        }
    }
}

struct MetronomeView: View {
    @State private var bpm: Double = UserDefaults.standard.double(forKey: "MetronomeBPM") != 0 ? UserDefaults.standard.double(forKey: "MetronomeBPM") : 120
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var beatCount = 0
    @State private var barCount = 1
    @State private var beatsPerBar = UserDefaults.standard.integer(forKey: "MetronomeBeatsPerBar") != 0 ? UserDefaults.standard.integer(forKey: "MetronomeBeatsPerBar") : 4
    @State private var subdivision: NoteSubdivision = NoteSubdivision(rawValue: UserDefaults.standard.string(forKey: "MetronomeSubdivision") ?? "") ?? .quarter
    @State private var lastBeatTime: Date?
    @State private var isMuted = UserDefaults.standard.bool(forKey: "MetronomeIsMuted")
    @State private var mutedBeats: Set<Int> = {
        let savedData = UserDefaults.standard.data(forKey: "MetronomeMutedBeats")
        if let data = savedData, let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return decoded
        }
        return Set<Int>()
    }()
    
    static func isAccentedBeat(beatCount: Int, subdivision: NoteSubdivision) -> Bool {
        return beatCount == 1  // First beat of each bar is accented
    }
    
    static func calculateInterval(bpm: Double, subdivision: NoteSubdivision) -> TimeInterval {
        let baseInterval = 60.0 / bpm
        return baseInterval / subdivision.multiplier
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                VStack {
                    Text("\(Int(bpm)) BPM")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Slider(value: $bpm, in: 40...400, step: 1)
                        .padding(.horizontal)
                        .onChange(of: bpm) { _, _ in
                            updateBPMWhilePlaying()
                            UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
                        }
                }
                
                VStack {
                    Text("Subdivision")
                        .font(.headline)
                    
                    Menu {
                        ForEach(NoteSubdivision.allCases, id: \.self) { subdivision in
                            Button(action: {
                                self.subdivision = subdivision
                                UserDefaults.standard.set(subdivision.rawValue, forKey: "MetronomeSubdivision")
                            }) {
                                HStack {
                                    Text(subdivision.symbol)
                                    Text(subdivision.rawValue)
                                    Spacer()
                                    if self.subdivision == subdivision {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .accessibilityLabel("\(subdivision.symbol) \(subdivision.rawValue)")
                        }
                    } label: {
                        HStack {
                            Text(subdivision.symbol)
                            Text(subdivision.rawValue)
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .disabled(isPlaying)
                }
                
                HStack(spacing: 20) {
                    Button(isPlaying ? "Stop" : "Start") {
                        toggleMetronome()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                    
                    Button(action: {
                        isMuted.toggle()
                        UserDefaults.standard.set(isMuted, forKey: "MetronomeIsMuted")
                    }) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(isMuted ? .red : .blue)
                    }
                    .buttonStyle(.bordered)
                }
                
                VStack {
                    HStack(spacing: 12) {
                        ForEach(1...beatsPerBar, id: \.self) { beat in
                            Button(action: {
                                toggleBeatMute(beat: beat)
                            }) {
                                Circle()
                                    .fill(beatIndicatorColor(for: beat))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(beatIndicatorBorder(for: beat), lineWidth: 3)
                                    )
                                    .overlay(
                                        mutedBeats.contains(beat) ? 
                                        Image(systemName: "speaker.slash")
                                            .foregroundColor(.white)
                                            .font(.title3) : nil
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(isPlaying && beatCount == beat ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: beatCount)
                        }
                    }
                    
                    if isPlaying {
                        Text("Bar \(barCount), Beat \(beatCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Metronome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PresetView(
                        currentBPM: $bpm,
                        currentBeatsPerBar: $beatsPerBar,
                        currentSubdivision: $subdivision,
                        currentMutedBeats: $mutedBeats
                    )) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .padding()
        }
    }
    
    private func toggleMetronome() {
        if isPlaying {
            stopMetronome()
        } else {
            startMetronome()
        }
    }
    
    private func startMetronome() {
        setupAudio()
        isPlaying = true
        playBeat()
        startRegularTimer()
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        beatCount = 0
        barCount = 1
        lastBeatTime = nil
    }
    
    private func updateBPMWhilePlaying() {
        guard isPlaying, let lastBeat = lastBeatTime else { return }
        
        let elapsed = Date().timeIntervalSince(lastBeat)
        let newInterval = Self.calculateInterval(bpm: bpm, subdivision: subdivision)
        let timeUntilNextBeat = max(0, newInterval - elapsed)
        
        timer?.invalidate()
        
        if timeUntilNextBeat > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: timeUntilNextBeat, repeats: false) { _ in
                self.playBeat()
                self.startRegularTimer()
            }
        } else {
            playBeat()
            startRegularTimer()
        }
    }
    
    private func playBeat() {
        beatCount += 1
        if beatCount > beatsPerBar {
            beatCount = 1
            barCount += 1
        }
        
        playClick()
        lastBeatTime = Date()
    }
    
    private func startRegularTimer() {
        let interval = Self.calculateInterval(bpm: bpm, subdivision: subdivision)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.playBeat()
        }
    }
    
    private func beatIndicatorColor(for beat: Int) -> Color {
        if mutedBeats.contains(beat) {
            return Color.gray.opacity(0.6)
        } else if isPlaying && beatCount == beat {
            return beat == 1 ? Color.red : Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private func beatIndicatorBorder(for beat: Int) -> Color {
        if beat == 1 {
            return Color.red.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func playClick() {
        guard !isMuted && !mutedBeats.contains(beatCount) else { return }
        
        if Self.isAccentedBeat(beatCount: beatCount, subdivision: subdivision) {
            AudioServicesPlaySystemSound(1103) // 1103 is louder click sound
        } else {
            AudioServicesPlaySystemSound(1104) // 1104 is click sound
        }
    }
    
    private func toggleBeatMute(beat: Int) {
        if mutedBeats.contains(beat) {
            mutedBeats.remove(beat)
        } else {
            mutedBeats.insert(beat)
        }
        saveMutedBeats()
    }
    
    private func saveMutedBeats() {
        if let encoded = try? JSONEncoder().encode(mutedBeats) {
            UserDefaults.standard.set(encoded, forKey: "MetronomeMutedBeats")
        }
    }
}

#Preview {
    MetronomeView()
}