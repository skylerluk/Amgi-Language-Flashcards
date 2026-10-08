//
//  TutorView.swift
//  ReaderFeature
//
//  "Profe": a topic-based Spanish conversation tutor on Groq. Each turn the
//  model returns JSON with the Spanish reply, its English, a correction of
//  the learner's last message and a hint for what to say next.
//

import SwiftUI
import Theme

@Observable
@MainActor
final class TutorModel {
    struct Message: Identifiable {
        let id: Int
        let isUser: Bool
        let text: String
        var english = ""
        var correction = ""
        var hint = ""
        /// The model's raw JSON, replayed as history so it keeps its format.
        var raw = ""
    }

    var topic = ""
    var level: Conversation.Level = .beginner
    private(set) var isStarted = false
    private(set) var messages: [Message] = []
    private(set) var isThinking = false
    var errorMessage: String?

    @ObservationIgnored private var nextID = 0

    var hasKey: Bool { AIProvider.groq.endpoint != nil }

    var latestHint: String? {
        messages.last(where: { !$0.isUser })?.hint.nilIfEmpty
    }

    func start() async {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        topic = trimmed
        messages = []
        isStarted = true
        await requestReply()
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(Message(id: makeID(), isUser: true, text: trimmed))
        await requestReply()
    }

    func retry() async {
        await requestReply()
    }

    func reset() {
        isStarted = false
        messages = []
        errorMessage = nil
    }

    private func requestReply() async {
        guard let endpoint = AIProvider.groq.endpoint else {
            errorMessage = ChatClientError.missingKey(.groq).errorDescription
            return
        }
        errorMessage = nil
        isThinking = true
        defer { isThinking = false }

        var history = [
            ChatMessage(role: .system, content: AIPrompts.tutorSystem(topic: topic, level: level)),
            ChatMessage(role: .user, content: AIPrompts.tutorOpening),
        ]
        for message in messages {
            history.append(message.isUser
                ? ChatMessage(role: .user, content: message.text)
                : ChatMessage(role: .assistant, content: message.raw))
        }

        do {
            let raw = try await ChatClient.complete(endpoint, messages: history, json: true, temperature: 0.7)
            messages.append(Self.parse(raw, id: makeID()))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makeID() -> Int {
        nextID += 1
        return nextID
    }

    private struct Turn: Decodable {
        let reply: String
        let english: String?
        let correction: String?
        let hint: String?
    }

    /// Falls back to treating the whole response as the reply if the model
    /// ignored the JSON instruction, so a turn is never lost.
    static func parse(_ raw: String, id: Int) -> Message {
        var json = raw
        if let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") {
            json = String(raw[start...end])
        }
        guard let data = json.data(using: .utf8),
              let turn = try? JSONDecoder().decode(Turn.self, from: data) else {
            return Message(id: id, isUser: false, text: raw, raw: raw)
        }
        return Message(
            id: id,
            isUser: false,
            text: turn.reply,
            english: turn.english ?? "",
            correction: turn.correction ?? "",
            hint: turn.hint ?? "",
            raw: json
        )
    }
}

private extension String {
    var nilIfEmpty: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}

/// The Tutor half of the Read tab: pick a topic and level, then chat.
struct TutorView: View {
    @Environment(\.palette) private var palette
    @State private var model = TutorModel()
    @State private var speaker = ConversationSpeaker()
    @State private var draft = ""
    @State private var revealed: Set<Int> = []
    @State private var showHint = false
    @State private var showKeys = false
    @AppStorage("tutor.autoSpeak") private var autoSpeak = true

    var body: some View {
        Group {
            if model.isStarted {
                chat
            } else {
                setup
            }
        }
        .navigationTitle(model.isStarted ? model.topic : "Tutor")
        .navigationBarTitleDisplayMode(model.isStarted ? .inline : .large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if model.isStarted {
                    Button {
                        autoSpeak.toggle()
                        if !autoSpeak { speaker.stop() }
                    } label: {
                        Label(
                            autoSpeak ? "Auto-play on" : "Auto-play off",
                            systemImage: autoSpeak ? "speaker.wave.2.fill" : "speaker.slash"
                        )
                    }
                    Button("New Topic", systemImage: "arrow.counterclockwise") {
                        speaker.stop()
                        model.reset()
                        revealed = []
                    }
                }
                Button("AI Keys", systemImage: "key") { showKeys = true }
            }
        }
        .sheet(isPresented: $showKeys) { AIKeysView() }
        .onChange(of: model.messages.count) {
            showHint = false
            guard autoSpeak, let last = model.messages.last, !last.isUser else { return }
            speaker.speak(text: last.text, id: last.id)
        }
        .onDisappear { speaker.stop() }
    }

    // MARK: - Setup

    private var setup: some View {
        Form {
            Section {
                Text("Practice speaking with Profe, an AI tutor. Pick a topic — Profe keeps the conversation going, corrects your Spanish and gives hints when you're stuck.")
                    .amgiFont(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
            Section("Topic") {
                TextField("What do you want to talk about?", text: $model.topic, axis: .vertical)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(AIPrompts.tutorTopicSuggestions, id: \.self) { idea in
                            Button(idea) { model.topic = idea }
                                .buttonStyle(.bordered)
                                .amgiFont(.caption)
                        }
                    }
                }
            }
            Section("Level") {
                Picker("Level", selection: $model.level) {
                    ForEach(Conversation.Level.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section {
                if model.hasKey {
                    Button("Start Conversation") { Task { await model.start() } }
                        .disabled(model.topic.trimmingCharacters(in: .whitespaces).isEmpty)
                } else {
                    Button("Add Groq key to start") { showKeys = true }
                }
            }
        }
    }

    // MARK: - Chat

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.messages) { message in
                        messageView(message).id(message.id)
                    }
                    if model.isThinking {
                        HStack {
                            ProgressView()
                            Text("Profe is typing…")
                                .amgiFont(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("thinking")
                    }
                    if let error = model.errorMessage {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .amgiFont(.caption)
                                .foregroundStyle(palette.danger)
                            Button("Try again") { Task { await model.retry() } }
                                .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
            .onChange(of: model.messages.count) {
                withAnimation { proxy.scrollTo(model.messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: model.isThinking) {
                if model.isThinking { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
            }
        }
        .background(palette.background)
        .safeAreaInset(edge: .bottom) { inputBar }
    }

    @ViewBuilder
    private func messageView(_ message: TutorModel.Message) -> some View {
        if message.isUser {
            Text(message.text)
                .amgiFont(.body)
                .foregroundStyle(palette.textPrimary)
                .padding(12)
                .background(palette.accentSoft, in: .rect(cornerRadius: 16))
                .frame(maxWidth: 320, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if !message.correction.isEmpty {
                    Label {
                        Text(message.correction)
                            .amgiFont(.caption)
                            .foregroundStyle(palette.textPrimary)
                    } icon: {
                        Image(systemName: "pencil.line")
                            .foregroundStyle(palette.warning)
                    }
                    .padding(10)
                    .background(palette.warning.opacity(0.12), in: .rect(cornerRadius: 12))
                }
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.text)
                            .amgiFont(.body)
                            .foregroundStyle(palette.textPrimary)
                            .textSelection(.enabled)
                        if revealed.contains(message.id), !message.english.isEmpty {
                            Text(message.english)
                                .amgiFont(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        if speaker.speakingLineID == message.id {
                            speaker.stop()
                        } else {
                            speaker.speak(text: message.text, id: message.id)
                        }
                    } label: {
                        Image(systemName: speaker.speakingLineID == message.id ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .symbolEffect(.variableColor.iterative, isActive: speaker.speakingLineID == message.id)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(palette.accent)
                    .accessibilityLabel("Listen")
                }
                .padding(12)
                .background(palette.surfaceElevated, in: .rect(cornerRadius: 16))
                .contentShape(.rect(cornerRadius: 16))
                .onTapGesture {
                    withAnimation(.snappy) {
                        if revealed.contains(message.id) { revealed.remove(message.id) } else { revealed.insert(message.id) }
                    }
                }
            }
            .frame(maxWidth: 340, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showHint, let hint = model.latestHint {
                Label(hint, systemImage: "lightbulb")
                    .amgiFont(.caption)
                    .foregroundStyle(palette.textPrimary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.accentSoft, in: .rect(cornerRadius: 12))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy) { showHint.toggle() }
                } label: {
                    Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                }
                .font(.title3)
                .disabled(model.latestHint == nil)
                .accessibilityLabel("Hint")

                TextField("Responde en español…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit(send)

                Button("Send", systemImage: "arrow.up.circle.fill", action: send)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(model.isThinking || draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        let text = draft
        draft = ""
        speaker.stop()
        Task { await model.send(text) }
    }
}
