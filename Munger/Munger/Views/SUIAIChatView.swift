//
//  SUIAIChatView.swift
//  Munger
//
//  Created by Paul Nguyen on 2/6/25.
//

import SwiftUI

struct SUIAIChatView: View {
    @EnvironmentObject var viewModel: AIChatViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedProvider: AIProvider = .openai // Default to OpenAI
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages.indices, id: \.self) { index in
                            MessageBubble(
                                message: viewModel.messages[index].content,
                                isUser: viewModel.messages[index].role == "user"
                            )
                            .id(index)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.leading)
                                Text("Thinking...")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.count - 1, anchor: .bottom)
                    }
                }
            }
            
            VStack(spacing: 0) {
                Divider()
                
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                HStack {
                    TextField("Ask about investing...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .focused($isTextFieldFocused)
                        .disabled(viewModel.isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty || viewModel.isLoading ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("AI Analysis")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Change Model", selection: $selectedProvider) {
                        Text("OpenAI").tag(AIProvider.openai)
                        Text("DeepSeek").tag(AIProvider.deepseek)
                        Text("Grok").tag(AIProvider.grok)
                    }
                    .onChange(of: selectedProvider) { newProvider in
                        viewModel.setProvider(newProvider)
                        viewModel.clearChat() // Optional: reset chat for new model
                    }
                    
                    Divider()
                    
                    Button("Clear Chat", role: .destructive) {
                        viewModel.clearChat()
                    }
                } label: {
                    Label("Change Model", systemImage: "gearshape")
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = messageText
        messageText = ""
        isTextFieldFocused = false
        viewModel.sendMessage(message)
    }
}

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 24) }
            Text(message)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isUser ? Color.blue : Color(.systemGray6))
                .foregroundColor(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .textSelection(.enabled)
            if !isUser { Spacer(minLength: 24) }
        }
        .id(UUID())
    }
}

#Preview {
    let factory = ServiceFactory()
    let coordinator = AppCoordinator(serviceFactory: factory)
    SUIAIChatView()
        .environmentObject(coordinator.aichatViewModel)
}
