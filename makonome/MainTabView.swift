//
//  MainTabView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView(selection: .constant(1)) {
            StopwatchView()
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Stopwatch")
                }
                .tag(0)
            
            MetronomeView()
                .tabItem {
                    Image(systemName: "metronome")
                    Text("Metronome")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}