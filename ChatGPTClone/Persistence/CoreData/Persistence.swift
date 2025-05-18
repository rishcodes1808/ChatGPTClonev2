//
//  Persistence.swift
//  ChatGPTClone
//
//  Created by Rish on 16/05/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ChatGPTClone")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func saveContext() throws {
        let ctx = viewContext
        if ctx.hasChanges {
            try ctx.save()
        }
    }
}
