//
//  SessionHistoryView.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import SwiftUI

struct SessionHistoryView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedPeriod: TimePeriod = .all
    
    enum TimePeriod: String, CaseIterable {
        case all = "All Time"
        case week = "This Week"
        case month = "This Month"
    }
    
    var filteredSessions: [PracticeSession] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .all:
            return sessionManager.sessions
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return sessionManager.sessions.filter { $0.startTime >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return sessionManager.sessions.filter { $0.startTime >= monthAgo }
        }
    }
    
    var totalTimeForPeriod: TimeInterval {
        return filteredSessions.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.softBackground
                    .ignoresSafeArea()
                
                VStack {
                if sessionManager.sessions.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .imageScale(.large)
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No Sessions Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your practice sessions will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    Spacer()
                    
                } else {
                    // Sessions list
                    VStack(spacing: 0) {
                        // Period selector
                        Picker("Time Period", selection: $selectedPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        // Summary stats
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(filteredSessions.count)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Text("Sessions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(sessionManager.formatTime(totalTimeForPeriod))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                    Text("Total Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            if filteredSessions.count > 0 {
                                HStack {
                                    Text("Average: \(sessionManager.formatTime(totalTimeForPeriod / Double(filteredSessions.count)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    let goalsMetCount = filteredSessions.filter { $0.isGoalMet }.count
                                    if goalsMetCount > 0 {
                                        Text("Goals met: \(goalsMetCount)/\(filteredSessions.filter { $0.targetDuration != nil }.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        
                        // Sessions list
                        List {
                            ForEach(filteredSessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                                SessionRowView(session: session)
                            }
                            .onDelete(perform: deleteSessions)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Practice History")
            .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        let sortedSessions = filteredSessions.sorted(by: { $0.startTime > $1.startTime })
        for index in offsets {
            sessionManager.deleteSession(sortedSessions[index])
        }
    }
}

struct SessionRowView: View {
    let session: PracticeSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.sessionName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(SessionManager.shared.formatTime(session.duration))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    
                    if session.isGoalMet {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            HStack {
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(session.startTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let targetDuration = session.targetDuration {
                    HStack(spacing: 2) {
                        Image(systemName: "target")
                            .font(.caption2)
                        Text(SessionManager.shared.formatTime(targetDuration))
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionHistoryView()
}