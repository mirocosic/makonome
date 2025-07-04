import SwiftUI

struct TempoDetectionView: View {
    @StateObject private var permissionManager = MicrophonePermissionManager()
    @StateObject private var detectionEngine = TempoDetectionEngine()
    @State private var showingPermissionAlert = false
    @State private var isRequestingPermission = false
    
    // Callback to update parent view's BPM
    let onBPMDetected: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Detection Status
            VStack(spacing: 8) {
                Text("Tempo Detection")
                    .font(.headline)
                
                if detectionEngine.isDetecting {
                    Text("Listening...")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                } else {
                    Text("Tap to start detection")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            
            // Audio Level Indicator and Gain Control
            if detectionEngine.isDetecting {
                VStack(spacing: 8) {
                    HStack {
                        Text("Audio Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Gain: \(String(format: "%.1f", detectionEngine.inputGain))x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(detectionEngine.audioLevel), total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: audioLevelColor))
                        .frame(height: 8)
                        .scaleEffect(x: 1, y: 1.5)
                    
                    // Input Gain Slider
                    HStack {
                        Image(systemName: "minus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $detectionEngine.inputGain, in: 1.0...10.0, step: 0.5)
                            .frame(height: 20)
                        
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Auto") {
                            detectionEngine.adjustGainAutomatically()
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    }
                    
                    // Noise reduction controls
                    VStack(spacing: 4) {
                        HStack {
                            Text("Noise Gate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Calibrate") {
                                detectionEngine.calibrateNoiseFloor()
                            }
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                        }
                        
                        Slider(value: $detectionEngine.noiseGateThreshold, in: 0.01...0.1, step: 0.005)
                            .frame(height: 16)
                    }
                }
                .animation(.easeInOut(duration: 0.1), value: detectionEngine.audioLevel)
            }
            
            // Detected BPM Display
            if detectionEngine.isDetecting {
                VStack(spacing: 4) {
                    Text("\(Int(detectionEngine.currentBPM)) BPM")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                    
                    // Confidence indicator
                    HStack(spacing: 4) {
                        Text("Confidence:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(confidenceColor(for: index))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: detectionEngine.currentBPM)
            }
            
            // Main Detection Button
            Button(action: {
                handleDetectionToggle()
            }) {
                HStack {
                    Image(systemName: detectionEngine.isDetecting ? "mic.fill" : "mic")
                        .font(.title2)
                    Text(detectionEngine.isDetecting ? "Stop Detection" : "Start Detection")
                        .font(.headline)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(detectionEngine.isDetecting ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(detectionEngine.isDetecting ? .red : .blue)
                .cornerRadius(12)
            }
            .disabled(isRequestingPermission)
            
            // Apply BPM Button (only show when detecting and has good confidence)
            if detectionEngine.isDetecting && detectionEngine.confidenceScore > 0.5 {
                Button(action: {
                    onBPMDetected(detectionEngine.currentBPM)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Apply \(Int(detectionEngine.currentBPM)) BPM")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
        .onAppear {
            permissionManager.updatePermissionStatus()
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Makonome needs microphone access to detect tempo from audio input. Please enable microphone access in Settings.")
        }
    }
    
    private var audioLevelColor: Color {
        let level = detectionEngine.audioLevel
        if level < 0.3 {
            return .green
        } else if level < 0.7 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func confidenceColor(for index: Int) -> Color {
        let confidence = detectionEngine.confidenceScore
        let threshold = Double(index + 1) * 0.2
        
        if confidence >= threshold {
            return .green
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func handleDetectionToggle() {
        if detectionEngine.isDetecting {
            detectionEngine.stopDetection()
        } else {
            startDetection()
        }
    }
    
    private func startDetection() {
        guard permissionManager.isPermissionGranted else {
            if permissionManager.isPermissionUndetermined {
                requestPermission()
            } else {
                showingPermissionAlert = true
            }
            return
        }
        
        Task {
            do {
                try await detectionEngine.startDetection()
            } catch {
                print("Failed to start tempo detection: \(error)")
            }
        }
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            let granted = await permissionManager.requestPermission()
            
            await MainActor.run {
                isRequestingPermission = false
                
                if granted {
                    startDetection()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    TempoDetectionView { bpm in
        print("Detected BPM: \(bpm)")
    }
    .padding()
}