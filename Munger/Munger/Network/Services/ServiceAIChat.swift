//
//  ServiceAIChat.swift
//  Munger
//
//  Created by Paul Nguyen on 2/6/25.
//

import Foundation
import Combine

public final class ServiceAIChat {
    private let requestDispatcher: RequestDispatcher
    private var provider: AIProvider
    private var messages: [Message] = []
    
    init(
        requestDispatcher: RequestDispatcher,
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
        
        // Extensive logging
        print("🔍 Sending message to AI")
        print("🌐 Provider: \(provider)")
        print("🔑 API Key (first 5 chars): \(String(Config.openAIKey.prefix(5)))")
        
        guard let url = URL(string: provider.baseURL) else {
            print("🚨 ERROR: Invalid URL - \(provider.baseURL)")
            return Fail(error: URLError(.badURL) as Error)
                .eraseToAnyPublisher()
        }
        
        let body = ChatRequestBody(
            model: "gpt-4o-mini", // Updated to latest model
            messages: messages,
            temperature: 0.7
        )
        
        let apiKey = Config.openAIKey
        
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
                // Log response data for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Response Data: \(jsonString)")
                }
                
                let response = try JSONDecoder().decode(ChatResponse.self, from: data)
                guard let message = response.choices.first?.message else {
                    print("🚨 ERROR: Cannot parse response message")
                    throw URLError(.cannotParseResponse)
                }
                
                // Add AI response to history
                self.messages.append(message)
                return message.content
            }
            .mapError { (error: Error) -> Error in
                // Detailed error logging
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
}

