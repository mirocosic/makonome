import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var usageTracker = UsageTracker.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var metronomeManager = MetronomeManager.shared
    @State private var autoStartMetronome = UserDefaults.standard.bool(forKey: "AutoStartMetronomeWithPractice")
    @State private var showingPermissionAlert = false
    @State private var devModeEnabled = UserDefaults.standard.bool(forKey: "DeveloperModeEnabled")
    @State private var sendingTestNotification = false
    
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
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Picker("Metronome Sound", selection: $metronomeManager.selectedSound) {
                            ForEach(MetronomeSound.allCases, id: \.rawValue) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: metronomeManager.selectedSound) { _, newValue in
                            metronomeManager.updateSelectedSound(newValue)
                        }
                    }
                } header: {
                    Text("Metronome Sound")
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
                
                Section {
                    Toggle(isOn: Binding(
                        get: { notificationManager.isNotificationEnabled },
                        set: { _ in
                            Task {
                                await notificationManager.toggleNotifications()
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily practice reminder")
                                Text("Get reminded to practice every day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(notificationManager.permissionDenied)
                    
                    if notificationManager.isNotificationEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: Binding(
                                get: { notificationManager.notificationTime },
                                set: { newTime in
                                    Task {
                                        await notificationManager.updateNotificationTime(newTime)
                                    }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    if notificationManager.permissionDenied {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications disabled")
                                    .foregroundColor(.orange)
                                Text("Enable notifications in Settings to receive practice reminders")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Practice Reminders")
                }
                
                Section {
                    Toggle(isOn: $devModeEnabled) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Developer mode")
                                Text("Enable development and testing features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: devModeEnabled) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "DeveloperModeEnabled")
                    }
                    
                    if devModeEnabled {
                        Button(action: {
                            Task {
                                sendingTestNotification = true
                                let success = await notificationManager.sendTestNotification()
                                sendingTestNotification = false
                                
                                if success {
                                    print("✅ Test notification sent successfully")
                                } else {
                                    print("❌ Failed to send test notification")
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: sendingTestNotification ? "arrow.triangle.2.circlepath" : "bell.badge.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                    .rotationEffect(.degrees(sendingTestNotification ? 360 : 0))
                                    .animation(sendingTestNotification ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: sendingTestNotification)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sendingTestNotification ? "Sending..." : "Send test notification")
                                        .foregroundColor(.blue)
                                    Text("Trigger a test notification immediately")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .disabled(sendingTestNotification)
                    }
                } header: {
                    Text("Developer")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                Task {
                    await notificationManager.checkPermissionStatus()
                }
            }
        }
    }
}








#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}