//
//  MetronomeView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI
import AVFoundation

enum BeatState: String, CaseIterable, Codable {
    case normal = "normal"
    case muted = "muted"
    case accented = "accented"
    
    func next() -> BeatState {
        switch self {
        case .normal: return .accented
        case .accented: return .muted
        case .muted: return .normal
        }
    }
}

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
    @ObservedObject private var usageTracker = UsageTracker.shared
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
    @State private var beatStates: [Int: BeatState] = {
        let savedData = UserDefaults.standard.data(forKey: "MetronomeBeatStates")
        if let data = savedData, let decoded = try? JSONDecoder().decode([Int: BeatState].self, from: data) {
            return decoded
        }
        return [:]
    }()
    @State private var tapTimes: [Date] = []
    @State private var tapTimer: Timer?
    @State private var isEditingBPM = false
    @State private var bpmInputText = ""
    @FocusState private var isBPMInputFocused: Bool
    @State private var showingSubdivisionPicker = false
    @State private var showingBeatsPerBarPicker = false
    @State private var isGapTrainerEnabled = UserDefaults.standard.bool(forKey: "GapTrainerEnabled")
    @State private var gapTrainerNormalBars = UserDefaults.standard.integer(forKey: "GapTrainerNormalBars") != 0 ? UserDefaults.standard.integer(forKey: "GapTrainerNormalBars") : 4
    @State private var gapTrainerMutedBars = UserDefaults.standard.integer(forKey: "GapTrainerMutedBars") != 0 ? UserDefaults.standard.integer(forKey: "GapTrainerMutedBars") : 4
    @State private var showingGapTrainerPicker = false
    @State private var gapTrainerCurrentCycle = 1
    @State private var gapTrainerInNormalPhase = true
    
    
    static func calculateInterval(bpm: Double, subdivision: NoteSubdivision) -> TimeInterval {
        let baseInterval = 60.0 / bpm
        return baseInterval / subdivision.multiplier
    }
    
    var beatIndicatorSize: CGFloat {
        // Responsive sizing based on number of beats
        switch beatsPerBar {
        case 1...4: return 50
        case 5...8: return 45
        case 9...12: return 40
        default: return 35 // 13-16 beats
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    VStack(spacing: 30) {
                
                VStack {
                    HStack(spacing: 20) {
                        Button(action: {
                            decrementBPM()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        .disabled(bpm <= 40)
                        
                        Group {
                            if isEditingBPM {
                                TextField("BPM", text: $bpmInputText)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .multilineTextAlignment(.center)
                                    .frame(minWidth: 180)
                                    .keyboardType(.numberPad)
                                    .focused($isBPMInputFocused)
                                    .onSubmit {
                                        finishBPMEditing()
                                    }
                                    .onAppear {
                                        bpmInputText = String(Int(bpm))
                                        isBPMInputFocused = true
                                    }
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                finishBPMEditing()
                                            }
                                        }
                                    }
                                    .transition(.opacity.combined(with: .scale))
                            } else {
                                Text("\(Int(bpm)) BPM")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .frame(minWidth: 180)
                                    .onTapGesture {
                                        startBPMEditing()
                                    }
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: isEditingBPM)
                        
                        Button(action: {
                            incrementBPM()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        .disabled(bpm >= 400)
                    }
                    
                    // Slider(value: $bpm, in: 40...400, step: 1)
                    //     .padding(.horizontal)
                    //     .onChange(of: bpm) { _, _ in
                    //         updateBPMWhilePlaying()
                    //         UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
                    //     }
                    
                    // BPMScrollWheel(bpm: $bpm)
                    //     .padding(.horizontal)
                    
                    SimpleBPMScrollWheel(bpm: $bpm)
                        .padding(.horizontal)
                    
                    Button(action: {
                        handleTapTempo()
                    }) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text(tapTimes.isEmpty ? "Tap Tempo" : "Tap \(tapTimes.count)")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
                
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        VStack {
                            Text("Subdivision")
                                .font(.headline)
                            
                            Button(action: {
                                showingSubdivisionPicker = true
                            }) {
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
                            .sheet(isPresented: $showingSubdivisionPicker) {
                                SubdivisionPickerSheet(subdivision: $subdivision)
                            }
                        }
                        
                        VStack {
                            Text("Beats Per Bar")
                                .font(.headline)
                            
                            Button(action: {
                                showingBeatsPerBarPicker = true
                            }) {
                                HStack {
                                    Text("\(beatsPerBar)")
                                    Text(beatsPerBar == 1 ? "beat" : "beats")
                                    Image(systemName: "chevron.down")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .disabled(isPlaying)
                            .sheet(isPresented: $showingBeatsPerBarPicker) {
                                BeatsPerBarPickerSheet(beatsPerBar: $beatsPerBar, cleanupMutedBeats: cleanupBeatStates)
                            }
                        }
                    }
                    
                    VStack {
                        Text("Gap Trainer")
                            .font(.headline)
                        
                        Button(action: {
                            showingGapTrainerPicker = true
                        }) {
                            HStack {
                                Image(systemName: isGapTrainerEnabled ? "pause.circle.fill" : "pause.circle")
                                if isGapTrainerEnabled {
                                    Text("\(gapTrainerNormalBars) normal, \(gapTrainerMutedBars) muted")
                                } else {
                                    Text("Off")
                                }
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isGapTrainerEnabled ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .disabled(isPlaying)
                        .sheet(isPresented: $showingGapTrainerPicker) {
                            GapTrainerPickerSheet(
                                isGapTrainerEnabled: $isGapTrainerEnabled,
                                gapTrainerNormalBars: $gapTrainerNormalBars,
                                gapTrainerMutedBars: $gapTrainerMutedBars
                            )
                        }
                    }
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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(beatsPerBar, 8)), spacing: 12) {
                        ForEach(1...beatsPerBar, id: \.self) { beat in
                            Button(action: {
                                toggleBeatState(beat: beat)
                            }) {
                                Circle()
                                    .fill(beatIndicatorColor(for: beat))
                                    .frame(width: beatIndicatorSize, height: beatIndicatorSize)
                                    .overlay(
                                        Circle()
                                            .stroke(beatIndicatorBorder(for: beat), lineWidth: 3)
                                    )
                                    .overlay(
                                        beatIndicatorIcon(for: beat)
                                    )
                                    .overlay(
                                        Text("\(beat)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(beatIndicatorTextColor(for: beat))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(isPlaying && beatCount == beat ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: beatCount)
                        }
                    }
                    
                    if isPlaying {
                        VStack(spacing: 4) {
                            Text("Bar \(barCount), Beat \(beatCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if isGapTrainerEnabled {
                                Text(gapTrainerInNormalPhase ? "Normal (\(gapTrainerCurrentCycle)/\(gapTrainerNormalBars))" : "Muted (\(gapTrainerCurrentCycle)/\(gapTrainerMutedBars))")
                                    .font(.caption2)
                                    .foregroundColor(gapTrainerInNormalPhase ? .blue : .orange)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                    Spacer()
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            }
            .navigationTitle("Metronome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PresetView(
                        currentBPM: $bpm,
                        currentBeatsPerBar: $beatsPerBar,
                        currentSubdivision: $subdivision,
                        currentBeatStates: $beatStates
                    )) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
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
        usageTracker.startTracking()
        
        // Reset gap trainer state
        if isGapTrainerEnabled {
            gapTrainerCurrentCycle = 1
            gapTrainerInNormalPhase = true
        }
        
        playBeat()
        startRegularTimer()
    }
    
    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        usageTracker.stopTracking()
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
            
            // Gap trainer logic - advance to next bar in cycle
            if isGapTrainerEnabled {
                gapTrainerCurrentCycle += 1
                
                if gapTrainerInNormalPhase {
                    // Currently in normal phase
                    if gapTrainerCurrentCycle > gapTrainerNormalBars {
                        // Switch to muted phase
                        gapTrainerInNormalPhase = false
                        gapTrainerCurrentCycle = 1
                    }
                } else {
                    // Currently in muted phase
                    if gapTrainerCurrentCycle > gapTrainerMutedBars {
                        // Switch back to normal phase
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
        let interval = Self.calculateInterval(bpm: bpm, subdivision: subdivision)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.playBeat()
        }
    }
    
    private func beatIndicatorColor(for beat: Int) -> Color {
        // Gap trainer muted phase overrides everything
        if isGapTrainerEnabled && !gapTrainerInNormalPhase && isPlaying {
            if beatCount == beat {
                return Color.orange.opacity(0.8) // Muted phase active beat
            } else {
                return Color.gray.opacity(0.4) // Muted phase inactive beats
            }
        }
        
        let beatState = beatStates[beat] ?? .normal
        
        switch beatState {
        case .muted:
            return Color.gray.opacity(0.6)
        case .accented:
            if isPlaying && beatCount == beat {
                return Color.red.opacity(0.9)
            } else {
                return Color.red.opacity(0.4)
            }
        case .normal:
            if isPlaying && beatCount == beat {
                return Color.blue.opacity(0.9)
            } else {
                return Color.gray.opacity(0.3)
            }
        }
    }
    
    private func beatIndicatorBorder(for beat: Int) -> Color {
        let beatState = beatStates[beat] ?? .normal
        switch beatState {
        case .accented:
            return Color.red.opacity(0.8)
        default:
            return Color.clear
        }
    }
    
    private func beatIndicatorIcon(for beat: Int) -> some View {
        let beatState = beatStates[beat] ?? .normal
        switch beatState {
        case .muted:
            return AnyView(
                Image(systemName: "speaker.slash")
                    .foregroundColor(.white)
                    .font(.caption)
            )
        case .accented:
            return AnyView(
                Image(systemName: "star.fill")
                    .foregroundColor(.white)
                    .font(.caption2)
            )
        case .normal:
            return AnyView(EmptyView())
        }
    }
    
    private func beatIndicatorTextColor(for beat: Int) -> Color {
        let beatState = beatStates[beat] ?? .normal
        switch beatState {
        case .muted:
            return .clear
        default:
            return .white
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
        // Check gap trainer muting first (overrides individual beat muting)
        if isGapTrainerEnabled && !gapTrainerInNormalPhase {
            return // Muted phase - no sound
        }
        
        // Regular muting checks
        guard !isMuted else { return }
        
        let beatState = beatStates[beatCount] ?? .normal
        
        switch beatState {
        case .muted:
            return // No sound for muted beats
        case .accented:
            AudioServicesPlaySystemSound(1103) // 1103 is louder click sound
        case .normal:
            AudioServicesPlaySystemSound(1104) // 1104 is click sound
        }
    }
    
    private func toggleBeatState(beat: Int) {
        let currentState = beatStates[beat] ?? .normal
        beatStates[beat] = currentState.next()
        saveBeatStates()
    }
    
    private func saveBeatStates() {
        if let encoded = try? JSONEncoder().encode(beatStates) {
            UserDefaults.standard.set(encoded, forKey: "MetronomeBeatStates")
        }
    }
    
    private func cleanupBeatStates() {
        // Remove any beat states that are greater than the current beatsPerBar
        beatStates = beatStates.filter { $0.key <= beatsPerBar }
        saveBeatStates()
    }
    
    private func incrementBPM() {
        if bpm < 400 {
            bpm += 1
            triggerHapticFeedback()
            updateBPMWhilePlaying()
            UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
        }
    }
    
    private func decrementBPM() {
        if bpm > 40 {
            bpm -= 1
            triggerHapticFeedback()
            updateBPMWhilePlaying()
            UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
        }
    }
    
    private func handleTapTempo() {
        let now = Date()
        tapTimes.append(now)
        
        // Reset tap timer
        tapTimer?.invalidate()
        tapTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.tapTimes.removeAll()
        }
        
        // Need at least 2 taps to calculate BPM
        if tapTimes.count >= 2 {
            let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let calculatedBPM = 60.0 / averageInterval
            
            // Clamp BPM to valid range
            let clampedBPM = max(40, min(400, calculatedBPM))
            bpm = clampedBPM
            triggerHapticFeedback()
            updateBPMWhilePlaying()
            UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
        }
        
        // Keep only the last 6 taps for better accuracy
        if tapTimes.count > 6 {
            tapTimes.removeFirst()
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func startBPMEditing() {
        bpmInputText = String(Int(bpm))
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingBPM = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isBPMInputFocused = true
        }
    }
    
    private func finishBPMEditing() {
        // Validate and update BPM
        if let newBPM = Double(bpmInputText), newBPM >= 40, newBPM <= 400 {
            bpm = newBPM
            triggerHapticFeedback()
            updateBPMWhilePlaying()
            UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
        } else {
            // Invalid input, revert to current BPM
            bpmInputText = String(Int(bpm))
        }
        
        isBPMInputFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingBPM = false
        }
    }
}



#Preview {
    MetronomeView()
}