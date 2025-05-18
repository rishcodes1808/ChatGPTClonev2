//
//  ConversationCoreDataRepository.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import CoreData

final class ConversationCoreDataRepository {
    static let shared = ConversationCoreDataRepository()
    private let ctx = PersistenceController.shared.viewContext

    private init() {}

    func createConversation(id: UUID, title: String, isVoice: Bool = false) throws -> ConversationEntity {
        let conv = ConversationEntity(context: ctx)
        conv.title = title
        conv.id = id
        conv.isVoice = isVoice
        conv.createdAt = Date()
        try PersistenceController.shared.saveContext()
        return conv
    }

    func fetchConversation(by id: UUID) -> ConversationEntity? {
        let req = ConversationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? ctx.fetch(req).first
    }

    func getOrCreateConversation(id: UUID, title: String, isVoice: Bool = false) throws -> ConversationEntity {
        if let existing = fetchConversation(by: id) {
            return existing
        } else {
            return try createConversation(id: id, title: title, isVoice: isVoice)
        }
    }

    func addMessage(
        conversationID: UUID,
        messageID: UUID,
        text: String,
        isUser: Bool,
        timestamp: Date = .init(),
        isVoice: Bool = false,
        parserResults: [ParserResult] = []
    ) throws {
        let conv = try getOrCreateConversation(id: conversationID, title: text, isVoice: isVoice)
        let msg = MessageEntity(context: ctx)
        msg.id = messageID
        msg.text = text
        msg.isUser = isUser
        msg.timestamp = timestamp
        msg.conversation = conv

        if !parserResults.isEmpty {
            print("adding parser results \(parserResults.count)")
            for (idx, pr) in parserResults.enumerated() {
                let pe = ParserResultEntity(context: ctx)
                pe.id = pr.id
                pe.isCodeBlock = pr.isCodeBlock
                pe.codeBlockLanguage = pr.codeBlockLanguage
                pe.orderIndex = Int16(idx)
                pe.attributedData = try JSONEncoder().encode(pr.attributedString)
                pe.message = msg
                conv.addToMessages(msg)
                msg.addToParserResults(pe)
            }
        } else {
            conv.addToMessages(msg)
        }

        try PersistenceController.shared.saveContext()
    }

    func fetchAllConversations() throws -> [ConversationEntity] {
        let req = ConversationEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try ctx.fetch(req)
    }

    func fetchMessages(for conversationID: UUID) throws -> [MessageEntity] {
        guard let conv = fetchConversation(by: conversationID) else { return [] }
        return conv.messageEntities
    }
    
    func deleteConversation(id: UUID) throws {
        let ctx = PersistenceController.shared.viewContext
        let req = ConversationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let toDelete = try ctx.fetch(req).first {
            ctx.delete(toDelete)
            try PersistenceController.shared.saveContext()
        }
    }
}
