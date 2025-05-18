//
//  OpenAIAPI.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

class OpenAIAPI: LLMClient, @unchecked Sendable {
    
    var provider: LLMProvider { .openAI }
    
    private let systemMessage: Message
    private let temperature: Double
    private let model: String
    
    private let apiKey: String
    private var historyList = [Message]()
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach {  urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd"
        return df
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    
    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    

    init(apiKey: String, model: String = "gpt-3.5-turbo", systemPrompt: String = "You are a helpful assistant", temperature: Double = 0.5) {
        self.apiKey = apiKey
        self.model = model
        self.systemMessage = .init(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    private func generateMessages(from text: String) -> [Message] {
        var messages = [systemMessage] + historyList + [Message(role: "user", content: text)]
        
        if messages.contentCount > (4000 * 4) {
            _ = historyList.removeFirst()
            messages = generateMessages(from: text)
        }
        return messages
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let request = Request(model: model, temperature: temperature,
                              messages: generateMessages(from: text), stream: stream)
        return try JSONEncoder().encode(request)
    }
    
    private func appendToHistoryList(userText: String, responseText: String) {
        self.historyList.append(.init(role: "user", content: userText))
        self.historyList.append(.init(role: "assistant", content: responseText))
    }
    
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        try Task.checkCancellation()
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var errorText = ""
            for try await line in result.lines {
                try Task.checkCancellation()
                errorText += line
            }
            
            if let data = errorText.data(using: .utf8), let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                errorText = "\n\(errorResponse.message)"
            }
            
            throw "Bad Response: \(httpResponse.statusCode), \(errorText)"
        }
        
        var responseText = ""
        let streams: AsyncThrowingStream<String, Error> = AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in result.lines {
                        try Task.checkCancellation()
                        continuation.yield(line)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        
        return AsyncThrowingStream { [weak self] in
            guard let self else { return nil }
            for try await line in streams {
                try Task.checkCancellation()
                if line.hasPrefix("data: "),
                   let data = line.dropFirst(6).data(using: .utf8),
                   let response = try? self.jsonDecoder.decode(StreamCompletionResponse.self, from: data),
                   let text = response.choices.first?.delta.content {
                    responseText += text
                    return text
                }
            }
            self.appendToHistoryList(userText: text, responseText: responseText)
            return nil
        }
    }

    func sendMessage(_ text: String) async throws -> String {
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        try Task.checkCancellation()
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var error = "Bad Response: \(httpResponse.statusCode)"
            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                error.append("\n\(errorResponse.message)")
            }
            throw error
        }
        
        do {
            let completionResponse = try self.jsonDecoder.decode(CompletionResponse.self, from: data)
            let responseText = completionResponse.choices.first?.message.content ?? ""
            self.appendToHistoryList(userText: text, responseText: responseText)
            return responseText
        } catch {
            throw error
        }
    }
    
    func deleteHistoryList() {
        self.historyList.removeAll()
    }
}

extension OpenAIAPI {
    func generateAudioTransciptions(audioData: Data, fileName: String = "recording.m4a") async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        let boundary: String = UUID().uuidString
        request.timeoutInterval = 30
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let bodyBuilder = MultipartFormDataBodyBuilder(boundary: boundary, entries: [
            .file(paramName: "file", fileName: fileName, fileData: audioData, contentType: "audio/mpeg"),
            .string(paramName: "model", value: "whisper-1"),
            .string(paramName: "response_format", value: "text")
        ])
        request.httpBody = bodyBuilder.build()
        let (data, resp) = try await urlSession.data(for: request)
        guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw "Invalid Status Code \((resp as? HTTPURLResponse)?.statusCode ?? -1)"
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw "Invalid format"
        }
        
        return text
    }

    
    func generateSpeechFrom(input: String, voice: VoiceType, model: String = "tts-1") async throws -> Data {
           guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
               throw "Invalid URL for speech generation"
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           request.setValue("aac", forHTTPHeaderField: "Accept")


           let requestBody = SpeechRequestBody(model: model, input: input, voice: voice.rawValue)
           
           do {
               request.httpBody = try JSONEncoder().encode(requestBody)
           } catch {
               throw "Failed to encode speech request body: \(error.localizedDescription)"
           }
           
           let (data, response) = try await urlSession.data(for: request)
           try Task.checkCancellation()
           
           guard let httpResponse = response as? HTTPURLResponse else {
               throw "Invalid response object for speech generation"
           }
           
           guard (200...299).contains(httpResponse.statusCode) else {
               // Try to decode error message from OpenAI if available
               if let errorDetail = String(data: data, encoding: .utf8) {
                   throw "Speech generation failed with status code \(httpResponse.statusCode): \(errorDetail)"
               } else {
                   throw "Speech generation failed with status code \(httpResponse.statusCode)"
               }
           }
           
           return data
       }
}

extension OpenAIAPI {
    public func resetHistory() {
        historyList.removeAll()
    }

    public func appendHistory(role: String, content: String) {
        let msg = Message(role: role, content: content)
        historyList.append(msg)
    }
}

extension String: @retroactive Error {}
extension String: @retroactive CustomNSError {
    
    public var errorUserInfo: [String : Any] {
        [
            NSLocalizedDescriptionKey: self
        ]
    }
}

