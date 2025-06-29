//
//  PracticeSessionView.swift
//  makonome
//
//  Created by Miro on 29.06.2025..
//

import SwiftUI

struct PracticeSessionView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var timer: Timer?
    @State private var sessionName = "Practice Session"
    @State private var targetDuration: TimeInterval = 1800 // 30 minutes default
    @State private var hasTargetDuration = false
    @State private var showingSessionSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let currentSession = sessionManager.currentSession {
                    // Active session view
                    VStack(spacing: 20) {
                        Text(currentSession.sessionName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(sessionManager.formatTime(currentSession.duration))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        
                        if let targetDuration = currentSession.targetDuration {
                            VStack(spacing: 8) {
                                ProgressView(value: min(currentSession.duration, targetDuration), total: targetDuration)
                                    .progressViewStyle(LinearProgressViewStyle(tint: currentSession.isGoalMet ? .green : .blue))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                                
                                HStack {
                                    Text("Goal: \(sessionManager.formatTime(targetDuration))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if currentSession.isGoalMet {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Goal Met!")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    } else {
                                        Text("\(sessionManager.formatTime(targetDuration - currentSession.duration)) remaining")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Button("Complete Session") {
                        completeSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                    
                } else {
                    // No active session view
                    VStack(spacing: 20) {
                        Image(systemName: "timer")
                            .imageScale(.large)
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)
                        
                        Text("Ready to Practice?")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Start a new practice session to track your progress")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button("Start Practice Session") {
                        showingSessionSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                }
                
                // Quick stats
                if !sessionManager.sessions.isEmpty {
                    VStack(spacing: 12) {
                        Divider()
                        
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(sessionManager.sessions.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Sessions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(sessionManager.formatTime(sessionManager.totalPracticeTime))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                Text("Total Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(sessionManager.formatTime(sessionManager.practiceTimeThisWeek))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                Text("This Week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .navigationTitle("Practice")
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SessionHistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingSessionSetup) {
                SessionSetupView(
                    sessionName: $sessionName,
                    targetDuration: $targetDuration,
                    hasTargetDuration: $hasTargetDuration,
                    onStart: { shouldStartMetronome in
                        startNewSession(shouldStartMetronome: shouldStartMetronome)
                    }
                )
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func startNewSession(shouldStartMetronome: Bool) {
        let target = hasTargetDuration ? targetDuration : nil
        sessionManager.startSession(name: sessionName, targetDuration: target, shouldStartMetronome: shouldStartMetronome)
        showingSessionSetup = false
    }
    
    private func completeSession() {
        sessionManager.completeCurrentSession()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // This will trigger UI updates for the duration display
            if sessionManager.currentSession != nil {
                sessionManager.objectWillChange.send()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct SessionSetupView: View {
    @Binding var sessionName: String
    @Binding var targetDuration: TimeInterval
    @Binding var hasTargetDuration: Bool
    let onStart: (Bool) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var shouldStartMetronome = UserDefaults.standard.bool(forKey: "AutoStartMetronomeWithPractice")
    
    var body: some View {
        NavigationView {
            Form {
                Section("Session Details") {
                    TextField("Session Name", text: $sessionName)
                }
                
                Section("Practice Goal") {
                    Toggle("Set time goal", isOn: $hasTargetDuration)
                    
                    if hasTargetDuration {
                        HStack {
                            Text("Target Duration")
                            Spacer()
                            Text(formatMinutes(targetDuration))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $targetDuration, in: 60...3600, step: 60) // 1 min to 1 hour
                            .onChange(of: targetDuration) { _, _ in
                                // Round to nearest minute
                                targetDuration = round(targetDuration / 60) * 60
                            }
                    }
                }
                
                Section("Metronome") {
                    Toggle(isOn: $shouldStartMetronome) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start metronome")
                            Text("Begin metronome with this practice session")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        onStart(shouldStartMetronome)
                    }
                    .disabled(sessionName.isEmpty)
                }
            }
        }
    }
    
    private func formatMinutes(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    PracticeSessionView()
}