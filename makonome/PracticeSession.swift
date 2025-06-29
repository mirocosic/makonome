//
//  PracticeSession.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import Foundation

struct PracticeSession: Identifiable, Codable {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    var sessionName: String
    var notes: String
    var targetDuration: TimeInterval? // Optional practice goal in seconds
    var shouldStartMetronome: Bool
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    var isCompleted: Bool {
        return endTime != nil
    }
    
    var isGoalMet: Bool {
        guard let targetDuration = targetDuration else { return false }
        return duration >= targetDuration
    }
    
    init(sessionName: String = "Practice Session", targetDuration: TimeInterval? = nil, notes: String = "", shouldStartMetronome: Bool = UserDefaults.standard.bool(forKey: "AutoStartMetronomeWithPractice")) {
        self.startTime = Date()
        self.sessionName = sessionName
        self.targetDuration = targetDuration
        self.notes = notes
        self.shouldStartMetronome = shouldStartMetronome
    }
    
    mutating func complete() {
        if endTime == nil {
            endTime = Date()
        }
    }
}

extension PracticeSession {
    static let sample = PracticeSession(sessionName: "Scale Practice", targetDuration: 1800, notes: "Worked on C major scales", shouldStartMetronome: true)
}