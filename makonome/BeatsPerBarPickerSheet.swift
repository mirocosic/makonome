//
//  BeatsPerBarPickerSheet.swift
//  makonome
//
//  Created by Claude on 28.06.2025.
//

import SwiftUI

struct BeatsPerBarPickerSheet: View {
    @Binding var beatsPerBar: Int
    @Environment(\.dismiss) private var dismiss
    let cleanupMutedBeats: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Beats Per Bar", selection: $beatsPerBar) {
                    ForEach(1...16, id: \.self) { beats in
                        HStack {
                            Text("\(beats)")
                            Text(beats == 1 ? "beat" : "beats")
                        }
                        .tag(beats)
                    }
                }
                .pickerStyle(.wheel)
                .onChange(of: beatsPerBar) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "MetronomeBeatsPerBar")
                    cleanupMutedBeats()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Beats Per Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.4)])
    }
}

#Preview {
    @Previewable @State var beatsPerBar: Int = 4
    BeatsPerBarPickerSheet(
        beatsPerBar: $beatsPerBar,
        cleanupMutedBeats: { print("Cleanup muted beats") }
    )
}