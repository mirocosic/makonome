//
//  MainTabView.swift
//  makonome
//
//  Created by Miro on 24.06.2025..
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MetronomeView()
                .tabItem {
                    Image(systemName: "metronome")
                    Text("Metronome")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
    }
}

#Preview {
    MainTabView()
}