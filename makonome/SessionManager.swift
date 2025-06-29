//
//  SessionManager.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import Foundation

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var sessions: [PracticeSession] = []
    @Published var currentSession: PracticeSession?
    
    private let sessionsKey = "PracticeSessions"
    private let currentSessionKey = "CurrentPracticeSession"
    
    private init() {
        loadSessions()
        loadCurrentSession()
    }
    
    // MARK: - Session Management
    
    func startSession(name: String = "Practice Session", targetDuration: TimeInterval? = nil, notes: String = "") {
        // Complete any existing session first
        if let current = currentSession {
            completeCurrentSession()
        }
        
        let newSession = PracticeSession(sessionName: name, targetDuration: targetDuration, notes: notes)
        currentSession = newSession
        saveCurrentSession()
        
        print("📝 Started new practice session: \(name)")
    }
    
    func completeCurrentSession() {
        guard var current = currentSession else { return }
        
        current.complete()
        sessions.append(current)
        currentSession = nil
        
        saveSessions()
        saveCurrentSession()
        
        print("📝 Completed practice session: \(current.sessionName), Duration: \(formatTime(current.duration))")
    }
    
    func updateCurrentSessionName(_ name: String) {
        currentSession?.sessionName = name
        saveCurrentSession()
    }
    
    func updateCurrentSessionNotes(_ notes: String) {
        currentSession?.notes = notes
        saveCurrentSession()
    }
    
    func updateCurrentSessionTarget(_ targetDuration: TimeInterval?) {
        currentSession?.targetDuration = targetDuration
        saveCurrentSession()
    }
    
    // MARK: - History Management
    
    func deleteSession(at indexSet: IndexSet) {
        sessions.remove(atOffsets: indexSet)
        saveSessions()
    }
    
    func deleteSession(_ session: PracticeSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    // MARK: - Statistics
    
    var totalPracticeTime: TimeInterval {
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    var averageSessionDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return totalPracticeTime / Double(sessions.count)
    }
    
    var sessionsThisWeek: [PracticeSession] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= weekAgo }
    }
    
    var practiceTimeThisWeek: TimeInterval {
        return sessionsThisWeek.reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Persistence
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
    
    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else { return }
        
        do {
            sessions = try JSONDecoder().decode([PracticeSession].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    private func saveCurrentSession() {
        do {
            if let currentSession = currentSession {
                let data = try JSONEncoder().encode(currentSession)
                UserDefaults.standard.set(data, forKey: currentSessionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: currentSessionKey)
            }
        } catch {
            print("Failed to save current session: \(error)")
        }
    }
    
    private func loadCurrentSession() {
        guard let data = UserDefaults.standard.data(forKey: currentSessionKey) else { return }
        
        do {
            currentSession = try JSONDecoder().decode(PracticeSession.self, from: data)
        } catch {
            print("Failed to load current session: \(error)")
        }
    }
    
    // MARK: - Utility
    
    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}