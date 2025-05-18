//
//  MessageRowView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI
import Markdown

struct MessageRowView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let message: MessageRow
    let isPlaying: Bool
    let retryCallback: (MessageRow) -> Void
    let onShowToast: (String) -> Void
    let onPlay: (MessageRow) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            bubble(
                rowType: message.send,
                bgColor: colorScheme == .light ? Color.blue.opacity(0.2) : Color.blue.opacity(0.4),
                isUser: true
            )
            
            if let response = message.response {
                bubble(
                    rowType: response,
                    bgColor: colorScheme == .light ? Color.gray.opacity(0.2) : Color.gray.opacity(0.4),
                    responseError: message.responseError,
                    showDotLoading: message.isInteracting,
                    isUser: false
                )
            }
        }
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    private func bubble(
        rowType: MessageRowType,
        bgColor: Color,
        responseError: String? = nil,
        showDotLoading: Bool = false,
        isUser: Bool
    ) -> some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: .leading, spacing: 8) {
                if showDotLoading, rowType.isEmpty {
                    Text("Thinking…")
                        .italic()
                        .shimmering(animation: .easeInOut(duration: 2.0).repeatForever(autoreverses: true))
                } else {
                    switch rowType {
                    case .attributed(let output):
                        attributedView(results: output.results)
                    case .rawText(let text):
                        if isUser {
                            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        } else {
                            Text(text)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        }
                        
                    }
                }
                
                if let err = responseError, !isUser {
                    Text("Error: \(err)")
                        .foregroundColor(.red)
                    Button("Regenerate") { retryCallback(message) }
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
                
                if showDotLoading, !rowType.isEmpty {
                    DotLoadingView().frame(width: 60, height: 30)
                }
                
                if !isUser, !rowType.isEmpty {
                    HStack(spacing: 16) {
                        if let text = rowType.plainText, !text.isEmpty {
                            copyButton(for: text)
                            playButton()
                        }
                    }
                }
            }
            .padding(12)
            .padding(isUser ? .trailing : .leading, 12)
            .background(bgColor)
            .clipShape(ChatBubble(isUser: isUser))
            
            if !isUser { Spacer() }
        }
    }
    
    private func copyButton(for text: String) -> some View {
        Button(action: {
            UIPasteboard.general.string = text
            onShowToast("Copied To Clipboard")
        }) {
            Image(systemName: "doc.on.doc")
                .font(.subheadline)
        }
        .padding(.top, 4)
    }
    
    private func playButton() -> some View {
        Button(action: {
            onPlay(message)
        }) {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.circle")
                .font(.subheadline)
        }
        .padding(.top, 4)
        .disabled(isPlaying)
    }

    
    private func attributedView(results: [ParserResult]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(results) { parsed in
                if parsed.isCodeBlock {
                    CodeBlockView(parserResult: parsed)
                        .padding(.bottom, 24)
                } else {
                    Text(parsed.attributedString)
                        .textSelection(.enabled)
                }
            }
        }
    }
}


struct MessageRowView_Previews: PreviewProvider {
    static let userOnly = MessageRow(
        isInteracting: false,
        send: .rawText("This is a user message."),
        response: nil,
        responseError: nil
    )
    
    static let aiOnly = MessageRow(
        isInteracting: false,
        send: .rawText(""),
        response: .rawText("This is an AI response."),
        responseError: nil
    )
    
    static let userAndAi = MessageRow(
        isInteracting: true,
        send: .rawText("What is SwiftUI?"),
        response: .rawText("SwiftUI is Apple’s declarative UI framework."),
        responseError: nil
    )
    
    static var previews: some View {
        VStack(spacing: 20) {
            Text("User-only (right aligned)")
            MessageRowView(message: userOnly, isPlaying: false) { _ in } onShowToast: { _ in } onPlay: { _ in }
            
            Text("AI-only (left aligned)")
            MessageRowView(message: aiOnly, isPlaying: false) { _ in } onShowToast: { _ in } onPlay: { _ in }
            
            Text("User + AI")
            MessageRowView(message: userAndAi, isPlaying: false) { _ in } onShowToast: { _ in } onPlay: { _ in }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
