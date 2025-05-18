//
//  LLMClient.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

protocol LLMClient {
    
    var provider: LLMProvider { get }
    
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error>
    func sendMessage(_ text: String) async throws -> String
    func deleteHistoryList()
    
    func generateSpeechFrom(input: String, voice: VoiceType, model: String) async throws -> Data
    func generateAudioTransciptions(audioData: Data, fileName: String) async throws -> String
    
    func resetHistory()
    func appendHistory(role: String, content: String)
}


extension LLMClient {
    func generateSpeechFrom(input: String, voice: VoiceType, model: String = "tts-1") async throws -> Data {
        try await generateSpeechFrom(input: input, voice: voice, model: model)
    }
}
