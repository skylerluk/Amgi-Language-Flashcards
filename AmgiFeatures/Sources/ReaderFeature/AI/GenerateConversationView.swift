//
//  GenerateConversationView.swift
//  ReaderFeature
//

import SwiftUI
import Theme

/// Asks DeepSeek for a new dialogue in the importable Markdown format, then
/// saves it with the user's other conversations.
struct GenerateConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette

    @State private var topic = ""
    @State private var level: Conversation.Level = .beginner
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showKeys = false

    private let ideas = [
        "At the doctor", "Buying a phone plan", "A birthday party",
        "Lost luggage at the airport", "Renting an apartment", "A job interview",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Topic") {
                    TextField("Anything — or leave empty to be surprised", text: $topic, axis: .vertical)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(ideas, id: \.self) { idea in
                                Button(idea) { topic = idea }
                                    .buttonStyle(.bordered)
                                    .amgiFont(.caption)
                            }
                        }
                    }
                }
                Section("Level") {
                    Picker("Level", selection: $level) {
                        ForEach(Conversation.Level.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .amgiFont(.caption)
                            .foregroundStyle(palette.danger)
                        if AIProvider.openRouter.endpoint == nil {
                            Button("Add OpenRouter key") { showKeys = true }
                        }
                    }
                }
            }
            .navigationTitle("New Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Button("Generate") { Task { await generate() } }
                    }
                }
            }
            .interactiveDismissDisabled(isGenerating)
            .sheet(isPresented: $showKeys) { AIKeysView() }
        }
    }

    private func generate() async {
        guard let endpoint = AIProvider.openRouter.endpoint else {
            errorMessage = ChatClientError.missingKey(.openRouter).errorDescription
            return
        }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            let raw = try await ChatClient.complete(
                endpoint,
                messages: [
                    ChatMessage(role: .system, content: AIPrompts.generatorSystem(level: level)),
                    ChatMessage(role: .user, content: AIPrompts.generatorRequest(topic: topic)),
                ],
                temperature: 0.9
            )
            let conversation = try ConversationMarkdown.parse(
                Self.stripCodeFence(raw),
                id: "generated",
                fallbackTitle: topic.isEmpty ? "Conversación" : topic
            )
            try ConversationStore.shared.add(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Models sometimes wrap the answer in ```markdown fences despite being told not to.
    static func stripCodeFence(_ text: String) -> String {
        var lines = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n")
        if lines.first?.hasPrefix("```") == true { lines.removeFirst() }
        if lines.last?.hasPrefix("```") == true { lines.removeLast() }
        return lines.joined(separator: "\n")
    }
}
