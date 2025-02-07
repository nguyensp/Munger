//
//  Config.swift
//  Munger
//
//  Created by Paul Nguyen on 2/7/25.
//

import Foundation

struct Config {
    static var openAIKey: String {
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            fatalError("🚨 Couldn't find Config.plist")
        }
        guard let plist = NSDictionary(contentsOfFile: filePath) else {
            fatalError("🚨 Couldn't load Config.plist")
        }
        guard let apiKey = plist["OPENAI_API_KEY"] as? String else {
            fatalError("🚨 Couldn't find OPENAI_API_KEY in Config.plist")
        }
        
        print("🔑 Loaded API Key: \(apiKey.prefix(5))******") // Only print the first 5 characters
        return apiKey
    }
}
