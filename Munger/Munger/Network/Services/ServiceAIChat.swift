//
//  ServiceAIChat.swift
//  Munger
//
//  Created by Paul Nguyen on 2/6/25.
//

import Foundation
import Combine

/// AI Chat Service
public final class ServiceAIChat {
    private let requestDispatcher: RequestDispatcher
    private var provider: AIProvider
    private var messages: [Message] = []
    
    init(
        requestDispatcher: RequestDispatcher,
        provider: AIProvider = .openai // OpenAI remains default
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
        
        // Logging
        print("🔍 Sending message to AI")
        print("🌐 Provider: \(provider)")
        
        guard let url = URL(string: provider.baseURL) else {
            print("🚨 ERROR: Invalid URL - \(provider.baseURL)")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Use provider-specific model and key
        let body = ChatRequestBody(
            model: provider.model, // Dynamic model from AIProvider
            messages: messages,
            temperature: 0.7
        )
        
        let apiKey: String
        switch provider {
        case .openai:
            apiKey = Config.openAIKey
            print("🔑 Using OpenAI Key (first 5 chars): \(String(Config.openAIKey.prefix(5)))")
        case .deepseek:
            apiKey = Config.deepSeekKey // Add this to Config if using DeepSeek
            print("🔑 Using DeepSeek Key (first 5 chars): \(String(Config.deepSeekKey.prefix(5)))")
        case .grok:
            apiKey = Config.xAIKey // Add this to Config
            print("🔑 Using xAI Key (first 5 chars): \(String(Config.xAIKey.prefix(5)))")
        }
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        // Log request body
        if let bodyData = try? JSONEncoder().encode(body),
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        
        let urlRequest = RequestBuilder.createRequest(
            url: url,
            method: "POST",
            header: headers,
            body: try? JSONEncoder().encode(body)
        )
        
        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { (data: Data) -> String in
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Response Data: \(jsonString)")
                }
                
                let response = try JSONDecoder().decode(ChatResponse.self, from: data)
                guard let message = response.choices.first?.message else {
                    print("🚨 ERROR: Cannot parse response message")
                    throw URLError(.cannotParseResponse)
                }
                
                self.messages.append(message)
                return message.content
            }
            .mapError { (error: Error) -> Error in
                print("🚨 Network Error: \(error)")
                print("🚨 Error Type: \(type(of: error))")
                if let urlError = error as? URLError {
                    print("🚨 URLError Code: \(urlError.code)")
                    print("🚨 URLError Description: \(urlError.localizedDescription)")
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func clearConversation() {
        messages = [messages[0]] // Keep only the system message
    }
    
    func generateEmbedding(for text: String) -> AnyPublisher<[Float], Error> {
        guard let url = URL(string: "https://api.openai.com/v1/embeddings") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let requestBody: [String: Any] = [
            "input": text,
            "model": "text-embedding-ada-002"
        ]

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(Config.openAIKey)" // Uses existing API key
        ]

        let urlRequest = RequestBuilder.createRequest(
            url: url,
            method: "POST",
            header: headers,
            body: try? JSONSerialization.data(withJSONObject: requestBody)
        )

        return requestDispatcher.dispatch(request: urlRequest)
            .tryMap { (data: Data) -> [Float] in
                let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
                guard let embeddingArray = response.data.first?.embedding else {
                    throw URLError(.cannotParseResponse)
                }
                return embeddingArray
            }
            .mapError { error in
                print("🚨 Embedding API Error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }

}
