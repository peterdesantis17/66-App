import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let thickness: CGFloat = 12
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: thickness)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(
                        lineWidth: thickness,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            // Percentage text
            VStack {
                Text("\(Int(progress * 100))%")
                    .font(.title)
                    .bold()
            }
        }
        .frame(width: 150, height: 150)
    }
} 