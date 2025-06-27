import Foundation

class UsageTracker: ObservableObject {
    static let shared = UsageTracker()
    
    private static let totalUsageKey = "MetronomeTotalUsageSeconds"
    private var sessionStartTime: Date?
    
    @Published var totalUsageSeconds: Double = 0
    
    private init() {
        loadTotalUsage()
    }
    
    func startTracking() {
        sessionStartTime = Date()
    }
    
    func stopTracking() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        totalUsageSeconds += sessionDuration
        saveTotalUsage()
        sessionStartTime = nil
    }
    
    private func loadTotalUsage() {
        totalUsageSeconds = UserDefaults.standard.double(forKey: Self.totalUsageKey)
    }
    
    private func saveTotalUsage() {
        UserDefaults.standard.set(totalUsageSeconds, forKey: Self.totalUsageKey)
    }
    
    func formattedTotalUsage() -> String {
        let hours = Int(totalUsageSeconds) / 3600
        let minutes = Int(totalUsageSeconds) % 3600 / 60
        let seconds = Int(totalUsageSeconds) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}