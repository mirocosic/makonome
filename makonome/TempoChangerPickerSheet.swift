//
//  TempoChangerPickerSheet.swift
//  makonome
//
//  Created by Claude on 28.06.2025.
//

import SwiftUI

struct TempoChangerPickerSheet: View {
    @Binding var isTempoChangerEnabled: Bool
    @Binding var tempoChangerBPMIncrement: Int
    @Binding var tempoChangerBarInterval: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Toggle("Enable Tempo Changer", isOn: $isTempoChangerEnabled)
                        .font(.headline)
                        .onChange(of: isTempoChangerEnabled) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "TempoChangerEnabled")
                        }
                    
                    if isTempoChangerEnabled {
                        Text("Increase by \(tempoChangerBPMIncrement) BPM every \(tempoChangerBarInterval) bars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                if isTempoChangerEnabled {
                    HStack(spacing: 40) {
                        VStack {
                            Text("BPM Increment")
                                .font(.headline)
                            
                            Picker("BPM Increment", selection: $tempoChangerBPMIncrement) {
                                ForEach(1...10, id: \.self) { increment in
                                    Text("+\(increment)")
                                        .tag(increment)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .clipped()
                            .onChange(of: tempoChangerBPMIncrement) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "TempoChangerBPMIncrement")
                            }
                        }
                        
                        VStack {
                            Text("Bar Interval")
                                .font(.headline)
                            
                            Picker("Bar Interval", selection: $tempoChangerBarInterval) {
                                ForEach(1...10, id: \.self) { interval in
                                    Text("\(interval)")
                                        .tag(interval)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .clipped()
                            .onChange(of: tempoChangerBarInterval) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "TempoChangerBarInterval")
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Tempo Changer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.5)])
    }
}

#Preview {
    @Previewable @State var isEnabled = true
    @Previewable @State var bpmIncrement = 2
    @Previewable @State var barInterval = 4
    TempoChangerPickerSheet(
        isTempoChangerEnabled: $isEnabled,
        tempoChangerBPMIncrement: $bpmIncrement,
        tempoChangerBarInterval: $barInterval
    )
}