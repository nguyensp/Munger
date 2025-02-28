//
//  AIChatModels.swift
//  Munger
//
//  Created by Paul Nguyen on 2/28/25.
//

public enum AIProvider {
    case openai
    case deepseek
    
    var baseURL: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .deepseek:
            return "https://api.deepseek.com/v1/chat/completions"
        }
    }
    
    var model: String {
        switch self {
        case .openai:
            return "gpt-4-turbo-preview"
        case .deepseek:
            return "deepseek-chat"
        }
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct ChatRequestBody: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
}

struct ChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
}
