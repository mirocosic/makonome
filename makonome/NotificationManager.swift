//
//  NotificationManager.swift
//  makonome
//
//  Created by Miro on 30.06.2025.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    @Published var notificationTime = Date()
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationIdentifier = "dailyPracticeReminder"
    private let enabledKey = "DailyPracticeReminderEnabled"
    private let timeKey = "DailyPracticeReminderTime"
    
    override private init() {
        super.init()
        loadSettings()
        // Set up delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = self
        // Permission status will be checked when needed
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        isNotificationEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        
        if let timeData = UserDefaults.standard.data(forKey: timeKey),
           let savedTime = try? JSONDecoder().decode(Date.self, from: timeData) {
            notificationTime = savedTime
        } else {
            // Default to 9:00 AM
            let calendar = Calendar.current
            let components = DateComponents(hour: 9, minute: 0)
            notificationTime = calendar.date(from: components) ?? Date()
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isNotificationEnabled, forKey: enabledKey)
        
        if let timeData = try? JSONEncoder().encode(notificationTime) {
            UserDefaults.standard.set(timeData, forKey: timeKey)
        }
    }
    
    // MARK: - Permission Management
    
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.permissionStatus = settings.authorizationStatus
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.permissionStatus = granted ? .authorized : .denied
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            await MainActor.run {
                self.permissionStatus = .denied
            }
            return false
        }
    }
    
    // MARK: - Notification Scheduling
    
    func enableNotifications() async {
        guard permissionStatus != .authorized else {
            await scheduleNotification()
            await MainActor.run {
                self.isNotificationEnabled = true
                self.saveSettings()
            }
            return
        }
        
        let granted = await requestNotificationPermission()
        if granted {
            await scheduleNotification()
            await MainActor.run {
                self.isNotificationEnabled = true
                self.saveSettings()
            }
        } else {
            // Permission denied, don't enable notifications
            await MainActor.run {
                self.isNotificationEnabled = false
                self.saveSettings()
            }
        }
    }
    
    func disableNotifications() {
        cancelNotification()
        isNotificationEnabled = false
        saveSettings()
    }
    
    func updateNotificationTime(_ newTime: Date) async {
        notificationTime = newTime
        saveSettings()
        
        if isNotificationEnabled && permissionStatus == .authorized {
            await scheduleNotification()
        }
    }
    
    private func scheduleNotification() async {
        let center = UNUserNotificationCenter.current()
        
        // Cancel existing notification
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Practice!"
        content.body = getPracticeMessage()
        content.sound = .default
        content.categoryIdentifier = "PRACTICE_REMINDER"
        
        // Create trigger for daily notification
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("📝 Scheduled daily practice reminder for \(formatTime(notificationTime))")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    private func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        print("📝 Cancelled daily practice reminder")
    }
    
    // MARK: - Helper Methods
    
    private func getPracticeMessage() -> String {
        let messages = [
            "Ready for your daily practice session?",
            "Time to make some music!",
            "Your practice session awaits 🎵",
            "Let's build those musical skills!",
            "Ready to practice with your metronome?",
            "Time to keep the beat going!",
            "Your daily practice reminder is here!",
            "Let's make today's practice count!"
        ]
        return messages.randomElement() ?? messages[0]
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Developer/Testing Methods
    
    func sendTestNotification() async -> Bool {
        print("🧪 Starting test notification...")
        
        // Check current permission status
        await checkPermissionStatus()
        print("🔒 Current permission status: \(permissionStatus)")
        
        // Request permission if needed
        if permissionStatus != .authorized {
            print("🔑 Requesting notification permission...")
            let granted = await requestNotificationPermission()
            print("🔑 Permission granted: \(granted)")
            if !granted {
                print("❌ Permission denied, cannot send notification")
                return false
            }
        }
        
        let center = UNUserNotificationCenter.current()
        
        // Create test notification content
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "🧑‍💻 Dev Mode: " + getPracticeMessage()
        content.sound = .default
        content.categoryIdentifier = "PRACTICE_REMINDER_TEST"
        
        print("📝 Created notification content: \(content.title) - \(content.body)")
        
        // Create immediate trigger (1 second delay to ensure it fires)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request with unique identifier
        let requestId = "testNotification_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Successfully scheduled test notification with ID: \(requestId)")
            
            // Check pending notifications
            let pendingRequests = await center.pendingNotificationRequests()
            print("📋 Pending notifications count: \(pendingRequests.count)")
            
            return true
        } catch {
            print("❌ Error sending test notification: \(error)")
            return false
        }
    }
    
    // MARK: - Public Interface
    
    func toggleNotifications() async {
        if isNotificationEnabled {
            disableNotifications()
        } else {
            await enableNotifications()
        }
    }
    
    var canScheduleNotifications: Bool {
        permissionStatus == .authorized
    }
    
    var shouldRequestPermission: Bool {
        permissionStatus == .notDetermined
    }
    
    var permissionDenied: Bool {
        permissionStatus == .denied
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // This method is called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification delivered while app is in foreground: \(notification.request.content.title)")
        
        // For dev mode, show notifications even when app is in foreground
        if notification.request.content.categoryIdentifier == "PRACTICE_REMINDER_TEST" {
            print("🧑‍💻 Dev mode test notification - showing in foreground")
            completionHandler([.banner, .sound, .badge])
        } else {
            // For regular notifications, use default behavior (show in foreground)
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    // This method is called when the user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 User tapped on notification: \(response.notification.request.content.title)")
        
        // Handle notification tap here if needed
        // For example, could navigate to a specific screen
        
        completionHandler()
    }
}