//
//  PresetView.swift
//  makonome
//
//  Created by Miro on 26.06.2025..
//

import SwiftUI

struct MetronomePreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var bpm: Double
    var beatsPerBar: Int
    var subdivision: NoteSubdivision
    var beatStates: [Int: BeatState]
    
    init(name: String, bpm: Double, beatsPerBar: Int, subdivision: NoteSubdivision, beatStates: [Int: BeatState] = [:]) {
        self.id = UUID()
        self.name = name
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.subdivision = subdivision
        self.beatStates = beatStates
    }
    
    init(id: UUID, name: String, bpm: Double, beatsPerBar: Int, subdivision: NoteSubdivision, beatStates: [Int: BeatState] = [:]) {
        self.id = id
        self.name = name
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.subdivision = subdivision
        self.beatStates = beatStates
    }
}

struct PresetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var presets: [MetronomePreset] = []
    @State private var showingAddPreset = false
    @State private var editingPreset: MetronomePreset?
    @Binding var currentBPM: Double
    @Binding var currentBeatsPerBar: Int
    @Binding var currentSubdivision: NoteSubdivision
    @Binding var currentBeatStates: [Int: BeatState]
    
    var body: some View {
        NavigationView {
            List {
                if presets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No presets yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Create your first preset to save metronome configurations")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(presets) { preset in
                        PresetRowView(preset: preset) {
                            loadPreset(preset)
                            dismiss()
                        }
                        .contextMenu {
                            Button("Edit") {
                                editingPreset = preset
                            }
                            Button("Delete", role: .destructive) {
                                deletePreset(preset)
                            }
                        }
                    }
                    .onDelete(perform: deletePresets)
                }
            }
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPreset = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPreset) {
            AddPresetView(
                currentBPM: currentBPM,
                currentBeatsPerBar: currentBeatsPerBar,
                currentSubdivision: currentSubdivision,
                currentBeatStates: currentBeatStates
            ) { preset in
                addPreset(preset)
            }
        }
        .sheet(item: $editingPreset) { preset in
            EditPresetView(preset: preset) { updatedPreset in
                updatePreset(updatedPreset)
            }
        }
        .onAppear {
            loadPresets()
        }
    }
    
    private func loadPreset(_ preset: MetronomePreset) {
        currentBPM = preset.bpm
        currentBeatsPerBar = preset.beatsPerBar
        currentSubdivision = preset.subdivision
        currentBeatStates = preset.beatStates
        
        UserDefaults.standard.set(preset.bpm, forKey: "MetronomeBPM")
        UserDefaults.standard.set(preset.beatsPerBar, forKey: "MetronomeBeatsPerBar")
        UserDefaults.standard.set(preset.subdivision.rawValue, forKey: "MetronomeSubdivision")
        
        if let encoded = try? JSONEncoder().encode(preset.beatStates) {
            UserDefaults.standard.set(encoded, forKey: "MetronomeBeatStates")
        }
    }
    
    private func addPreset(_ preset: MetronomePreset) {
        presets.append(preset)
        savePresets()
    }
    
    private func updatePreset(_ updatedPreset: MetronomePreset) {
        if let index = presets.firstIndex(where: { $0.id == updatedPreset.id }) {
            presets[index] = updatedPreset
            savePresets()
        }
    }
    
    private func deletePreset(_ preset: MetronomePreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }
    
    private func deletePresets(offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        savePresets()
    }
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "MetronomePresets"),
           let decoded = try? JSONDecoder().decode([MetronomePreset].self, from: data) {
            presets = decoded
        }
    }
    
    private func savePresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: "MetronomePresets")
        }
    }
}

struct PresetRowView: View {
    let preset: MetronomePreset
    let onLoad: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("\(Int(preset.bpm))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(preset.beatsPerBar)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("beats")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text(preset.subdivision.symbol)
                            .font(.subheadline)
                        Text(preset.subdivision.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !preset.beatStates.isEmpty {
                    let mutedBeats = preset.beatStates.filter { $0.value == .muted }.keys.sorted()
                    let accentedBeats = preset.beatStates.filter { $0.value == .accented }.keys.sorted()
                    
                    if !mutedBeats.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.slash")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Beats \(mutedBeats.map(String.init).joined(separator: ", ")) muted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !accentedBeats.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Beats \(accentedBeats.map(String.init).joined(separator: ", ")) accented")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button("Load") {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onLoad()
                }
            }
            .buttonStyle(.bordered)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .padding(.vertical, 4)
    }
}

struct AddPresetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    let currentBPM: Double
    let currentBeatsPerBar: Int
    let currentSubdivision: NoteSubdivision
    let currentBeatStates: [Int: BeatState]
    let onSave: (MetronomePreset) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preset Name")) {
                    TextField("Enter preset name", text: $name)
                }
                
                Section(header: Text("Current Settings")) {
                    HStack {
                        Text("BPM")
                        Spacer()
                        Text("\(Int(currentBPM))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Beats per Bar")
                        Spacer()
                        Text("\(currentBeatsPerBar)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Subdivision")
                        Spacer()
                        Text("\(currentSubdivision.symbol) \(currentSubdivision.rawValue)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !currentBeatStates.isEmpty {
                        let mutedBeats = currentBeatStates.filter { $0.value == .muted }.keys.sorted()
                        let accentedBeats = currentBeatStates.filter { $0.value == .accented }.keys.sorted()
                        
                        if !mutedBeats.isEmpty {
                            HStack {
                                Text("Muted Beats")
                                Spacer()
                                Text(mutedBeats.map(String.init).joined(separator: ", "))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !accentedBeats.isEmpty {
                            HStack {
                                Text("Accented Beats")
                                Spacer()
                                Text(accentedBeats.map(String.init).joined(separator: ", "))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let preset = MetronomePreset(
                            name: name.isEmpty ? "Untitled Preset" : name,
                            bpm: currentBPM,
                            beatsPerBar: currentBeatsPerBar,
                            subdivision: currentSubdivision,
                            beatStates: currentBeatStates
                        )
                        onSave(preset)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditPresetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    let preset: MetronomePreset
    let onSave: (MetronomePreset) -> Void
    
    init(preset: MetronomePreset, onSave: @escaping (MetronomePreset) -> Void) {
        self.preset = preset
        self.onSave = onSave
        self._name = State(initialValue: preset.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preset Name")) {
                    TextField("Enter preset name", text: $name)
                }
                
                Section(header: Text("Settings")) {
                    HStack {
                        Text("BPM")
                        Spacer()
                        Text("\(Int(preset.bpm))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Beats per Bar")
                        Spacer()
                        Text("\(preset.beatsPerBar)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Subdivision")
                        Spacer()
                        Text("\(preset.subdivision.symbol) \(preset.subdivision.rawValue)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !preset.beatStates.isEmpty {
                        let mutedBeats = preset.beatStates.filter { $0.value == .muted }.keys.sorted()
                        let accentedBeats = preset.beatStates.filter { $0.value == .accented }.keys.sorted()
                        
                        if !mutedBeats.isEmpty {
                            HStack {
                                Text("Muted Beats")
                                Spacer()
                                Text(mutedBeats.map(String.init).joined(separator: ", "))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !accentedBeats.isEmpty {
                            HStack {
                                Text("Accented Beats")
                                Spacer()
                                Text(accentedBeats.map(String.init).joined(separator: ", "))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedPreset = MetronomePreset(
                            id: preset.id,
                            name: name.isEmpty ? "Untitled Preset" : name,
                            bpm: preset.bpm,
                            beatsPerBar: preset.beatsPerBar,
                            subdivision: preset.subdivision,
                            beatStates: preset.beatStates
                        )
                        onSave(updatedPreset)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PresetView(
        currentBPM: .constant(120),
        currentBeatsPerBar: .constant(4),
        currentSubdivision: .constant(.quarter),
        currentBeatStates: .constant([:])
    )
}
