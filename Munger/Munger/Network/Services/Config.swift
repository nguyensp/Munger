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
            fatalError("Couldn't find OpenAI API key in Config.plist")
        }
        return apiKey
    }
}
