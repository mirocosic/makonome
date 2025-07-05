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
        VStack(spacing: 20) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("Subdivision")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
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
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    @Previewable @State var subdivision: NoteSubdivision = .quarter
    SubdivisionPickerSheet(subdivision: $subdivision)
}