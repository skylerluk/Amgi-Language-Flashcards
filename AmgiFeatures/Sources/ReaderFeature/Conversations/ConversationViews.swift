//
//  ConversationViews.swift
//  ReaderFeature
//

import AnkiKit
package import Foundation
import BrowseFeature
package import SwiftUI
import Theme
import Translation
import UniformTypeIdentifiers

// MARK: - List

/// The Conversations half of the Read tab: the user's imported and generated
/// conversations first, then the bundled dialogues grouped by level.
struct ConversationListView: View {
    @Environment(\.palette) private var palette
    let conversations: [Conversation]

    @State private var store = ConversationStore.shared
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var showGenerator = false
    @State private var showKeys = false

    private static let importTypes: [UTType] = [
        .zip, .plainText,
        UTType(filenameExtension: "md") ?? .plainText,
        UTType("net.daringfireball.markdown") ?? .plainText,
    ]

    var body: some View {
        List {
            Section {
                if store.imported.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add your own conversations")
                            .amgiFont(.bodyEmphasis)
                            .foregroundStyle(palette.textPrimary)
                        Text("Import .md files or a .zip of them, or generate a new one with DeepSeek using the + button.")
                            .amgiFont(.caption)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(store.imported) { conversation in
                        NavigationLink(value: conversation) {
                            row(conversation)
                        }
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                store.delete(conversation)
                            }
                        }
                    }
                }
            } header: {
                Text("Your conversations")
            }

            ForEach(Conversation.spanishSections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.conversations) { conversation in
                        NavigationLink(value: conversation) {
                            row(conversation)
                        }
                    }
                }
            }

            ForEach(Conversation.Level.allCases, id: \.self) { level in
                let items = conversations.filter { $0.level == level }
                if !items.isEmpty {
                    Section(level.rawValue) {
                        ForEach(items) { conversation in
                            NavigationLink(value: conversation) {
                                row(conversation)
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Conversation.self) { conversation in
            ConversationDetailView(conversation: conversation)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Import Files…", systemImage: "square.and.arrow.down") {
                        isImporting = true
                    }
                    Button("Generate with DeepSeek…", systemImage: "sparkles") {
                        showGenerator = true
                    }
                    Divider()
                    Button("AI Keys…", systemImage: "key") {
                        showKeys = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: Self.importTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                importMessage = store.importFiles(urls).summary
            case .failure(let error):
                importMessage = error.localizedDescription
            }
        }
        .alert(
            "Import",
            isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })
        ) {
            Button("OK") { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
        }
        .sheet(isPresented: $showGenerator) { GenerateConversationView() }
        .sheet(isPresented: $showKeys) { AIKeysView() }
    }

    private func row(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            Image(systemName: conversation.symbol)
                .font(.title3)
                .foregroundStyle(palette.accent)
                .frame(width: 36, height: 36)
                .background(palette.accentSoft, in: .rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .amgiFont(.bodyEmphasis)
                    .foregroundStyle(palette.textPrimary)
                Text("\(conversation.englishTitle) · \(conversation.lines.count) lines")
                    .amgiFont(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail

/// One dialogue as chat bubbles. Tap a bubble to reveal its English; tap the
/// speaker icon to hear it; "+" turns the line into a flashcard with the
/// Spanish, the English and the spoken audio already filled in.
struct ConversationDetailView: View {
    @Environment(\.palette) private var palette
    let conversation: Conversation

    @State private var speaker = ConversationSpeaker()
    @State private var revealed: Set<Int> = []
    @State private var showAllTranslations = false
    @State private var cardDraft: DraftItem?
    @State private var preparingCardLine: Int?
    @State private var translationText = ""
    @State private var showTranslation = false
    @State private var askAI: AskItem?
    @State private var showPremiumVoice = false
    @State private var hasPremiumAudio = false

    struct AskItem: Identifiable {
        let id = UUID()
        let question: String?
    }

    struct DraftItem: Identifiable {
        let id = UUID()
        let draft: AddNoteDraft
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text(conversation.title)
                            .amgiFont(.cardTitle)
                            .foregroundStyle(palette.textPrimary)
                        if !conversation.englishTitle.isEmpty {
                            Text(conversation.englishTitle)
                                .amgiFont(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                        if hasPremiumAudio {
                            Label("Premium voice", systemImage: "waveform")
                                .amgiFont(.micro)
                                .foregroundStyle(palette.accent)
                        }
                        Text("Tap a line for English · hold a word to translate or ask DeepSeek")
                            .amgiFont(.micro)
                            .foregroundStyle(palette.textTertiary)
                            .padding(.top, 4)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                    ForEach(conversation.lines) { line in
                        bubble(line).id(line.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: speaker.speakingLineID) { _, id in
                guard speaker.isPlayingAll, let id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .background(palette.background)
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .onDisappear { speaker.stop() }
        .sheet(item: $cardDraft) { item in
            AddNoteView(initialDraft: item.draft, keepsOpenAfterAdd: false) {}
        }
        .sheet(item: $askAI) { item in
            AskAIView(conversation: conversation, initialQuestion: item.question)
                .presentationDetents([.medium, .large])
        }
        .translationPresentation(isPresented: $showTranslation, text: translationText)
        .sheet(isPresented: $showPremiumVoice) {
            PremiumVoiceView(conversation: conversation) { refreshPremium() }
        }
        .onAppear(perform: refreshPremium)
    }

    private func refreshPremium() {
        hasPremiumAudio = ConversationAudioCache.cachedCount(conversation) > 0
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                askAI = AskItem(question: nil)
            } label: {
                Label("Ask DeepSeek", systemImage: "sparkles")
            }
            Button {
                showAllTranslations.toggle()
                revealed = []
            } label: {
                Label(
                    showAllTranslations ? "Hide translations" : "Show translations",
                    systemImage: showAllTranslations ? "character.bubble.fill" : "character.bubble"
                )
            }
            Button {
                if speaker.isPlayingAll { speaker.stop() } else { speaker.playAll(conversation) }
            } label: {
                Label(
                    speaker.isPlayingAll ? "Stop" : "Play all",
                    systemImage: speaker.isPlayingAll ? "stop.fill" : "play.fill"
                )
            }
            Menu {
                Toggle(isOn: $speaker.isSlow) {
                    Label("Slow speed", systemImage: "tortoise")
                }
                Button {
                    speaker.stop()
                    showPremiumVoice = true
                } label: {
                    Label(
                        hasPremiumAudio ? "Premium voice (on)" : "Premium voice…",
                        systemImage: "waveform"
                    )
                }
            } label: {
                Label("More", systemImage: "ellipsis")
            }
        }
    }

    private func isShowingTranslation(_ line: Conversation.Line) -> Bool {
        showAllTranslations != revealed.contains(line.id)
    }

    @ViewBuilder
    private func bubble(_ line: Conversation.Line) -> some View {
        let isLeading = line.speaker == 0
        let isSpeaking = speaker.speakingLineID == line.id
        let name = conversation.speaker(for: line)?.name ?? ""

        VStack(alignment: isLeading ? .leading : .trailing, spacing: 4) {
            Text(name)
                .amgiFont(.micro)
                .foregroundStyle(palette.textTertiary)
                .padding(.horizontal, 4)

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    SelectableLineText(
                        text: line.text,
                        color: UIColor(palette.textPrimary),
                        onTap: { toggleTranslation(line) },
                        onTranslate: { selection in
                            translationText = selection
                            showTranslation = true
                        },
                        onAsk: { selection in
                            askAI = AskItem(question: AIPrompts.askAboutSelection(selection, line: line.text))
                        }
                    )
                    if isShowingTranslation(line) {
                        Text(line.translation)
                            .amgiFont(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    Button {
                        if isSpeaking { speaker.stop() } else { speaker.speak(line, in: conversation) }
                    } label: {
                        Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .symbolEffect(.variableColor.iterative, isActive: isSpeaking)
                    }
                    .accessibilityLabel(isSpeaking ? "Stop" : "Listen")

                    Button {
                        Task { await makeCard(from: line) }
                    } label: {
                        if preparingCardLine == line.id {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "plus.rectangle.on.rectangle")
                        }
                    }
                    .disabled(preparingCardLine != nil)
                    .accessibilityLabel("Make a flashcard from this line")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(palette.accent)
            }
            .padding(12)
            .background(
                isLeading ? palette.surfaceElevated : palette.accentSoft,
                in: .rect(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(palette.accent, lineWidth: isSpeaking ? 2 : 0)
            }
            .contentShape(.rect(cornerRadius: 16))
            .onTapGesture { toggleTranslation(line) }
            .accessibilityAction(named: "Show translation") {
                revealed.insert(line.id)
            }
        }
        .frame(maxWidth: 320, alignment: isLeading ? .leading : .trailing)
        .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
    }

    private func toggleTranslation(_ line: Conversation.Line) {
        withAnimation(.snappy) {
            if revealed.contains(line.id) { revealed.remove(line.id) } else { revealed.insert(line.id) }
        }
    }

    /// Speaks the line into an audio file, then opens Add Card pre-filled.
    /// If rendering fails the card still opens, just without audio.
    private func makeCard(from line: Conversation.Line) async {
        preparingCardLine = line.id
        defer { preparingCardLine = nil }
        speaker.stop()
        // Prefer the premium recording; copy it, because Add Card deletes its
        // attachments once they're saved or discarded.
        var audio: URL?
        if let cached = ConversationAudioCache.cachedURL(for: line, in: conversation) {
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent("amgi-el-\(UUID().uuidString.prefix(8)).mp3")
            if (try? FileManager.default.copyItem(at: cached, to: copy)) != nil { audio = copy }
        }
        if audio == nil {
            audio = try? await SpeechFileRenderer.render(speaker.utterance(for: line, in: conversation))
        }
        cardDraft = DraftItem(draft: AddNoteDraft(
            fieldValues: ["Front": line.text, "Back": line.translation],
            tags: ["conversation", "spanish"],
            audioFiles: audio.map { ["Front": [$0]] } ?? [:]
        ))
    }
}

// MARK: - Read tab container

/// The Read tab: Books (EPUB library), Conversations (dialogues) and Tutor
/// (AI conversation practice).
package struct ReadTabView: View {
    enum Mode: String, CaseIterable {
        case books = "Books"
        case conversations = "Conversations"
        case tutor = "Tutor"
    }

    @Environment(\.palette) private var palette
    @State private var mode: Mode = .books
    private let refreshID: UUID?

    package init(refreshID: UUID? = nil) {
        self.refreshID = refreshID
    }

    package var body: some View {
        Group {
            switch mode {
            case .books:
                ReaderLibraryView(refreshID: refreshID)
            case .conversations:
                ConversationListView(conversations: Conversation.spanish)
                    .navigationTitle("Conversations")
                    .navigationBarTitleDisplayMode(.large)
            case .tutor:
                TutorView()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("Read", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}
