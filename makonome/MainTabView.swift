//
//  MainTabView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var sessionManager = SessionManager.shared
    
    private var practiceTabText: String {
        if let currentSession = sessionManager.currentSession {
            return sessionManager.formatTime(currentSession.duration)
        } else {
            return "Practice"
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MetronomeView()
                .tabItem {
                    Image(systemName: "metronome")
                    Text("Metronome")
                }
                .tag(0)
            
            PracticeSessionView()
                .tabItem {
                    Image(systemName: "timer")
                    Text(practiceTabText)
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}