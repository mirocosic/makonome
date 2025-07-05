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
        VStack(spacing: 20) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("Beats Per Bar")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
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
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    @Previewable @State var beatsPerBar: Int = 4
    BeatsPerBarPickerSheet(
        beatsPerBar: $beatsPerBar,
        cleanupMutedBeats: { print("Cleanup muted beats") }
    )
}