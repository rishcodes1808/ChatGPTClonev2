//
//  ConversationEntity+CoreDataClass.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import CoreData

@objc(ConversationEntity)
public class ConversationEntity: NSManagedObject { }


extension ConversationEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationEntity> {
        NSFetchRequest<ConversationEntity>(entityName: "ConversationEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var title: String?
    @NSManaged public var isVoice: Bool
    @NSManaged public var messages: Set<MessageEntity>?
}

extension ConversationEntity {
    var messageEntities: [MessageEntity] {
        let raw = mutableSetValue(forKey: "messages").allObjects
            .compactMap { $0 as? MessageEntity }
        return raw.sorted {
            ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
        }
    }
}

// MARK: Generated accessors for messages
extension ConversationEntity {
    @objc(insertObject:inMessagesAtIndex:)
    @NSManaged public func insertIntoMessages(_ value: MessageEntity, at idx: Int)

    @objc(removeObjectFromMessagesAtIndex:)
    @NSManaged public func removeFromMessages(at idx: Int)

    @objc(insertMessages:atIndexes:)
    @NSManaged public func insertIntoMessages(_ values: [MessageEntity], at indexes: NSIndexSet)

    @objc(removeMessagesAtIndexes:)
    @NSManaged public func removeFromMessages(at indexes: NSIndexSet)

    @objc(replaceObjectInMessagesAtIndex:withObject:)
    @NSManaged public func replaceMessages(at idx: Int, with value: MessageEntity)

    @objc(replaceMessagesAtIndexes:withMessages:)
    @NSManaged public func replaceMessages(at indexes: NSIndexSet, with values: [MessageEntity])

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: MessageEntity)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: MessageEntity)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSOrderedSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSOrderedSet)
}
