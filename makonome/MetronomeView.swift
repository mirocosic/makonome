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
    @ObservedObject private var metronomeManager = MetronomeManager.shared
    @State private var bpm: Double = {
        let savedBPM = UserDefaults.standard.double(forKey: "MetronomeBPM")
        let finalBPM = savedBPM != 0 ? savedBPM : 120
        print("🎵 Loading BPM from UserDefaults: savedBPM=\(savedBPM), finalBPM=\(finalBPM)")
        return finalBPM
    }()
    @State private var beatsPerBar = UserDefaults.standard.integer(forKey: "MetronomeBeatsPerBar") != 0 ? UserDefaults.standard.integer(forKey: "MetronomeBeatsPerBar") : 4
    @State private var subdivision: NoteSubdivision = NoteSubdivision(rawValue: UserDefaults.standard.string(forKey: "MetronomeSubdivision") ?? "") ?? .quarter
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
    @State private var isTempoChangerEnabled = UserDefaults.standard.bool(forKey: "TempoChangerEnabled")
    @State private var tempoChangerBPMIncrement = UserDefaults.standard.integer(forKey: "TempoChangerBPMIncrement") != 0 ? UserDefaults.standard.integer(forKey: "TempoChangerBPMIncrement") : 2
    @State private var tempoChangerBarInterval = UserDefaults.standard.integer(forKey: "TempoChangerBarInterval") != 0 ? UserDefaults.standard.integer(forKey: "TempoChangerBarInterval") : 4
    @State private var tempoChangerStartingBar = 1
    @State private var showingTempoChangerPicker = false
    @State private var showingVolumeSheet = false
    @State private var showingTempoDetectionSheet = false
    @State private var displayVolume: Float = 0.8
    @State private var displayHapticEnabled = false
    
    
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
                Color.softBackground
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 30) {
                
                // Beat Indicators at the top
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
                            .scaleEffect(metronomeManager.isPlaying && metronomeManager.beatCount == beat ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: metronomeManager.beatCount)
                        }
                    }
                    
                    if metronomeManager.isPlaying {
                        VStack(spacing: 4) {
                            Text("Bar \(metronomeManager.barCount), Beat \(metronomeManager.beatCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if isGapTrainerEnabled {
                                Text(gapTrainerInNormalPhase ? "Normal (\(gapTrainerCurrentCycle)/\(gapTrainerNormalBars))" : "Muted (\(gapTrainerCurrentCycle)/\(gapTrainerMutedBars))")
                                    .font(.caption2)
                                    .foregroundColor(gapTrainerInNormalPhase ? .softBlue : .softOrange)
                                    .fontWeight(.medium)
                            }
                            
                            if isTempoChangerEnabled {
                                let barsCompleted = metronomeManager.barCount - tempoChangerStartingBar
                                let nextIncreaseIn = tempoChangerBarInterval - (barsCompleted % tempoChangerBarInterval)
                                Text("Tempo +\(tempoChangerBPMIncrement) in \(nextIncreaseIn) bars")
                                    .font(.caption2)
                                    .foregroundColor(.softGreen)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                VStack {
                    HStack(spacing: 20) {
                        Button(action: {
                            decrementBPM()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.softBlue)
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
                                .foregroundColor(.softBlue)
                        }
                        .disabled(bpm >= 400)
                    }
                    
                    Slider(value: $bpm, in: 40...400, step: 1)
                        .padding(.horizontal)
                        .onChange(of: bpm) { _, _ in
                            metronomeManager.bpm = bpm
                        }
                    
                    // BPMScrollWheel(bpm: $bpm)
                    //     .padding(.horizontal)
                    
                    // SimpleBPMScrollWheel(bpm: $bpm)
                    //     .padding(.horizontal)
                    
                    HStack {
                        Button(action: {
                            handleTapTempo()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.title2)
                                Text("Tap")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.softBlue.opacity(0.15))
                            .foregroundColor(.softBlue)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingTempoDetectionSheet = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.title2)
                                Text("Detect")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.softGreen.opacity(0.15))
                            .foregroundColor(.softGreen)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            metronomeManager.toggleMetronome()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: metronomeManager.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.title)
                                Text(metronomeManager.isPlaying ? "Stop" : "Start")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showVolumeSheet()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: displayVolume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(displayVolume == 0 ? .softRed : .softBlue)
                                
                                Text(displayVolume == 0 ? "Muted" : "\(Int(displayVolume * 100))%")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.softBlue.opacity(0.15))
                            .foregroundColor(displayVolume == 0 ? .softRed : .softBlue)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            displayHapticEnabled.toggle()
                            metronomeManager.isHapticFeedbackEnabled = displayHapticEnabled
                            triggerHapticFeedback()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: displayHapticEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                                    .font(.title2)
                                Text("Haptic")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.softBlue.opacity(0.15))
                            .foregroundColor(displayHapticEnabled ? .softBlue : .softGray)
                            .cornerRadius(8)
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    // Current settings display
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Text(subdivision.symbol)
                                Text(subdivision.rawValue)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("\(beatsPerBar)")
                                Text(beatsPerBar == 1 ? "beat" : "beats")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 16) {
                            if isGapTrainerEnabled {
                                HStack(spacing: 4) {
                                    Image(systemName: "pause.circle.fill")
                                        .font(.caption2)
                                    Text("Gap: \(gapTrainerNormalBars):\(gapTrainerMutedBars)")
                                }
                                .font(.caption)
                                .foregroundColor(.softBlue)
                            }
                            
                            if isTempoChangerEnabled {
                                HStack(spacing: 4) {
                                    Image(systemName: "speedometer")
                                        .font(.caption2)
                                    Text("Tempo: +\(tempoChangerBPMIncrement)/\(tempoChangerBarInterval)")
                                }
                                .font(.caption)
                                .foregroundColor(.softGreen)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // More options button
                    Menu {
                        Button(action: {
                            showingSubdivisionPicker = true
                        }) {
                            Label("Subdivision (\(subdivision.symbol) \(subdivision.rawValue))", systemImage: "music.note")
                        }
                        .disabled(metronomeManager.isPlaying)
                        
                        Button(action: {
                            showingBeatsPerBarPicker = true
                        }) {
                            Label("Beats Per Bar (\(beatsPerBar))", systemImage: "metronome")
                        }
                        .disabled(metronomeManager.isPlaying)
                        
                        Divider()
                        
                        Button(action: {
                            showingGapTrainerPicker = true
                        }) {
                            Label("Gap Trainer (\(isGapTrainerEnabled ? "On" : "Off"))", systemImage: isGapTrainerEnabled ? "pause.circle.fill" : "pause.circle")
                        }
                        .disabled(metronomeManager.isPlaying)
                        
                        Button(action: {
                            showingTempoChangerPicker = true
                        }) {
                            Label("Tempo Changer (\(isTempoChangerEnabled ? "On" : "Off"))", systemImage: "speedometer")
                        }
                        .disabled(metronomeManager.isPlaying)
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.softBlue)
                    }
                    .disabled(metronomeManager.isPlaying)
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
        .sheet(isPresented: $showingVolumeSheet) {
            VolumeControlSheet(metronomeManager: metronomeManager, displayVolume: $displayVolume)
        }
        .sheet(isPresented: $showingTempoDetectionSheet) {
            TempoDetectionView { detectedBPM in
                handleMicrophoneTempoDetection(detectedBPM)
                showingTempoDetectionSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSubdivisionPicker) {
            SubdivisionPickerSheet(subdivision: $subdivision)
        }
        .sheet(isPresented: $showingBeatsPerBarPicker) {
            BeatsPerBarPickerSheet(beatsPerBar: $beatsPerBar, cleanupMutedBeats: cleanupBeatStates)
        }
        .sheet(isPresented: $showingGapTrainerPicker) {
            GapTrainerPickerSheet(
                isGapTrainerEnabled: $isGapTrainerEnabled,
                gapTrainerNormalBars: $gapTrainerNormalBars,
                gapTrainerMutedBars: $gapTrainerMutedBars
            )
        }
        .sheet(isPresented: $showingTempoChangerPicker) {
            TempoChangerPickerSheet(
                isTempoChangerEnabled: $isTempoChangerEnabled,
                tempoChangerBPMIncrement: $tempoChangerBPMIncrement,
                tempoChangerBarInterval: $tempoChangerBarInterval
            )
        }
        .onAppear {
            displayVolume = metronomeManager.volume
            displayHapticEnabled = metronomeManager.isHapticFeedbackEnabled
            // Reset mute state since we're now using volume-based muting
            metronomeManager.isMuted = false
        }
    }
    
    
    
    private func beatIndicatorColor(for beat: Int) -> Color {
        // Gap trainer muted phase overrides everything
        if isGapTrainerEnabled && !gapTrainerInNormalPhase && metronomeManager.isPlaying {
            if metronomeManager.beatCount == beat {
                return Color.softOrange.opacity(0.8) // Muted phase active beat
            } else {
                return Color.softGray.opacity(0.4) // Muted phase inactive beats
            }
        }
        
        let beatState = beatStates[beat] ?? .normal
        
        switch beatState {
        case .muted:
            return Color.softGray.opacity(0.6)
        case .accented:
            if metronomeManager.isPlaying && metronomeManager.beatCount == beat {
                return Color.softRed.opacity(0.9)
            } else {
                return Color.softRed.opacity(0.4)
            }
        case .normal:
            if metronomeManager.isPlaying && metronomeManager.beatCount == beat {
                return Color.softBlue.opacity(0.9)
            } else {
                return Color.softGray.opacity(0.3)
            }
        }
    }
    
    private func beatIndicatorBorder(for beat: Int) -> Color {
        let beatState = beatStates[beat] ?? .normal
        switch beatState {
        case .accented:
            return Color.softRed.opacity(0.8)
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
            metronomeManager.bpm = bpm
        }
    }
    
    private func decrementBPM() {
        if bpm > 40 {
            bpm -= 1
            triggerHapticFeedback()
            metronomeManager.bpm = bpm
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
            metronomeManager.bpm = bpm
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
            metronomeManager.bpm = bpm
        } else {
            // Invalid input, revert to current BPM
            bpmInputText = String(Int(bpm))
        }
        
        isBPMInputFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingBPM = false
        }
    }
    
    private func showVolumeSheet() {
        triggerHapticFeedback()
        showingVolumeSheet = true
    }
    
    private func handleMicrophoneTempoDetection(_ detectedBPM: Double) {
        // Clamp BPM to valid range
        let clampedBPM = max(40, min(400, detectedBPM))
        bpm = clampedBPM
        triggerHapticFeedback()
        metronomeManager.bpm = bpm
        
        // Save the detected BPM
        UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
        print("🎵 Microphone detected BPM: \(Int(detectedBPM)) -> Applied: \(Int(clampedBPM))")
    }
}

struct VolumeControlSheet: View {
    @ObservedObject var metronomeManager: MetronomeManager
    @Binding var displayVolume: Float
    @Environment(\.dismiss) private var dismiss
    @State private var autoHideTimer: Timer?
    @State private var localVolume: Double = 0.0
    
    private var volumeIcon: String {
        let volume = metronomeManager.volume
        if volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Volume percentage
            Text("\(Int(localVolume * 100))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
            
            // Volume slider
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
                
                Slider(value: Binding(
                    get: { localVolume },
                    set: { newValue in
                        localVolume = newValue
                        metronomeManager.volume = Float(newValue)
                        displayVolume = Float(newValue)
                        restartAutoHideTimer()
                        // Trigger light haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                ), in: 0.0...1.0)
                .accentColor(.softBlue)
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.hidden) // We have our own
        .onAppear {
            localVolume = Double(metronomeManager.volume)
            displayVolume = metronomeManager.volume
            startAutoHideTimer()
        }
        .onDisappear {
            autoHideTimer?.invalidate()
        }
    }
    
    private func startAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
            dismiss()
        }
    }
    
    private func restartAutoHideTimer() {
        startAutoHideTimer()
    }
}

#Preview {
    MetronomeView()
}