import SwiftUI

struct CircularPicker: View {
    @Binding var value: Double
    @State private var isDragging = false
    @State private var lastAngle: Double = 0
    @State private var isFirstDrag = true
    @State private var hapticCounter = 0
    
    private let minValue: Double = 40
    private let maxValue: Double = 400
    private let radius: CGFloat = 120
    private let lineWidth: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.softGray.opacity(0.3), lineWidth: lineWidth)
                    .frame(width: radius * 2, height: radius * 2)
                
                // Progress arc (hidden)
                // Circle()
                //     .trim(from: 0, to: progressValue)
                //     .stroke(
                //         Color.softBlue,
                //         style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                //     )
                //     .frame(width: radius * 2, height: radius * 2)
                //     .rotationEffect(.degrees(-90))
                
                // Tick marks
                ForEach(tickMarks, id: \.value) { tick in
                    TickMark(
                        angle: tick.angle,
                        height: tick.height,
                        radius: radius,
                        color: tick.color
                    )
                }
                .rotationEffect(.radians(currentAngle - .pi / 2))
                
                // Center value display
                VStack(spacing: 4) {
                    Text("\(Int(value))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Drag handle (hidden)
                // Circle()
                //     .fill(Color.softBlue)
                //     .frame(width: 24, height: 24)
                //     .offset(x: cos(currentAngle) * radius, y: sin(currentAngle) * radius)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(center)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        handleDrag(gesture: gesture, center: center)
                    }
                    .onEnded { _ in
                        isDragging = false
                        isFirstDrag = true  // Reset for next drag
                    }
            )
        }
        .frame(width: (radius + 40) * 2, height: (radius + 40) * 2)
        .onAppear {
            lastAngle = currentAngle
            isFirstDrag = true
        }
    }
    
    private var progressValue: CGFloat {
        CGFloat((value - minValue) / (maxValue - minValue))
    }
    
    private var currentAngle: Double {
        let progress = (value - minValue) / (maxValue - minValue)
        return progress * 2 * .pi - .pi / 2  // Start from top (12 o'clock)
    }
    
    private var tickMarks: [TickMarkData] {
        var marks: [TickMarkData] = []
        let valueRange = maxValue - minValue
        let step = 10.0
        
        for i in stride(from: minValue, through: maxValue, by: step) {
            let progress = (i - minValue) / valueRange
            let angle = progress * 2 * .pi - .pi / 2  // Start from top (12 o'clock)
            
            marks.append(TickMarkData(
                value: i,
                angle: angle,
                height: 12,
                color: .softGray
            ))
        }
        
        return marks
    }
    
    private func handleDrag(gesture: DragGesture.Value, center: CGPoint) {
        isDragging = true
        
        let vector = CGPoint(
            x: gesture.location.x - center.x,
            y: gesture.location.y - center.y
        )
        
        let angle = atan2(vector.y, vector.x) + .pi / 2  // Adjust for top starting position
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        
        if isFirstDrag {
            lastAngle = normalizedAngle
            isFirstDrag = false
            return  // Don't update value on first drag event
        }
        
        var angleDiff = normalizedAngle - lastAngle
        
        // Handle angle wrap-around
        if angleDiff > .pi {
            angleDiff -= 2 * .pi
        } else if angleDiff < -.pi {
            angleDiff += 2 * .pi
        }
        
        let sensitivity = 0.35
        let valueChange = angleDiff * sensitivity * (maxValue - minValue) / (2 * .pi)
        let newValue = max(minValue, min(maxValue, value + valueChange))
        
        if abs(newValue - value) > 0.1 {
            let oldIntegerValue = Int(value)
            let newIntegerValue = Int(newValue)
            
            value = newValue
            
            // Trigger haptic when crossing integer BPM boundaries
            if oldIntegerValue != newIntegerValue {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        
        lastAngle = normalizedAngle
    }
}

struct TickMarkData {
    let value: Double
    let angle: Double
    let height: CGFloat
    let color: Color
}

struct TickMark: View {
    let angle: Double
    let height: CGFloat
    let radius: CGFloat
    let color: Color
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 2, height: height)
            .offset(y: -radius + 10 - height/2)  // Move inside to align with inner edge of path
            .rotationEffect(.radians(angle))
    }
}

#Preview {
    @Previewable @State var value: Double = 120
    
    VStack {
        CircularPicker(value: $value)
        
        Text("Current value: \(Int(value))")
            .font(.headline)
            .padding()
    }
}