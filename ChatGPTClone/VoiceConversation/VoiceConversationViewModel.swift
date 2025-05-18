//
//  VoiceConversationViewModel.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import AVFoundation
import Foundation
import Observation

class VoiceConversationViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    let client = OpenAIAPI(apiKey: PlistHelper.infoForKey(.openAIKey))
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var recordingSession = AVAudioSession.sharedInstance()

    @Published var animationTimer: Timer?
    @Published var recordingTimer: Timer?
    @Published var audioPower = 0.0
    @Published var processingSpeechTask: Task<Void, Never>?
    @Published var prevPowerDbForSilence: Float? = nil
    @Published var userHasSpoken: Bool = false
    @Published var userDeniedMicrophonePermission = false
    
    private let thresholdDB: Float = -30.0 // Threshold to detect speech vs. silence
    
    private let repository = ConversationCoreDataRepository.shared
    @Published private(set) var conversationID: UUID?
    
    @Preference(\.selectedVoice) var selectedVoice
    @Published var state = VoiceChatState.idle {
        didSet { print("Voice State", state) }
    }
    
    var captureURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("recording.m4a")
    }
    
    var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }
    
    
    override init() {
        super.init()
    }
    
    func startNewConversation() {
        let newID = UUID()
        conversationID = newID
    }
    
    func onAppear() {
        do {
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            
            try recordingSession.setActive(true)
            
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !allowed {
                        self.state = .error("Recording not allowed by the user")
                        self.userDeniedMicrophonePermission = true
                    } else {
                        if self.state == .idle {
                            self.startCaptureAudio()
                        }
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.state = .error(error.localizedDescription)
            }
        }
    }
        
    private func normalizeAudioPowerForVisualization(_ decibels: Float) -> Double {
        let sensitivityFactor: Double = 50.0
        return min(1.0, max(0.0, 1.0 - abs(Double(decibels) / sensitivityFactor)))
    }

    private func normalizeAudioPowerForPlayerVisualization(_ decibels: Float) -> Double {
        let minDb: Float = -120.0
        let maxDb: Float = 0.0
        if decibels < minDb { return 0.0 }
        if decibels > maxDb { return 1.0 }
        let normalized = (decibels - minDb) / (maxDb - minDb)
        return Double(normalized)
    }
    
    func startCaptureAudio() {
        guard state == .idle || state.isError || state == .playingSpeech || state == .recordingSpeech else {
            return
        }
        resetValues()
        prevPowerDbForSilence = nil
        state = .recordingSpeech
        do {
            audioRecorder = try AVAudioRecorder(url: captureURL,
                                                settings: [
                                                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                                    AVSampleRateKey: 12000,
                                                    AVNumberOfChannelsKey: 1,
                                                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                                                ])
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
                recorder.updateMeters()
                let averagePower = recorder.averagePower(forChannel: 0)
                if !self.userHasSpoken && averagePower > self.thresholdDB {
                    self.userHasSpoken = true
                    print("User speech detected via animationTimer (dB: \(averagePower)).")
                }
                
                let normalizedPower = self.normalizeAudioPowerForVisualization(recorder.averagePower(forChannel: 0))
                self.audioPower = normalizedPower
            }
            
            let silenceDetectionInterval: TimeInterval = 0.7
            let quietThresholdDb: Float = -33.0
            let veryQuietThresholdDb: Float = -33.0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: silenceDetectionInterval, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
                
                recorder.updateMeters()
                let currentPowerDb = recorder.averagePower(forChannel: 0)
                print("Silence Detection - Current dB: \(currentPowerDb), Prev dB for Silence: \(String(describing: self.prevPowerDbForSilence))")
                
                if !self.userHasSpoken {
                    self.prevPowerDbForSilence = nil
                    return
                }
                
                if self.prevPowerDbForSilence == nil {
                    self.prevPowerDbForSilence = currentPowerDb
                    return
                }
                
                if let previousDb = self.prevPowerDbForSilence,
                   previousDb < quietThresholdDb && currentPowerDb < veryQuietThresholdDb {
                    print("Silence detected (dB). Prev dB: \(previousDb), Current dB: \(currentPowerDb). Thresholds: quiet < \(quietThresholdDb), veryQuiet < \(veryQuietThresholdDb). Finishing capture.")
                    self.finishCaptureAudio()
                } else {
                    self.prevPowerDbForSilence = currentPowerDb
                }
            }
            
        } catch {
            resetValues()
            state = .error(error.localizedDescription)
        }
    }
        
    
    func finishCaptureAudio() {
        guard state == .recordingSpeech else { return }
        resetValues()
        do {
            guard FileManager.default.fileExists(atPath: captureURL.path) else {
                state = .error("Audio file not found.")
                self.startCaptureAudio()
                return
            }
            let audioFileAttributes = try FileManager.default.attributesOfItem(atPath: captureURL.path)
            if let fileSize = audioFileAttributes[FileAttributeKey.size] as? NSNumber, fileSize.int64Value == 0 {
                state = .error("No audio was recorded.")
                self.startCaptureAudio()
                return
            }
            let data = try Data(contentsOf: captureURL)
            processingSpeechTask = processSpeechTask(audioData: data)
        } catch {
            state = .error(error.localizedDescription)
            self.startCaptureAudio()
        }
    }
    
    func processSpeechTask(audioData: Data) -> Task<Void, Never> {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.state = .processingSpeech
            do {
                let prompt = try await client.generateAudioTransciptions(audioData: audioData)
                try Task.checkCancellation()

                if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.state = .error("Couldn't understand audio.")
                    self.startCaptureAudio()
                    return
                }
                
                if let cid = self.conversationID {
                    try self.repository.addMessage(
                        conversationID: cid,
                        messageID: UUID(),
                        text: prompt,
                        isUser: true,
                        isVoice: true,
                    )
                }
                
                let responseText = try await client.sendMessage(prompt)
                try Task.checkCancellation()
                
                if let cid = self.conversationID {
                    try self.repository.addMessage(
                        conversationID: cid,
                        messageID: UUID(),
                        text: responseText,
                        isUser: false,
                        isVoice: true,
                    )
                }

                if responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.state = .error("AI did not provide a response.")
                    self.startCaptureAudio()
                    return
                }
                
                let speechData = try await client.generateSpeechFrom(input: responseText, voice:
                    .init(rawValue: self.selectedVoice.rawValue) ?? .alloy)
                try Task.checkCancellation()
                
                try self.playAudio(data: speechData)
            } catch {
                if Task.isCancelled {
                    if self.state != .idle { self.state = .idle }
                } else {
                    self.state = .error(error.localizedDescription)
                    self.startCaptureAudio()
                }
            }
        }
    }
    
    func playAudio(data: Data) throws {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
        audioPlayer = nil
        
        self.state = .playingSpeech
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer!.isMeteringEnabled = true
        audioPlayer!.delegate = self
        
        if audioPlayer!.play() {
            animationTimer?.invalidate()
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer, player.isPlaying else {
                    return
                }
                player.updateMeters()
                let normalizedPower = self.normalizeAudioPowerForPlayerVisualization(player.averagePower(forChannel: 0))
                self.audioPower = normalizedPower
            }
        } else {
            self.state = .error("Failed to play audio response.")
            self.startCaptureAudio()
        }
    }
    
    func cancelRecording() {
        resetValues()
        state = .idle
    }
    
    func cancelProcessingTask() {
        processingSpeechTask?.cancel()
        processingSpeechTask = nil
        resetValues()
        state = .recordingSpeech
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            if self.state == .recordingSpeech {
                if !flag {
                    self.state = .error("Audio recording failed.")
                    self.resetValues()
                    self.startCaptureAudio()
                }
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.state = .error("Audio recording failed (encode error).")
            self.resetValues()
            self.startCaptureAudio()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.animationTimer?.invalidate()
            self.animationTimer = nil
            self.audioPower = 0.0

            if flag {
                self.startCaptureAudio()
            } else {
                self.resetValues()
                self.state = .error("AI audio playback failed.")
                self.startCaptureAudio()
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.animationTimer?.invalidate()
            self.animationTimer = nil
            self.state = .error("Failed to play audio (decode error).")
            self.resetValues()
            self.startCaptureAudio()
        }
    }

    func resetValues() {
        audioPower = 0.0
        prevPowerDbForSilence = nil
        userHasSpoken = false
        
        if audioRecorder?.isRecording == true {
            audioRecorder?.stop()
        }
        audioRecorder = nil
        
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
        audioPlayer = nil
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
