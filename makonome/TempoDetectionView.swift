import SwiftUI

struct TempoDetectionView: View {
    @StateObject private var permissionManager = MicrophonePermissionManager()
    @StateObject private var detectionEngine = TempoDetectionEngine()
    @State private var showingPermissionAlert = false
    @State private var isRequestingPermission = false
    
    // Callback to update parent view's BPM
    let onBPMDetected: (Double) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Tempo Detection")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Text(detectionEngine.isDetecting ? "Listening for tempo..." : "Detect tempo from audio input")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            
                // Current BPM Display (always visible, more prominent when detecting)
                VStack(spacing: 8) {
                    Text("\(Int(detectionEngine.currentBPM)) BPM")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(detectionEngine.isDetecting ? .primary : .secondary)
                    
                    // Confidence indicator
                    HStack(spacing: 8) {
                        Text("Confidence:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Circle()
                                    .fill(confidenceColor(for: index))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .animation(.easeInOut(duration: 0.2), value: detectionEngine.currentBPM)
                
                // Audio Controls Section (always visible)
                VStack(spacing: 16) {
                        // Audio Level Monitor
                        VStack(spacing: 8) {
                            HStack {
                                Text("Audio Level")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Gain: \(String(format: "%.1f", detectionEngine.inputGain))x")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: Double(detectionEngine.audioLevel), total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: audioLevelColor))
                                .frame(height: 12)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Gain Control
                        VStack(spacing: 12) {
                            HStack {
                                Text("Input Gain")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Auto") {
                                    detectionEngine.adjustGainAutomatically()
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            HStack {
                                Text("1x")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $detectionEngine.inputGain, in: 1.0...10.0, step: 0.5)
                                
                                Text("10x")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Noise Gate Control
                        VStack(spacing: 12) {
                            HStack {
                                Text("Noise Gate")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Calibrate") {
                                    detectionEngine.calibrateNoiseFloor()
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                            }
                            
                            HStack {
                                Text("Low")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $detectionEngine.noiseGateThreshold, in: 0.01...0.1, step: 0.005)
                                
                                Text("High")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)
                }
                .animation(.easeInOut(duration: 0.1), value: detectionEngine.audioLevel)
            
                // Main Action Buttons
                VStack(spacing: 12) {
                    // Primary Detection Button
                    Button(action: {
                        handleDetectionToggle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: detectionEngine.isDetecting ? "stop.fill" : "mic.fill")
                                .font(.title2)
                            Text(detectionEngine.isDetecting ? "Stop Detection" : "Start Detection")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(detectionEngine.isDetecting ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(isRequestingPermission)
                    
                    // Apply BPM Button (show when has good confidence, regardless of detection state)
                    if detectionEngine.confidenceScore > 0.3 {
                        Button(action: {
                            onBPMDetected(detectionEngine.currentBPM)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Apply \(Int(detectionEngine.currentBPM)) BPM")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
            }
        }
        .padding(20)
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