//
//  ConversationHomeViewModel.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation
import SwiftUI
import AVKit

class ConversationHomeViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    @Published var isInteracting = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    @Published var currentlyPlayingMessageID: UUID? = nil
    
    @Published private(set) var conversationID: UUID?
    @Published private(set) var isVoiceConversation = false
    private let repository = ConversationCoreDataRepository.shared
    
    @Preference(\.selectedVoice) private var selectedVoice
    
    private var audioPlayer: AVAudioPlayer?

    var task: Task<Void, Never>?
        
    private var api: LLMClient
    
    init(api: LLMClient) {
        self.api = api
        
    }
    
    func updateClient(_ client: LLMClient) {
        self.messages = []
        self.api = client
    }
    
    @MainActor
    func sendTapped() async {
        self.task = Task {
            let text = inputMessage
            inputMessage = ""
            await sendAttributed(text: text)
            
        }
    }
    
    @MainActor
    func clearMessages() {
        api.deleteHistoryList()
        withAnimation { [weak self] in
            self?.messages = []
        }
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        self.task = Task {
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
                return
            }
            self.messages.remove(at: index)
            if api.provider == .openAI {
                await sendAttributed(text: message.sendText)
            }
        }
    }
    
    func cancelStreamingResponse() {
        self.task?.cancel()
        self.task = nil
    }
    
    @MainActor
    private func sendAttributed(text: String) async {
        if conversationID == nil {
            startNewConversation()
        }
        guard let convID = conversationID else { return }
        
        isInteracting = true
        var streamText = ""
        
        var messageRow = MessageRow(
            isInteracting: true,
            send: .rawText(text),
            response: .rawText(streamText),
            responseError: nil
        )
        
        self.messages.append(messageRow)
        
        do {
            try repository.addMessage(
                conversationID: convID,
                messageID: messageRow.id,
                text: text,
                isUser: true,
                timestamp: Date(),
                parserResults: []
            )
        } catch {
            print("⚠️ Failed to save user message:", error)
        }
        
        HapticsManager.lightFeedback()
        
        var latestResults: [ParserResult] = []
        var didFireFirstTokenHaptic = false
        
        do {
            let parsingTask = ResponseParsingTask()
            let attributedSend = await parsingTask.parse(text: text)
            try Task.checkCancellation()
            messageRow.send = .attributed(attributedSend)
            self.messages[self.messages.count - 1] = messageRow
            
            let threshold = 64
            var bufferCount = 0
            var currentOutput: AttributedOutput?
            
            let stream = try await api.sendMessageStream(text: text)
            for try await chunk in stream {
                
                if !didFireFirstTokenHaptic {
                    HapticsManager.lightFeedback()
                    didFireFirstTokenHaptic = true
                }
                
                streamText += chunk
                bufferCount += chunk.count
                
                if bufferCount >= threshold || chunk.contains("```") {
                    currentOutput = await parsingTask.parse(text: streamText)
                    try Task.checkCancellation()
                    bufferCount = 0
                }
                
                if let out = currentOutput, !out.results.isEmpty {
                    // update only the last segment
                    let suffix = streamText.trimmingPrefix(out.string)
                    var results = out.results
                    latestResults = out.results
                    let last = results.removeLast()
                    var updated = last.attributedString
                    if last.isCodeBlock {
                        let attrs = AttributeContainer([
                            .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                            .foregroundColor: UIColor.white
                        ])
                        updated.append(AttributedString(String(suffix), attributes: attrs))
                    } else {
                        updated.append(AttributedString(String(suffix)))
                    }
                    results.append(
                        ParserResult(
                            attributedString: updated,
                            isCodeBlock: last.isCodeBlock,
                            codeBlockLanguage: last.codeBlockLanguage
                        )
                    )
                    messageRow.response = .attributed(.init(string: streamText, results: results))
                } else {
                    latestResults = [
                        ParserResult(attributedString: AttributedString(streamText),
                                     isCodeBlock: false, codeBlockLanguage: nil)
                    ]
                    messageRow.response = .attributed(
                        .init(
                            string: streamText,
                            results: [
                                ParserResult(
                                    attributedString: AttributedString(streamText),
                                    isCodeBlock: false,
                                    codeBlockLanguage: nil
                                )
                            ]
                        )
                    )
                }
                
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch is CancellationError {
            messageRow.responseError = "The response was cancelled"
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        if messageRow.response == nil {
            messageRow.response = .rawText(streamText)
        }
        
        let aiText = messageRow.responseText ?? streamText
        let aiMessageID = UUID()
        do {
            try repository.addMessage(
                conversationID: convID,
                messageID: aiMessageID,
                text: aiText,
                isUser: false,
                timestamp: Date(),
                parserResults: latestResults
            )
        } catch {
            print("⚠️ Failed to save AI message:", error)
        }
        
        messageRow.isInteracting = false
        self.messages[self.messages.count - 1] = messageRow
        isInteracting = false
    }
           
    
    @MainActor
    private func send(text: String) async {
        isInteracting = true
        var streamText = ""
        var messageRow = MessageRow(
            isInteracting: true,
            send: .rawText(text),
            response: .rawText(streamText),
            responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let stream = try await api.sendMessageStream(text: text)
            for try await text in stream {
                streamText += text
                messageRow.response = .rawText(streamText.trimmingCharacters(in: .whitespacesAndNewlines))
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isInteracting = false
        self.messages[self.messages.count - 1] = messageRow
        isInteracting = false
    }
    
    @MainActor
    private func sendWithoutStream(text: String) async {
        isInteracting = true
        var messageRow = MessageRow(
            isInteracting: true,
            send: .rawText(text),
            response: .rawText(""),
            responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let responseText = try await api.sendMessage(text)
            try Task.checkCancellation()
            messageRow.response = .rawText(responseText)
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isInteracting = false
        self.messages[self.messages.count - 1] = messageRow
        isInteracting = false
    }
    
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("❌ Failed to set audio session category: \(error)")
        }
    }
    
    @MainActor
    func startNewConversation(with id: UUID? = nil) {
        let newID = id ?? UUID()
        conversationID = newID
        
        messages.removeAll()
    }
}


extension ConversationHomeViewModel {
    @MainActor
    func playResponse(_ message: MessageRow) {
        guard let text = message.responseText, !text.isEmpty else { return }
        
        if let playingID = currentlyPlayingMessageID,
           playingID != message.id {
            audioPlayer?.stop()
        }
        currentlyPlayingMessageID = message.id
        
        Task {
            do {
                let data = try await api.generateSpeechFrom(
                    input: text,
                    voice: selectedVoice
                )
                try await MainActor.run {
                    try playAudio(data: data)
                }
            } catch {
                print("TTS error:", error)
                await MainActor.run {
                    currentlyPlayingMessageID = nil
                }
            }
        }
    }
    
    func playAudio(data: Data) throws {
        configureAudioSession()
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
        audioPlayer = nil
        
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer!.isMeteringEnabled = true
        audioPlayer!.delegate = self
        
        if audioPlayer!.play() {
           
        } else {
           print("Unable to play")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.currentlyPlayingMessageID = nil
        }
    }
}

extension ConversationHomeViewModel {
    @MainActor
    func loadConversation(conversation: ConversationEntity) {
        guard let id = conversation.id else { return }
        
        conversationID = id
        isVoiceConversation = conversation.isVoice
        messages.removeAll()
        
        api.resetHistory()
        
        do {
            let entities = try repository.fetchMessages(for: id)
            print("Fetched entities \(entities.count) for id \(id)")
            
            var i = 0
            while i < entities.count {
                let userEnt = entities[i]
                guard userEnt.isUser else {
                    i += 1
                    continue
                }
                
                let aiEnt: MessageEntity? = {
                    let next = i + 1
                    return next < entities.count && !entities[next].isUser
                    ? entities[next]
                    : nil
                }()
                
                var aiParserResults: [ParserResult]? = nil
                if let ai = aiEnt {
                    let rawSet = ai.mutableSetValue(forKey: "parserResults").allObjects
                    let prEntities = rawSet.compactMap { $0 as? ParserResultEntity }
                    let sorted = prEntities.sorted { $0.orderIndex < $1.orderIndex }
                    aiParserResults = try? sorted.map { pre in
                        guard
                            let data = pre.attributedData,
                            let attr = try? JSONDecoder().decode(AttributedString.self, from: data)
                        else {
                            throw NSError(domain: "DecodeError", code: 0)
                        }
                        return ParserResult(
                            id: pre.id,
                            attributedString: attr,
                            isCodeBlock: pre.isCodeBlock,
                            codeBlockLanguage: pre.codeBlockLanguage
                        )
                    }
                }
                
                let responseType: MessageRowType? = {
                    if let results = aiParserResults, !results.isEmpty {
                        let full = results
                            .map { String($0.attributedString.characters) }
                            .joined()
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !full.isEmpty else { return nil }
                        return .attributed(.init(string: full, results: results))
                    }
                    if let plain = aiEnt?.text?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                       !plain.isEmpty
                    {
                        return .rawText(plain)
                    }
                    return nil
                }()
                
                guard let resp = responseType else {
                    i += (aiEnt != nil ? 2 : 1)
                    continue
                }
                
                let userText = userEnt.text ?? ""
                api.appendHistory(role: "user", content: userText)
                
                let aiText: String
                switch resp {
                case .rawText(let t):
                    aiText = t
                case .attributed(let out):
                    aiText = out.string
                }
                
                api.appendHistory(role: "assistant", content: aiText)
                
                let row = MessageRow(
                    id: userEnt.id ?? UUID(),
                    isInteracting: false,
                    send: .rawText(userText),
                    response: resp,
                    responseError: nil
                )
                messages.append(row)
                
                i += (aiEnt != nil ? 2 : 1)
            }
            
        } catch {
            print("Failed to load conversation \(id):", error)
        }
    }
}
