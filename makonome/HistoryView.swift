//
//  HistoryView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "clock.arrow.circlepath")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("History")
                    .font(.largeTitle)
                
                Text("Your stopwatch history will appear here")
                    .foregroundStyle(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("History")
            .padding()
        }
    }
}

#Preview {
    HistoryView()
}