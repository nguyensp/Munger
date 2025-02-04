//
//  Cache.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation

protocol Cache {
    func get<T: Codable>(for key: String) async throws -> T?
    func set<T: Codable>(_ value: T, for key: String) async throws
}
