import SwiftUI

struct SimpleBPMScrollWheel: View {
    @State private var calculatedBPM: Int = 120
    
    private let minBPM = 40
    private let maxBPM = 400
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 4
    private let totalBarWidth: CGFloat = 7 // barWidth + barSpacing
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: barSpacing) {
                    ForEach(minBPM...maxBPM, id: \.self) { bpm in
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: barWidth, height: barHeight(for: bpm))
                    }
                }
                .padding(.horizontal, 200) // Add padding so we can scroll to center any value
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                // Initial BPM calculation
                                updateBPMFromGeometry(geometry)
                            }
                            .onChange(of: geometry.frame(in: .global)) { _, _ in
                                updateBPMFromGeometry(geometry)
                            }
                    }
                )
            }
            .frame(height: 60)
            .overlay(
                // Center indicator line
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: 60)
                    .opacity(0.8),
                alignment: .center
            )
            
            // Display calculated BPM
            Text("\(calculatedBPM) BPM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func barHeight(for bpm: Int) -> CGFloat {
        // Make every 10th BPM taller, every 50th even taller
        if bpm % 50 == 0 {
            return 50  // Major marks (50, 100, 150, etc.)
        } else if bpm % 10 == 0 {
            return 35  // Minor marks (every 10)
        } else {
            return 20  // Regular marks
        }
    }
    
    private func updateBPMFromGeometry(_ geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        let scrollOffset = frame.minX
        
        // Calculate BPM based on scroll position
        // We need to account for the padding and find which bar is at center
        let contentOffset = -scrollOffset + 200 // Account for left padding
        let barIndex = Int((contentOffset / totalBarWidth).rounded())
        let clampedIndex = max(0, min(maxBPM - minBPM, barIndex))
        let newBPM = minBPM + clampedIndex
        
        if newBPM != calculatedBPM {
            calculatedBPM = newBPM
        }
    }
}

#Preview {
    SimpleBPMScrollWheel()
}
