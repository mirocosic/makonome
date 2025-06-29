import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var usageTracker = UsageTracker.shared
    @State private var autoStartMetronome = UserDefaults.standard.bool(forKey: "AutoStartMetronomeWithPractice")
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("Total Usage Time")
                        
                        Spacer()
                        
                        Text(usageTracker.formattedTotalUsage())
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Usage Statistics")
                }
                
                Section {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        
                        //Spacer()
                        
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
                
                Section {
                    Toggle(isOn: $autoStartMetronome) {
                        HStack {
                            Image(systemName: "metronome")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-start metronome")
                                Text("Start metronome when starting practice sessions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: autoStartMetronome) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "AutoStartMetronomeWithPractice")
                    }
                } header: {
                    Text("Practice Integration")
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