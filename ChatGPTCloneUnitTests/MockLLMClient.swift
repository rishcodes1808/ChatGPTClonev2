//
//  MockLLMClient.swift
//  ChatGPTClone
//
//  Created by Rish on 18/05/25.
//

@testable import ChatGPTClone
import Foundation

final class MockLLMClient: LLMClient {
    func deleteHistoryList() {
        
    }
    
    func generateAudioTransciptions(audioData: Data, fileName: String) async throws -> String {
        ""
    }
    
    func resetHistory() {
        
    }
    
    func appendHistory(role: String, content: String) {
        
    }
    
    var provider: LLMProvider = .openAI
    func sendMessage(_ text: String) async throws -> String { "" }
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in continuation.finish() }
    }
    func generateSpeechFrom(input: String, voice: VoiceType, model: String = "") async throws -> Data {
        // return a tiny valid WAV/AAC header or just silence
        return Data([0x52,0x49,0x46,0x46]) // "RIFF" minimal
    }
}
