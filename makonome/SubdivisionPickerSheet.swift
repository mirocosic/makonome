//
//  SubdivisionPickerSheet.swift
//  makonome
//
//  Created by Claude on 28.06.2025.
//

import SwiftUI

struct SubdivisionPickerSheet: View {
    @Binding var subdivision: NoteSubdivision
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Subdivision", selection: $subdivision) {
                    ForEach(NoteSubdivision.allCases, id: \.self) { subdivision in
                        HStack {
                            Text(subdivision.symbol)
                            Text(subdivision.rawValue)
                        }
                        .tag(subdivision)
                    }
                }
                .pickerStyle(.wheel)
                .onChange(of: subdivision) { _, newValue in
                    UserDefaults.standard.set(newValue.rawValue, forKey: "MetronomeSubdivision")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Subdivision")
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
    @Previewable @State var subdivision: NoteSubdivision = .quarter
    SubdivisionPickerSheet(subdivision: $subdivision)
}