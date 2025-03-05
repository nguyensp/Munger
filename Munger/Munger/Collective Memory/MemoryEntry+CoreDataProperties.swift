//
//  MemoryEntry+CoreDataProperties.swift
//  Munger
//
//  Created by Paul Nguyen on 3/3/25.
//
//

import Foundation
import CoreData

extension MemoryEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoryEntry> {
        return NSFetchRequest<MemoryEntry>(entityName: "MemoryEntry")
    }

    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var timestamp: Date
    @NSManaged public var emotionScore: Double // 🔥 NEW: Used to prioritize memories
    @NSManaged public var embedding: [Float]? // 🔥 NEW: Used for AI-powered search
    @NSManaged public var tags: Set<Tag>? // Many-to-Many Relationship

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        timestamp = Date()
    }
}

// MARK: Generated accessors for tags
extension MemoryEntry {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}

extension MemoryEntry: Identifiable { }

