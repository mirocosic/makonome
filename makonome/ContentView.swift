//
//  ContentView.swift
//  makonome
//
//  Created by Miro on 23.06.2025..
//

import SwiftUI

struct ContentView: View {
    @State private var isStarted = false
    @State private var startTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var loggedTimes: [TimeInterval] = []
    
    var body: some View {
        VStack {
            Image(systemName: "stopwatch")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Stopwatch")
            
            Text(formatTime(elapsedTime))
                .font(.largeTitle)
                .monospacedDigit()
            
            Button(isStarted ? "Stop" : "Start") {
                toggleTimer()
            }
            .buttonStyle(.borderedProminent)
            
            if !loggedTimes.isEmpty {
                VStack(alignment: .leading) {
                    Text("Previous Times")
                        .font(.headline)
                        .padding(.top)
                    
                    List {
                        ForEach(Array(loggedTimes.enumerated().reversed()), id: \.offset) { index, time in
                            HStack {
                                Text("#\(loggedTimes.count - index)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatTime(time))
                                    .monospacedDigit()
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding()
    }
    
    private func toggleTimer() {
        if isStarted {
            // Stop timer and log the elapsed time
            timer?.invalidate()
            timer = nil
            if elapsedTime > 0 {
                loggedTimes.append(elapsedTime)
            }
            elapsedTime = 0
        } else {
            // Start timer
            startTime = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        isStarted.toggle()
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

#Preview {
    ContentView()
}
