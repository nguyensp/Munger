//
//  Tag+CoreDataProperties.swift
//  Munger
//
//  Created by Paul Nguyen on 3/3/25.
//
//

import Foundation
import CoreData

extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var memories: Set<MemoryEntry>? // Many-to-Many Relationship

    // Auto-assign UUID on insert
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}

// MARK: Generated accessors for memories
extension Tag {

    @objc(addMemoriesObject:)
    @NSManaged public func addToMemories(_ value: MemoryEntry)

    @objc(removeMemoriesObject:)
    @NSManaged public func removeFromMemories(_ value: MemoryEntry)

    @objc(addMemories:)
    @NSManaged public func addToMemories(_ values: NSSet)

    @objc(removeMemories:)
    @NSManaged public func removeFromMemories(_ values: NSSet)
}

extension Tag: Identifiable { }
