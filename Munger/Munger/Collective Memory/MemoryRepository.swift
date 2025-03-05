//
//  MemoryRepository.swift
//  Munger
//
//  Created by Paul Nguyen on 3/4/25.
//

import CoreData

class MemoryRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CollectiveMemoryManager.shared.viewContext) {
        self.context = context
    }

    // Save a new memory
    func saveMemory(text: String, tags: [String] = []) {
        let backgroundContext = CollectiveMemoryManager.shared.backgroundContext
        backgroundContext.perform {
            let newMemory = MemoryEntry(context: backgroundContext)
            newMemory.text = text
            newMemory.timestamp = Date()

            var tagObjects = Set<Tag>()
            for tagName in tags {
                let tag = self.fetchOrCreateTag(named: tagName, context: backgroundContext)
                tagObjects.insert(tag)
            }
            newMemory.tags = tagObjects

            do {
                try backgroundContext.save()
                print("✅ Memory saved!")
            } catch {
                print("❌ Error saving memory: \(error)")
            }
        }
    }

    // Fetch all memories
    func fetchAllMemories() -> [MemoryEntry] {
        let fetchRequest: NSFetchRequest<MemoryEntry> = MemoryEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ Error fetching memories: \(error)")
            return []
        }
    }

    // Fetch memories by tag
    func fetchMemoriesByTag(tagName: String) -> [MemoryEntry] {
        let fetchRequest: NSFetchRequest<MemoryEntry> = MemoryEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY tags.name == %@", tagName)

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ Error fetching memories by tag: \(error)")
            return []
        }
    }

    // Helper function: Fetch or create a tag
    private func fetchOrCreateTag(named name: String, context: NSManagedObjectContext) -> Tag {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        if let existingTag = try? context.fetch(fetchRequest).first {
            return existingTag
        } else {
            let newTag = Tag(context: context)
            newTag.id = UUID()
            newTag.name = name
            return newTag
        }
    }
}

