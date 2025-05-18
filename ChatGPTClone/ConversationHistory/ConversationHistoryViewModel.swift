//
//  ConversationHistoryViewModel.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation
import Combine

class ConversationHistoryViewModel: ObservableObject {
    @Published var conversations: [ConversationEntity] = []
    
    private let repository = ConversationCoreDataRepository.shared
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    init() {
        loadHistory()
    }
    
    func loadHistory() {
        do {
            conversations = try repository.fetchAllConversations()
        } catch {
            print("Failed to fetch history:", error)
            conversations = []
        }
    }
    
    func delete(at offsets: IndexSet) {
        for idx in offsets {
            let conv = conversations[idx]
            if let id = conv.id {
                do {
                    try repository.deleteConversation(id: id)
                    conversations.remove(at: idx)
                } catch {
                    print("Failed to delete conversation \(id):", error)
                }
            }
        }
    }
    
    func dateString(for conv: ConversationEntity) -> String {
        guard let d = conv.createdAt else { return "" }
        return Self.dateFormatter.string(from: d)
    }
}
