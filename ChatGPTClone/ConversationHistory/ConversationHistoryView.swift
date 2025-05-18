//
//  ConversationHistoryView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct ConversationHistoryView: View {
    @StateObject private var vm = ConversationHistoryViewModel()
    let onNewConversation: () -> Void
    
    let onSelect: (ConversationEntity) -> Void
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Group {
            if vm.conversations.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Conversations Yet")
                        .font(.title2).bold()
                    Text("Tap below to start a brand new chat.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: {
                        startNewConversation()
                    }) {
                        Text("Start New Conversation")
                            .frame(minWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List {
                    ForEach(vm.conversations, id: \.id) { conv in
                        Button(action: {
                            if let id = conv.id {
                                dismiss()
                                onSelect(conv)
                            }
                        }) {
                            HStack {
                                Text(conv.title ?? "New Conversation")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Text(vm.dateString(for: conv))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: vm.delete)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    startNewConversation()
                }) {
                    Image(systemName: "square.and.pencil.circle.fill")
                }
            }
        }
        .onAppear { vm.loadHistory() }
    }
    
    private func startNewConversation() {
        dismiss()
        onNewConversation()
    }
}
