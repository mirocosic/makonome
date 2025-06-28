import SwiftUI

struct SimpleBPMScrollWheel: View {
    @Binding var bpm: Double
    @State private var isUpdatingFromScroll = false
    @State private var scrollOffset: CGFloat = 0
    
    private let minBPM = 40
    private let maxBPM = 400
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 4
    private let totalBarWidth: CGFloat = 7 // barWidth + barSpacing
    
    var body: some View {
        GeometryReader { geometry in
            let halfWidth = geometry.size.width / 2
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: barSpacing) {
                    // Add leading spacer to center the first value
                    Spacer()
                        .frame(width: halfWidth)
                    
                    ForEach(minBPM...maxBPM, id: \.self) { bpmValue in
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: barWidth, height: barHeight(for: bpmValue))
                    }
                    
                    // Add trailing spacer to center the last value
                    Spacer()
                        .frame(width: halfWidth)
                }
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .onChange(of: scrollGeometry.frame(in: .global)) { _, _ in
                                updateBPMFromGeometry(scrollGeometry, containerWidth: geometry.size.width)
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
            .onAppear {
                scrollToBPM(Int(bpm))
            }
            .onChange(of: bpm) { _, newBPM in
                if !isUpdatingFromScroll {
                    scrollToBPM(Int(newBPM))
                }
            }
        }
        .frame(height: 60)
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

    private func updateBPMFromGeometry(_ geometry: GeometryProxy, containerWidth: CGFloat) {
        let frame = geometry.frame(in: .global)
        let scrollOffset = frame.minX
        let halfWidth = containerWidth / 2
        
        // Calculate BPM based on scroll position
        // When scrolled fully left, we want BPM = minBPM (40)
        // When scrolled fully right, we want BPM = maxBPM (400)
        let contentOffset = halfWidth - scrollOffset
        let barIndex = Int((contentOffset / totalBarWidth).rounded())
        let clampedIndex = max(0, min(maxBPM - minBPM, barIndex))
        let newBPM = Double(minBPM + clampedIndex)
        
        if newBPM != bpm {
            isUpdatingFromScroll = true
            bpm = newBPM
            UserDefaults.standard.set(bpm, forKey: "MetronomeBPM")
            
            // Reset flag after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isUpdatingFromScroll = false
            }
        }
    }
    
    private func scrollToBPM(_ targetBPM: Int) {
        // Since we can't programmatically scroll without ScrollViewReader,
        // we'll rely on the scroll view's natural behavior and user interaction
        // The scroll position will be automatically updated when the user scrolls
    }
}

#Preview {
    @Previewable @State var bpm: Double = 120
    SimpleBPMScrollWheel(bpm: $bpm)
}
