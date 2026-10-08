//
//  AskAIView.swift
//  ReaderFeature
//

import SwiftUI
import Theme

@Observable
@MainActor
final class AskAIModel {
    struct Turn: Identifiable {
        let id = UUID()
        let isUser: Bool
        var text: String
    }

    private(set) var turns: [Turn] = []
    private(set) var isStreaming = false
    var errorMessage: String?

    private let context: String
    @ObservationIgnored private var task: Task<Void, Never>?

    init(conversation: Conversation) {
        context = AIPrompts.explainerContext(conversation)
    }

    var hasKey: Bool { AIProvider.openRouter.endpoint != nil }

    func ask(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }
        guard let endpoint = AIProvider.openRouter.endpoint else {
            errorMessage = ChatClientError.missingKey(.openRouter).errorDescription
            return
        }
        errorMessage = nil
        turns.append(Turn(isUser: true, text: trimmed))
        turns.append(Turn(isUser: false, text: ""))
        let answerIndex = turns.count - 1

        var messages = [
            ChatMessage(role: .system, content: AIPrompts.explainerSystem),
            ChatMessage(role: .user, content: context),
            ChatMessage(role: .assistant, content: "Got it — I have the dialogue. What would you like to know?"),
        ]
        for turn in turns.dropLast() where !turn.text.isEmpty {
            messages.append(ChatMessage(role: turn.isUser ? .user : .assistant, content: turn.text))
        }

        isStreaming = true
        task = Task {
            do {
                for try await piece in ChatClient.stream(endpoint, messages: messages) {
                    turns[answerIndex].text += piece
                }
                if turns[answerIndex].text.isEmpty { throw ChatClientError.emptyResponse }
            } catch is CancellationError {
            } catch {
                errorMessage = error.localizedDescription
                if turns[answerIndex].text.isEmpty { turns.remove(at: answerIndex) }
            }
            isStreaming = false
        }
    }

    func cancel() {
        task?.cancel()
        isStreaming = false
    }
}

/// Chat sheet for asking DeepSeek about a conversation — opened from the
/// toolbar, or from "Ask DeepSeek" on a text selection with the question
/// already asked.
struct AskAIView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var model: AskAIModel
    @State private var draft = ""
    @State private var showKeys = false
    @FocusState private var inputFocused: Bool
    private let initialQuestion: String?

    init(conversation: Conversation, initialQuestion: String? = nil) {
        _model = State(initialValue: AskAIModel(conversation: conversation))
        self.initialQuestion = initialQuestion
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if model.turns.isEmpty {
                            suggestions
                        }
                        ForEach(model.turns) { turn in
                            turnView(turn).id(turn.id)
                        }
                        if let error = model.errorMessage {
                            errorView(error)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: model.turns.last?.text) {
                    if let last = model.turns.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .background(palette.background)
            .safeAreaInset(edge: .bottom) { inputBar }
            .navigationTitle("Ask DeepSeek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { model.cancel(); dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("AI Keys", systemImage: "key") { showKeys = true }
                }
            }
            .sheet(isPresented: $showKeys) { AIKeysView() }
            .task {
                if let initialQuestion, model.turns.isEmpty, model.hasKey {
                    model.ask(initialQuestion)
                } else if !model.hasKey {
                    showKeys = true
                }
            }
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask anything about this conversation, or select words in a line and choose Ask DeepSeek.")
                .amgiFont(.caption)
                .foregroundStyle(palette.textSecondary)
            ForEach(AIPrompts.conversationQuickQuestions, id: \.self) { question in
                Button(question) { model.ask(question) }
                    .buttonStyle(.bordered)
                    .amgiFont(.caption)
            }
        }
    }

    @ViewBuilder
    private func turnView(_ turn: AskAIModel.Turn) -> some View {
        if turn.isUser {
            Text(turn.text)
                .amgiFont(.bodyEmphasis)
                .foregroundStyle(palette.textPrimary)
                .padding(10)
                .background(palette.accentSoft, in: .rect(cornerRadius: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else if turn.text.isEmpty {
            ProgressView().padding(.vertical, 8)
        } else {
            markdownText(turn.text)
                .amgiFont(.body)
                .foregroundStyle(palette.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: "exclamationmark.triangle")
                .amgiFont(.caption)
                .foregroundStyle(palette.danger)
            if !model.hasKey {
                Button("Add OpenRouter key") { showKeys = true }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask about a word or phrase…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit(send)
            if model.isStreaming {
                Button("Stop", systemImage: "stop.circle.fill") { model.cancel() }
                    .labelStyle(.iconOnly)
                    .font(.title2)
            } else {
                Button("Send", systemImage: "arrow.up.circle.fill", action: send)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        model.ask(draft)
        draft = ""
    }
}
