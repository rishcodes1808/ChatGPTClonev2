//
//  LineWaveView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct LineWaveView: View {
    /// Current audio level (0...1).
    var amplitude: CGFloat
    /// Frequency of the sine wave (number of cycles across the width).
    var frequency: CGFloat = 1.5
    /// Total number of waves (primary + secondary).
    var numberOfWaves: Int = 5
    /// Minimum amplitude when the audio level is near zero.
    var idleAmplitude: CGFloat = 0.01
    /// Sampling density across the width.
    var density: CGFloat = 5.0
    /// Line width for the primary (most prominent) wave.
    var primaryWaveLineWidth: CGFloat = 3.0
    /// Line width for all secondary waves.
    var secondaryWaveLineWidth: CGFloat = 1.0
    /// How much the phase shifts on each update. Negative values shift the wave to the left.
    var phaseShift: CGFloat = -0.15
    var waveColor: Color = .black
    /// A multiplier to make the wave more reactive. Increase to boost the height difference.
    var sensitivity: CGFloat = 1.0

    @State private var phase: CGFloat = 0.0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midY = height / 2
            let midX = width / 2

            ZStack {
                ForEach(0..<numberOfWaves, id: \.self) { i in
                    let progress = 1.0 - CGFloat(i) / CGFloat(numberOfWaves)
                    let effectiveAmplitude = max(amplitude, idleAmplitude)
                    let normedAmplitude = (1.5 * progress - (2.0 / CGFloat(numberOfWaves))) * effectiveAmplitude * sensitivity
                    let lineWidth = (i == 0 ? primaryWaveLineWidth : secondaryWaveLineWidth)
                    let maxAmplitude = midY - (lineWidth * 2)
                    let multiplier = min(1.0, (progress * (2.0/3.0)) + (1.0/3.0))
                    
                    Path { path in
                        var firstPoint = true
                        for x in stride(from: 0, through: width, by: density) {
                            let scaling = -pow((x - midX) / midX, 2) + 1
                            let y = scaling * maxAmplitude * normedAmplitude * sin(2 * .pi * (x / width) * frequency + phase) + midY
                            if firstPoint {
                                path.move(to: CGPoint(x: x, y: y))
                                firstPoint = false
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(waveColor.opacity(Double(multiplier)), lineWidth: lineWidth)
                }
            }
            .drawingGroup()
        }
        .onReceive(Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.linear(duration: 0.02)) {
                phase += phaseShift
            }
        }
    }
}

struct LineWaveView_Previews: PreviewProvider {
    static var previews: some View {
        LineWaveView(amplitude: 0.5, sensitivity: 2.5)
            .frame(height: 100)
            .background(Color.black)
    }
}
