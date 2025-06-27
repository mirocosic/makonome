//
//  makonomeApp.swift
//  makonome
//
//  Created by Miro on 23.06.2025..
//

import SwiftUI

@main
struct makonomeApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
