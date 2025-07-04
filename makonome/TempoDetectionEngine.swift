import AVFoundation
import Foundation
import Accelerate

class TempoDetectionEngine: ObservableObject {
    @Published var isDetecting: Bool = false
    @Published var currentBPM: Double = 120.0
    @Published var confidenceScore: Double = 0.0
    @Published var audioLevel: Float = 0.0
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let bufferSize: AVAudioFrameCount = 1024
    private var sampleRate: Double = 44100.0
    
    // Beat detection parameters
    private let minBPM: Double = 40.0
    private let maxBPM: Double = 400.0
    private let detectionThreshold: Float = 0.15  // Lowered for better sensitivity
    private let smoothingFactor: Double = 0.6     // Less aggressive smoothing
    
    // Audio input gain and noise reduction
    @Published var inputGain: Float = 3.0  // 3x boost by default
    private let maxGain: Float = 10.0      // Maximum 10x boost
    
    // Noise reduction
    private var noiseFloor: Float = 0.0
    private var noiseFloorSamples: [Float] = []
    private let noiseFloorSize = 100
    @Published var noiseGateThreshold: Float = 0.02  // Gate threshold
    private var isCalibrating = false
    
    // High-pass filter for noise reduction (simple first-order)
    private var filterPrevInput: Float = 0.0
    private var filterPrevOutput: Float = 0.0
    private let highPassCutoff: Float = 80.0  // 80 Hz cutoff
    
    // Beat tracking
    private var beatTimestamps: [TimeInterval] = []
    private var lastBeatTime: TimeInterval = 0
    private var energyBuffer: [Float] = []
    private let energyBufferSize = 43 // ~1 second at 44.1kHz with 1024 buffer
    
    // Enhanced detection
    private var spectralFluxBuffer: [Float] = []
    
    init() {
        inputNode = audioEngine.inputNode
    }
    
    private func setupAudioEngine() {
        // Remove any existing taps
        inputNode.removeTap(onBus: 0)
        
        // Get the input node's hardware format
        let inputFormat = inputNode.inputFormat(forBus: 0)
        sampleRate = inputFormat.sampleRate
        
        // Install tap with the hardware format (no conversion)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
    }
    
    func startDetection() async throws {
        guard !isDetecting else { return }
        
        do {
            // Configure audio session for recording and playback
            MetronomeManager.shared.setupAudioSession(forRecording: true)
            
            // Set up the audio engine after the session is configured
            setupAudioEngine()
            
            try audioEngine.start()
            await MainActor.run {
                isDetecting = true
                resetDetectionState()
            }
        } catch {
            throw error
        }
    }
    
    func stopDetection() {
        guard isDetecting else { return }
        
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isDetecting = false
        resetDetectionState()
        
        // Restore audio session to playback-only mode
        MetronomeManager.shared.setupAudioSession(forRecording: false)
    }
    
    
    private func resetDetectionState() {
        beatTimestamps.removeAll()
        energyBuffer.removeAll()
        spectralFluxBuffer.removeAll()
        noiseFloorSamples.removeAll()
        lastBeatTime = 0
        confidenceScore = 0.0
        audioLevel = 0.0
        noiseFloor = 0.0
        isCalibrating = false
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        // Apply input gain boost to improve signal strength
        var boostedData = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        vDSP_vsmul(boostedData, 1, &inputGain, &boostedData, 1, UInt(frameCount))
        
        // Apply high-pass filter to remove low-frequency noise
        applyHighPassFilter(to: &boostedData)
        
        // Calculate RMS energy from boosted signal
        var rms: Float = 0.0
        vDSP_rmsqv(&boostedData, 1, &rms, UInt(frameCount))
        
        // Update noise floor estimation
        updateNoiseFloor(rms: rms)
        
        // Apply noise gate - only process if signal is above noise floor + threshold
        let gatedRMS = applyNoiseGate(rms: rms)
        
        DispatchQueue.main.async {
            self.audioLevel = gatedRMS
        }
        
        // Only process audio if it passes the noise gate
        guard gatedRMS > noiseGateThreshold else {
            return // Skip processing for noise
        }
        
        // Calculate simple spectral flux using boosted and gated signal
        let spectralFlux = calculateSpectralFlux(from: &boostedData, frameCount: frameCount)
        
        // Add to energy buffer (use gated RMS)
        energyBuffer.append(gatedRMS)
        if energyBuffer.count > energyBufferSize {
            energyBuffer.removeFirst()
        }
        
        // Add to spectral flux buffer
        spectralFluxBuffer.append(spectralFlux)
        if spectralFluxBuffer.count > energyBufferSize {
            spectralFluxBuffer.removeFirst()
        }
        
        // Detect beats using simple onset detection
        detectBeat(energy: gatedRMS, spectralFlux: spectralFlux)
        
        // Periodically adjust gain automatically
        if energyBuffer.count % 20 == 0 { // Every 20 buffers
            adjustGainAutomatically()
        }
    }
    
    private func calculateSpectralFlux(from channelData: inout [Float], frameCount: Int) -> Float {
        // Simple spectral flux: just return energy change
        let currentEnergy = channelData.prefix(frameCount).map { $0 * $0 }.reduce(0, +) / Float(frameCount)
        let flux = max(0, currentEnergy - (energyBuffer.last ?? 0))
        return flux
    }
    
    private func detectBeat(energy: Float, spectralFlux: Float) {
        guard energyBuffer.count >= energyBufferSize else { return }
        
        // Simple onset detection: energy spike above adaptive threshold
        let averageEnergy = energyBuffer.reduce(0, +) / Float(energyBuffer.count)
        let energyThreshold = averageEnergy * (1.0 + detectionThreshold)
        
        // Combine energy and flux for detection
        let combinedSignal = energy + spectralFlux * 0.5
        
        if combinedSignal > energyThreshold {
            let currentTime = CACurrentMediaTime()
            
            // Prevent double-triggering with adaptive minimum interval
            let minInterval: TimeInterval = beatTimestamps.count >= 2 ? 
                min(0.15, max(0.1, (beatTimestamps.last! - beatTimestamps[beatTimestamps.count - 2]) * 0.8)) : 0.15
            
            if currentTime - lastBeatTime > minInterval {
                lastBeatTime = currentTime
                beatTimestamps.append(currentTime)
                
                // Keep only recent timestamps (last 8 beats)
                if beatTimestamps.count > 8 {
                    beatTimestamps.removeFirst()
                }
                
                // Calculate tempo if we have enough beats
                if beatTimestamps.count >= 3 {
                    calculateTempo()
                }
            }
        }
    }
    
    private func calculateTempo() {
        guard beatTimestamps.count >= 3 else { return }
        
        // Calculate intervals between beats
        var intervals: [TimeInterval] = []
        for i in 1..<beatTimestamps.count {
            intervals.append(beatTimestamps[i] - beatTimestamps[i-1])
        }
        
        // Remove outliers (intervals outside reasonable range)
        let minInterval = 60.0 / maxBPM
        let maxInterval = 60.0 / minBPM
        intervals = intervals.filter { $0 >= minInterval && $0 <= maxInterval }
        
        guard !intervals.isEmpty else { return }
        
        // Calculate average interval
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let calculatedBPM = 60.0 / averageInterval
        
        // Calculate confidence based on consistency of intervals
        let variance = intervals.map { pow($0 - averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        let confidence = max(0.0, 1.0 - (stdDev / averageInterval))
        
        // Smooth the BPM update
        let smoothedBPM = (currentBPM * smoothingFactor) + (calculatedBPM * (1.0 - smoothingFactor))
        
        DispatchQueue.main.async {
            self.currentBPM = smoothedBPM
            self.confidenceScore = confidence
        }
    }
    
    func getBPMWithConfidence() -> (bpm: Double, confidence: Double) {
        return (currentBPM, confidenceScore)
    }
    
    func adjustGainAutomatically() {
        // Auto-adjust gain based on recent audio levels
        guard energyBuffer.count >= energyBufferSize else { return }
        
        let recentAverage = energyBuffer.suffix(energyBufferSize / 2).reduce(0, +) / Float(energyBufferSize / 2)
        let targetLevel: Float = 0.3 // Target RMS level
        
        if recentAverage < 0.1 && inputGain < maxGain {
            // Signal too quiet, increase gain
            let newGain = min(maxGain, inputGain * 1.5)
            DispatchQueue.main.async {
                self.inputGain = newGain
            }
        } else if recentAverage > 0.8 && inputGain > 1.0 {
            // Signal too loud, decrease gain
            let newGain = max(1.0, inputGain * 0.7)
            DispatchQueue.main.async {
                self.inputGain = newGain
            }
        }
    }
    
    private func updateNoiseFloor(rms: Float) {
        // Collect samples for noise floor estimation
        noiseFloorSamples.append(rms)
        if noiseFloorSamples.count > noiseFloorSize {
            noiseFloorSamples.removeFirst()
        }
        
        // Calculate noise floor as the 25th percentile of recent samples
        if noiseFloorSamples.count >= noiseFloorSize {
            let sorted = noiseFloorSamples.sorted()
            noiseFloor = sorted[sorted.count / 4] // 25th percentile
        }
    }
    
    private func applyNoiseGate(rms: Float) -> Float {
        // Apply noise gate: if signal is below noise floor + threshold, return 0
        let threshold = noiseFloor + noiseGateThreshold
        return rms > threshold ? rms - noiseFloor : 0.0
    }
    
    func calibrateNoiseFloor() {
        // Start noise floor calibration
        isCalibrating = true
        noiseFloorSamples.removeAll()
        noiseFloor = 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isCalibrating = false
        }
    }
    
    private func applyHighPassFilter(to data: inout [Float]) {
        // Simple first-order high-pass filter
        let dt = 1.0 / Float(sampleRate)
        let rc = 1.0 / (2.0 * Float.pi * highPassCutoff)
        let alpha = rc / (rc + dt)
        
        for i in 0..<data.count {
            let output = alpha * (filterPrevOutput + data[i] - filterPrevInput)
            filterPrevInput = data[i]
            filterPrevOutput = output
            data[i] = output
        }
    }
    
    deinit {
        if isDetecting {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
        }
    }
}