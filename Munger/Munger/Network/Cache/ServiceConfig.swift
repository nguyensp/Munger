//
//  ServiceConfig.swift
//  Munger
//
//  Created by Paul Nguyen on 2/4/25.
//

import Foundation

class ServiceConfig {
    static let shared = ServiceConfig()
    
    lazy var cache: Cache = {
        CoreDataCache(modelName: "Cache")
    }()
    
    lazy var dispatcher: RequestDispatcher = {
        CachingDispatcher(cache: cache)
    }()
    
    private init() {}
}
