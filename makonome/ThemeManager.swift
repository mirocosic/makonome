import SwiftUI

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var selectedTheme: String = AppTheme.system.rawValue
    
    var currentTheme: AppTheme {
        AppTheme(rawValue: selectedTheme) ?? .system
    }
    
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}