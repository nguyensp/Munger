//
//  AIChatViewModel.swift
//  Munger
//
//  Created by Paul Nguyen on 2/6/25.
//

import Foundation
import Combine

/// Handles AIChat Logic
class AIChatViewModel: ObservableObject {
    @Published var messages: [(role: String, content: String)] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let chatService: ServiceAIChat
    private var cancellables = Set<AnyCancellable>()
    
    init(chatService: ServiceAIChat) {
        self.chatService = chatService
    }
    
    func sendMessage(_ content: String) {
        messages.append((role: "user", content: content))
        isLoading = true
        error = nil
        
        chatService.sendMessage(content)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] response in
                    self?.messages.append((role: "assistant", content: response))
                }
            )
            .store(in: &cancellables)
    }
    
    func setProvider(_ provider: AIProvider) {
        chatService.setProvider(provider)
    }
    
    func clearChat() {
        messages.removeAll()
        chatService.clearConversation()
    }
}

