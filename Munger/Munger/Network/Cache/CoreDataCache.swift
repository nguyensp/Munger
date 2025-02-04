//
//  CoreDataCache.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation
import CoreData

class CoreDataCache: Cache {
    private let container: NSPersistentContainer
    private let expirationInterval: TimeInterval
    
    init(modelName: String = "Cache", expirationInterval: TimeInterval = 86400) {
        print("📦 Initializing CoreDataCache")
        self.container = NSPersistentContainer(name: modelName)
        self.expirationInterval = expirationInterval
        container.loadPersistentStores { _, error in
            if let error = error {
                print("🚨 Core Data failed to load: \(error)")
                fatalError("Core Data failed to load: \(error)")
            }
            print("✅ Core Data store loaded successfully")
        }
    }
    
    func get<T: Codable>(for key: String) async throws -> T? {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CacheEntry")
        request.predicate = NSPredicate(format: "key == %@", key)
        
        let results = try context.fetch(request)
        print("📊 Found \(results.count) cache entries for key: \(key)")
        
        guard let entry = results.first,
              let timestamp = entry.value(forKey: "timestamp") as? Date,
              let data = entry.value(forKey: "data") as? Data else {
            print("❌ No valid cache entry found")
            return nil
        }
        
        if Date().timeIntervalSince(timestamp) >= expirationInterval {
            print("⏰ Cache expired for key: \(key)")
            return nil
        }
        
        print("✅ Valid cache entry found, size: \(data.count) bytes")
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func set<T: Codable>(_ value: T, for key: String) async throws {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CacheEntry")
        request.predicate = NSPredicate(format: "key == %@", key)
        
        let entry: NSManagedObject
        if let existing = try context.fetch(request).first {
            print("🔄 Updating existing cache entry")
            entry = existing
        } else {
            print("➕ Creating new cache entry")
            let entity = NSEntityDescription.entity(forEntityName: "CacheEntry", in: context)!
            entry = NSManagedObject(entity: entity, insertInto: context)
        }
        
        let data = try JSONEncoder().encode(value)
        print("💾 Saving \(data.count) bytes to cache")
        
        entry.setValue(key, forKey: "key")
        entry.setValue(Date(), forKey: "timestamp")
        entry.setValue(data, forKey: "data")
        
        try context.save()
        print("✅ Cache save completed")
    }
}
