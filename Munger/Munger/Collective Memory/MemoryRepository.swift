//
//  MemoryRepository.swift
//  Munger
//
//  Created by Paul Nguyen on 3/4/25.
//

import NaturalLanguage
import CoreML
import CoreData
import Combine

class MemoryRepository {
    private let context: NSManagedObjectContext
    private let aiChatService: ServiceAIChat
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = CollectiveMemoryManager.shared.viewContext,
         aiChatService: ServiceAIChat) {
        self.context = context
        self.aiChatService = aiChatService
    }

    func saveMemory(text: String) {
        let backgroundContext = CollectiveMemoryManager.shared.backgroundContext
        backgroundContext.perform {
            let newMemory = MemoryEntry(context: backgroundContext)
            newMemory.text = text
            newMemory.timestamp = Date()

            // 🔥 Auto-assign emotion score (Default: Neutral = 0.5)
            newMemory.emotionScore = 0.5

            // 🔥 Auto-tag using NLP
            let detectedTags = self.autoTag(text: text)
            var tagObjects = Set<Tag>()
            for tagName in detectedTags {
                let tag = self.fetchOrCreateTag(named: tagName, context: backgroundContext)
                tagObjects.insert(tag)
            }
            newMemory.tags = tagObjects

            // 🔥 Generate AI embedding asynchronously
            self.generateEmbedding(for: text) { embedding in
                newMemory.embedding = embedding

                do {
                    try backgroundContext.save()
                    print("✅ Memory saved with auto-tags & embedding!")
                } catch {
                    print("❌ Error saving memory: \(error)")
                }
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
    
    func autoTag(text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType]) // ✅ Fixed enum value
        tagger.string = text

        var extractedTags: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, _ in
            if let tag = tag?.rawValue {
                extractedTags.append(tag)
            }
            return true
        }
        return extractedTags
    }
    
    func generateEmbedding(for text: String, completion: @escaping ([Float]?) -> Void) {
        aiChatService.generateEmbedding(for: text)
            .sink(receiveCompletion: { _ in }, receiveValue: { embedding in
                completion(embedding)
            })
            .store(in: &cancellables)
    }
    
    func findSimilarMemories(query: String, completion: @escaping ([MemoryEntry]) -> Void) {
        generateEmbedding(for: query) { queryEmbedding in
            guard let queryEmbedding = queryEmbedding else {
                completion([])
                return
            }

            let allMemories = self.fetchAllMemories()
            let sortedMemories = allMemories.sorted {
                self.cosineSimilarity($0.embedding, queryEmbedding) > self.cosineSimilarity($1.embedding, queryEmbedding)
            }

            completion(Array(sortedMemories.prefix(5)))
        }
    }
    
    func cosineSimilarity(_ vecA: [Float]?, _ vecB: [Float]?) -> Double {
        guard let vecA = vecA, let vecB = vecB, vecA.count == vecB.count else { return 0 }
        
        let dotProduct = zip(vecA, vecB).map { Double($0 * $1) }.reduce(0, +)
        let magnitudeA = sqrt(vecA.map { Double($0 * $0) }.reduce(0, +))
        let magnitudeB = sqrt(vecB.map { Double($0 * $0) }.reduce(0, +))
        
        return magnitudeA > 0 && magnitudeB > 0 ? dotProduct / (magnitudeA * magnitudeB) : 0
    }
    
    func fetchPrioritizedMemories() -> [MemoryEntry] {
        let allMemories = fetchAllMemories()

        let scoredMemories = allMemories.map { memory -> (MemoryEntry, Double) in
            let recencyWeight = 1.0 / max(1, Date().timeIntervalSince(memory.timestamp))  // Newer memories score higher
            let tagWeight = Double(memory.tags?.count ?? 1) * 0.1  // More tags = more relevant
            let emotionWeight = memory.emotionScore * 0.5  // Higher emotion = more important
            return (memory, recencyWeight + tagWeight + emotionWeight)
        }

        return scoredMemories.sorted { $0.1 > $1.1 }.map { $0.0 }
    }
}
