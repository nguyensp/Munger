//
//  CollectiveMemoryManager.swift
//  Munger
//
//  Created by Paul Nguyen on 3/4/25.
//

import CoreData

class CollectiveMemoryManager {
    static let shared = CollectiveMemoryManager()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "MemoryModel")
        persistentContainer.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("❌ Failed to load Core Data: \(error)")
            }
        }
    }

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Error saving Core Data: \(error)")
            }
        }
    }
}

