//
//  MessageEntity+CoreDataClass.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import CoreData

@objc(MessageEntity)
public class MessageEntity: NSManagedObject { }


extension MessageEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageEntity> {
        NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var isUser: Bool
    @NSManaged public var timestamp: Date?
    @NSManaged public var conversation: ConversationEntity?
    
    @NSManaged public var parserResults: Set<ParserResultEntity>?
}

// MARK: Generated accessors for parserResults
extension MessageEntity {
    @objc(insertObject:inParserResultsAtIndex:)
    @NSManaged public func insertIntoParserResults(_ value: ParserResultEntity, at idx: Int)

    @objc(removeObjectFromParserResultsAtIndex:)
    @NSManaged public func removeFromParserResults(at idx: Int)

    @objc(insertParserResults:atIndexes:)
    @NSManaged public func insertIntoParserResults(_ values: [ParserResultEntity], at indexes: NSIndexSet)

    @objc(removeParserResultsAtIndexes:)
    @NSManaged public func removeFromParserResults(at indexes: NSIndexSet)

    @objc(replaceObjectInParserResultsAtIndex:withObject:)
    @NSManaged public func replaceParserResults(at idx: Int, with value: ParserResultEntity)

    @objc(replaceParserResultsAtIndexes:withParserResults:)
    @NSManaged public func replaceParserResults(at indexes: NSIndexSet, with values: [ParserResultEntity])

    @objc(addParserResultsObject:)
    @NSManaged public func addToParserResults(_ value: ParserResultEntity)

    @objc(removeParserResultsObject:)
    @NSManaged public func removeFromParserResults(_ value: ParserResultEntity)

    @objc(addParserResults:)
    @NSManaged public func addToParserResults(_ values: NSOrderedSet)

    @objc(removeParserResults:)
    @NSManaged public func removeFromParserResults(_ values: NSOrderedSet)
}
