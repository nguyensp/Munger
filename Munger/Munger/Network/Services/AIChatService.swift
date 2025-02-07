//
//  AIChatService.swift
//  Munger
//
//  Created by Paul Nguyen on 2/6/25.
//

import Foundation
import Combine

enum AIProvider {
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

class AIChatService {
    private let requestDispatcher: RequestDispatcher
    private var provider: AIProvider
    private var messages: [Message] = []
    
    init(
        requestDispatcher: RequestDispatcher = ServiceConfig.shared.dispatcher,
        provider: AIProvider = .openai
    ) {
        self.requestDispatcher = requestDispatcher
        self.provider = provider
        
        // Initialize with a system message
        self.messages = [Message(
            role: "system",
            content: "You are an expert value investor trained in Rule #1 investing methodology. Help analyze companies and provide investment insights based on fundamental analysis. Focus on moats, management quality, margin of safety, and long-term value creation."
        )]
    }
    
    func setProvider(_ provider: AIProvider) {
        self.provider = provider
    }
    
    func sendMessage(_ content: String) -> AnyPublisher<String, Error> {
        // Add user message to history
        messages.append(Message(role: "user", content: content))
        
        guard let url = URL(string: provider.baseURL) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let body = ChatRequestBody(
            model: provider.model,
            messages: messages,
            temperature: 0.7
        )
        /*
        let apiKey = provider == .openai ?
            ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "" :
            ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] ?? ""
        */
        
        let apiKey = Config.openAIKey
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let urlRequest = RequestBuilder.createRequest(
            url: url,
            method: "POST",
            header: headers,
            body: try? JSONEncoder().encode(body)
        )
        
        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { data -> String in
                let response = try JSONDecoder().decode(ChatResponse.self, from: data)
                guard let message = response.choices.first?.message else {
                    throw URLError(.cannotParseResponse)
                }
                // Add AI response to history
                self.messages.append(message)
                return message.content
            }
            .eraseToAnyPublisher()
    }
    
    func clearConversation() {
        messages = [messages[0]] // Keep only the system message
    }
}

