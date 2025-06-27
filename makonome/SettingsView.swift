import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("Theme")
                        
                        Spacer()
                        
                        Picker("Theme", selection: $themeManager.selectedTheme) {
                            ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                                Text(theme.displayName).tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Settings")
        }
    }
}






#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}