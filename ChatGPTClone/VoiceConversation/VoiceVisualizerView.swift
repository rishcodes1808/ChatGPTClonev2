//
//  VoiceVisualizerView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct VoiceVisualizerView: View {
    @ObservedObject var viewModel: VoiceConversationViewModel
    
    private let lineCount = 4
    private let colors: [Color] = [.blue, .purple, .green, .orange]
    
    // ——— Randomized per-loop state ———
    @State private var rotationAngles: [Double] = (0..<4).map { _ in Double.random(in: 0..<360) }
    @State private var pulsePhases: [Double] = (0..<4).map { _ in
        Double.random(in: 0..<Double.pi * 2)
    }
    
    @State private var orbitSpeeds:     [Double] = (0..<4).map { _ in Double.random(in: 10...20) }
    @State private var tiltAngles:      [Angle]  = (0..<4).map { _ in .degrees(Double.random(in: 0..<360)) }
    @State private var ellipseScales:   [CGSize] = (0..<4).map { _ in
        CGSize(width: CGFloat.random(in: 0.7...1.0),
               height: CGFloat.random(in: 0.5...1.0))
    }
    @State private var baseRadii:       [CGFloat] = (0..<4).map { _ in CGFloat.random(in: 40...80) }
    
    @State private var smoothedAudioPower: CGFloat = 0
    
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch viewModel.state {
                case .recordingSpeech:
                    ForEach(0..<lineCount, id: \.self) { i in
                        Circle()
                            .stroke(
                                colors[i].opacity(Double(0.3 + 0.7 * smoothedAudioPower)),
                                lineWidth: 1.5 + smoothedAudioPower * 3.0
                            )
                        // fixed base size
                            .frame(
                                width: baseRadii[i] * 2 * ellipseScales[i].width,
                                height: baseRadii[i] * 2 * ellipseScales[i].height
                            )
                        // combine static tilt + dynamic rotation
                            .rotationEffect(
                                tiltAngles[i] +
                                    .degrees(rotationAngles[i])
                            )
                        // pulsing scale on top
                            .scaleEffect(
                                1 + smoothedAudioPower * 0.25 * CGFloat(sin(pulsePhases[i]))
                            )
                        // center it
                            .position(x: geo.size.width/2,
                                      y: geo.size.height/2)
                    }
                    
                    // drive spin & pulse
                    .onReceive(timer) { _ in
                        let audio = smoothedAudioPower
                        // idle = slow (0.1×), max = fast (2.5×)
                        let speedMult = 0.1 + Double(audio) * 2.4
                        withAnimation(.linear(duration: 0.02)) {
                            for i in 0..<lineCount {
                                // advance rotation
                                rotationAngles[i] += orbitSpeeds[i] * speedMult * 0.02
                                // advance pulse phase
                                pulsePhases[i]   += 0.15 + Double(audio) * 0.15
                            }
                        }
                    }
                    // smooth audioPower changes
                    .onAppear {
                        smoothedAudioPower = viewModel.audioPower
                    }
                    .onChange(of: viewModel.audioPower) { _, new in
                        withAnimation(.linear(duration: 0.1)) {
                            smoothedAudioPower = new
                        }
                    }
                    
                    
                    
                case .processingSpeech:
                    LineWaveView(
                        amplitude: 0.1,
                        frequency: 1.3,
                        numberOfWaves: 4,
                        idleAmplitude: 0.05,
                        phaseShift: -0.1, waveColor: Color.blue.opacity(0.75),
                        sensitivity: 1.0
                    )
                    
                case .playingSpeech:
                    LineWaveView(
                        amplitude: CGFloat(viewModel.audioPower) / 3,
                        frequency: 1.5,
                        numberOfWaves: 5,
                        idleAmplitude: 0.02,
                        phaseShift: -0.2, waveColor: Color.green.opacity(0.9),
                        sensitivity: 1.8
                    )
                    
                case .idle:
                    LineWaveView(
                        amplitude: 0.02,
                        frequency: 1.0,
                        numberOfWaves: 3,
                        idleAmplitude: 0.02,
                        phaseShift: -0.05, waveColor: Color.gray.opacity(0.5),
                        sensitivity: 0.5
                    )
                    
                case .error:
                    LineWaveView(
                        amplitude: 0.01,
                        frequency: 0.5,
                        numberOfWaves: 1,
                        idleAmplitude: 0.01,
                        phaseShift: 0.0, waveColor: Color.red.opacity(0.6),
                        sensitivity: 0.1
                    )
                }
            }
        }
    }
}

// Previews
struct VoiceVisualizerView_Previews: PreviewProvider {
    
    class MockVoiceConversationViewModel: VoiceConversationViewModel {
        
    }
    
    static var previews: some View {
        let recordingVM = MockVoiceConversationViewModel()
        recordingVM.state = .recordingSpeech
        recordingVM.audioPower = 0.6
        
        let idleRecordingVM = MockVoiceConversationViewModel()
        idleRecordingVM.state = .recordingSpeech
        idleRecordingVM.audioPower = 0.05
        
        let processingVM = MockVoiceConversationViewModel()
        processingVM.state = .processingSpeech
        
        let playingVM = MockVoiceConversationViewModel()
        playingVM.state = .playingSpeech
        playingVM.audioPower = 0.7
        
        let errorVM = MockVoiceConversationViewModel()
        let (sampleErrorString) = ("Preview Error")
        errorVM.state = .error(sampleErrorString)
        
        let idleStateVM = MockVoiceConversationViewModel()
        idleStateVM.state = .idle
        
        let containerHeight: CGFloat = 150
        let backgroundColor = Color.black.opacity(0.05)
        
        return ScrollView {
            VStack(spacing: 20) {
                Text("User Talking (Loud)")
                VoiceVisualizerView(viewModel: recordingVM)
                    .frame(height: containerHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text("User Talking (Soft)")
                VoiceVisualizerView(viewModel: idleRecordingVM)
                    .frame(height: containerHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text("AI Processing")
                VoiceVisualizerView(viewModel: processingVM)
                    .frame(height: containerHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text("AI Talking")
                VoiceVisualizerView(viewModel: playingVM)
                    .frame(height: containerHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text("Error State")
                VoiceVisualizerView(viewModel: errorVM)
                    .frame(height: containerHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text("Idle State")
                VoiceVisualizerView(viewModel: idleStateVM)
                    .frame(height: containerHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
    }
}
