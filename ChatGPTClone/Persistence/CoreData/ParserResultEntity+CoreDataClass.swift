//
//  ParserResultEntity+CoreDataClass.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import CoreData

@objc(ParserResultEntity)
public class ParserResultEntity: NSManagedObject { }

extension ParserResultEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ParserResultEntity> {
        NSFetchRequest<ParserResultEntity>(entityName: "ParserResultEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var attributedData: Data?
    @NSManaged public var isCodeBlock: Bool
    @NSManaged public var codeBlockLanguage: String?
    @NSManaged public var orderIndex: Int16
    @NSManaged public var message: MessageEntity?
}
