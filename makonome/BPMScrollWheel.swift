import SwiftUI

struct BPMScrollWheel: View {
    @Binding var bpm: Double
    
    @State private var scrollOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var velocity: CGFloat = 0
    @State private var decelerationTimer: Timer?
    @State private var isUpdatingFromScroll = false
    
    private let minBPM: Double = 40
    private let maxBPM: Double = 400
    private let bpmRange: Double = 360
    private let totalBars: Int = 72  // More bars for finer control
    private let barSpacing: CGFloat = 8  // Tighter spacing
    private let sensitivity: CGFloat = 0.3  // Reduce sensitivity
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 60)
                    .cornerRadius(12)
                
                // Center indicator
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 3, height: 40)
                    .position(x: geometry.size.width / 2, y: 30)
                
                // Bars
                HStack(spacing: barSpacing) {
                    ForEach(0..<totalBars, id: \.self) { index in
                        let barBPM = minBPM + (Double(index) * bpmRange / Double(totalBars - 1))
                        let isMajor = index % 12 == 0  // Every 12th bar for 72 total bars
                        let isMinor = index % 6 == 0   // Every 6th bar
                        
                        Rectangle()
                            .fill(barColor(for: barBPM, isMajor: isMajor, isMinor: isMinor))
                            .frame(
                                width: 2,
                                height: isMajor ? 35 : (isMinor ? 25 : 15)
                            )
                    }
                }
                .offset(x: scrollOffset)
                .clipped()
                
                // BPM display
                VStack {
                    Spacer()
                    Text("\(Int(bpm))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(height: 60)
        .onAppear {
            updateScrollFromBPM()
        }
        .onChange(of: bpm) { _, _ in
            if !isUpdatingFromScroll {
                updateScrollFromBPM()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    stopDeceleration()
                    scrollOffset = dragStartOffset + (value.translation.width * sensitivity)
                    updateBPMFromScroll()
                }
                .onEnded { value in
                    dragStartOffset = scrollOffset
                    
                    // Calculate velocity for inertia
                    let velocityX = value.velocity.width
                    velocity = velocityX * sensitivity * 0.0005 // Scale down for smoother deceleration
                    
                    // Single haptic feedback at end of gesture
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    startDeceleration()
                }
        )
    }
    
    private func updateScrollFromBPM() {
        let normalizedBPM = (bpm - minBPM) / bpmRange
        let targetOffset = -CGFloat(normalizedBPM) * CGFloat(totalBars - 1) * barSpacing
        
        withAnimation(.easeOut(duration: 0.3)) {
            scrollOffset = targetOffset
        }
        dragStartOffset = targetOffset
    }
    
    private func updateBPMFromScroll() {
        isUpdatingFromScroll = true
        
        let normalizedScroll = -scrollOffset / (CGFloat(totalBars - 1) * barSpacing)
        let newBPM = minBPM + (Double(normalizedScroll) * bpmRange)
        let clampedBPM = max(minBPM, min(maxBPM, newBPM))
        
        // Round to nearest integer for smoother user experience
        bpm = round(clampedBPM)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isUpdatingFromScroll = false
        }
    }
    
    private func startDeceleration() {
        guard abs(velocity) > 0.01 else { return }
        
        decelerationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            velocity *= 0.92 // Deceleration factor
            scrollOffset += velocity
            updateBPMFromScroll()
            
            if abs(velocity) < 0.005 {
                stopDeceleration()
            }
        }
    }
    
    private func stopDeceleration() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
        velocity = 0
        dragStartOffset = scrollOffset
    }
    
    private func barColor(for barBPM: Double, isMajor: Bool, isMinor: Bool) -> Color {
        let distance = abs(barBPM - bpm)
        let maxDistance: Double = 60
        let opacity = max(0.2, 1.0 - distance / maxDistance)
        
        if isMajor {
            return Color.blue.opacity(opacity * 0.9)
        } else if isMinor {
            return Color.gray.opacity(opacity * 0.8)
        } else {
            return Color.gray.opacity(opacity * 0.5)
        }
    }
}

#Preview {
    @State var bpm: Double = 120
    return VStack {
        Text("BPM: \(Int(bpm))")
            .font(.title2)
        BPMScrollWheel(bpm: $bpm)
            .padding()
        Slider(value: $bpm, in: 40...400, step: 1)
            .padding()
    }
}