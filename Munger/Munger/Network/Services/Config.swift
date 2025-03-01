//
//  Config.swift
//  Munger
//
//  Created by Paul Nguyen on 2/7/25.
//

import Foundation

struct Config {
    static var openAIKey: String {
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let apiKey = plist["OPENAI_API_KEY"] as? String else {
            fatalError("🚨 Couldn't find OPENAI_API_KEY in Config.plist")
        }
        print("🔑 Loaded OpenAI API Key: \(apiKey.prefix(5))******")
        return apiKey
    }
    
    static var xAIKey: String {
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let apiKey = plist["XAI_API_KEY"] as? String else {
            fatalError("🚨 Couldn't find XAI_API_KEY in Config.plist")
        }
        print("🔑 Loaded xAI API Key: \(apiKey.prefix(5))******")
        return apiKey
    }
    
    // Optional: Add DeepSeek if you use it
    static var deepSeekKey: String {
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let apiKey = plist["DEEPSEEK_API_KEY"] as? String else {
            fatalError("🚨 Couldn't find DEEPSEEK_API_KEY in Config.plist")
        }
        print("🔑 Loaded DeepSeek Ascendancy DeepSeek API Key: \(apiKey.prefix(5))******")
        return apiKey
    }
}
