//
//  GapTrainerPickerSheet.swift
//  makonome
//
//  Created by Claude on 28.06.2025.
//

import SwiftUI

struct GapTrainerPickerSheet: View {
    @Binding var isGapTrainerEnabled: Bool
    @Binding var gapTrainerNormalBars: Int
    @Binding var gapTrainerMutedBars: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Toggle("Enable Gap Trainer", isOn: $isGapTrainerEnabled)
                        .font(.headline)
                        .onChange(of: isGapTrainerEnabled) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "GapTrainerEnabled")
                        }
                    
                    if isGapTrainerEnabled {
                        Text("Pattern: \(gapTrainerNormalBars) normal → \(gapTrainerMutedBars) muted → repeat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                if isGapTrainerEnabled {
                    HStack(spacing: 40) {
                        VStack {
                            Text("Normal Bars")
                                .font(.headline)
                            
                            Picker("Normal Bars", selection: $gapTrainerNormalBars) {
                                ForEach(1...16, id: \.self) { bars in
                                    Text("\(bars)")
                                        .tag(bars)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .clipped()
                            .onChange(of: gapTrainerNormalBars) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "GapTrainerNormalBars")
                            }
                        }
                        
                        VStack {
                            Text("Muted Bars")
                                .font(.headline)
                            
                            Picker("Muted Bars", selection: $gapTrainerMutedBars) {
                                ForEach(1...16, id: \.self) { bars in
                                    Text("\(bars)")
                                        .tag(bars)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                            .clipped()
                            .onChange(of: gapTrainerMutedBars) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "GapTrainerMutedBars")
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Gap Trainer")
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
    @Previewable @State var normalBars = 4
    @Previewable @State var mutedBars = 2
    GapTrainerPickerSheet(
        isGapTrainerEnabled: $isEnabled,
        gapTrainerNormalBars: $normalBars,
        gapTrainerMutedBars: $mutedBars
    )
}