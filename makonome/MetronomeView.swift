//
//  MetronomeView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI
import AVFoundation

enum NoteSubdivision: String, CaseIterable {
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
    @State private var bpm: Double = 120
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var beatCount = 1
    @State private var subdivision: NoteSubdivision = .quarter
    
    static func isAccentedBeat(beatCount: Int, subdivision: NoteSubdivision) -> Bool {
        switch subdivision {
        case .quarter:
            return beatCount % 1 == 0  // Every quarter note
        case .eighth:
            return beatCount % 2 == 1  // Every 2nd eighth note (every quarter note)
        case .sixteenth:
            return beatCount % 4 == 1  // Every 4th sixteenth note (every quarter note)
        case .triplets:
            return beatCount % 3 == 1  // Every 3rd triplet (every quarter note)
        }
    }
    
    static func calculateInterval(bpm: Double, subdivision: NoteSubdivision) -> TimeInterval {
        let baseInterval = 60.0 / bpm
        return baseInterval / subdivision.multiplier
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "metronome")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Metronome")
                    .font(.largeTitle)
                
                VStack {
                    Text("\(Int(bpm)) BPM")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Slider(value: $bpm, in: 40...400, step: 1)
                        .disabled(isPlaying)
                        .padding(.horizontal)
                }
                
                VStack {
                    Text("Subdivision")
                        .font(.headline)
                    
                    Menu {
                        ForEach(NoteSubdivision.allCases, id: \.self) { subdivision in
                            Button(action: {
                                self.subdivision = subdivision
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
                
                Button(isPlaying ? "Stop" : "Start") {
                    toggleMetronome()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)
                
                if isPlaying {
                    VStack {
                        Circle()
                            .fill(Self.isAccentedBeat(beatCount: beatCount, subdivision: subdivision) ? Color.red : Color.blue)
                            .frame(width: 60, height: 60)
                            .animation(.easeInOut(duration: 0.1), value: beatCount)
                        
                        Text("Beat: \(beatCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Metronome")
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
        let interval = Self.calculateInterval(bpm: bpm, subdivision: subdivision)

        isPlaying = true
        playClick()
        
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            beatCount += 1
            playClick()
            
        }
        
        
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        beatCount = 1
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
        if Self.isAccentedBeat(beatCount: beatCount, subdivision: subdivision) {
            AudioServicesPlaySystemSound(1103) // 1103 is louder click sound
        } else {
            AudioServicesPlaySystemSound(1104) // 1104 is click sound
        }
    }
}

#Preview {
    MetronomeView()
}