//
//  PremiumVoiceView.swift
//  ReaderFeature
//

import SwiftUI
import Theme

/// Upgrades one conversation to ElevenLabs voices. Shows the credit cost
/// and the account's remaining credits before anything is spent.
struct PremiumVoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette

    let conversation: Conversation
    var onChange: () -> Void

    @State private var voices: [ElevenLabs.Voice] = []
    @State private var usage: ElevenLabs.Usage?
    @State private var quality = ElevenLabs.quality
    @State private var femaleVoice = ""
    @State private var maleVoice = ""
    @State private var isLoading = true
    @State private var progress: (done: Int, total: Int)?
    @State private var errorMessage: String?
    @State private var showKeys = false
    @State private var cachedCount = 0

    private var pendingCharacters: Int { ConversationAudioCache.pendingCharacters(conversation) }
    private var isComplete: Bool { cachedCount == conversation.lines.count }
    private var neededGenders: Set<Conversation.Speaker.Gender> { Set(conversation.speakers.map(\.gender)) }

    private func credits(_ quality: ElevenLabs.Quality) -> Int {
        Int((Double(pendingCharacters) * quality.creditsPerCharacter).rounded(.up))
    }

    var body: some View {
        NavigationStack {
            Form {
                if ElevenLabs.apiKey == nil {
                    Section {
                        Text("Add your ElevenLabs API key to use premium voices.")
                        Button("Add key") { showKeys = true }
                    }
                } else {
                    statusSection
                    qualitySection.disabled(progress != nil || isLoading)
                    voicesSection.disabled(progress != nil || isLoading)
                    actionsSection
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .amgiFont(.caption)
                            .foregroundStyle(palette.danger)
                    }
                }
            }
            .navigationTitle("Premium Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .disabled(progress != nil)
                }
            }
            .interactiveDismissDisabled(progress != nil)
            .sheet(isPresented: $showKeys, onDismiss: { Task { await load() } }) { AIKeysView() }
            .task {
                quality = ElevenLabs.quality(for: conversation.language)
                femaleVoice = ElevenLabs.voiceID(for: .female, language: conversation.language) ?? ""
                maleVoice = ElevenLabs.voiceID(for: .male, language: conversation.language) ?? ""
                await load()
            }
            .onChange(of: femaleVoice) { rememberVoices() }
            .onChange(of: maleVoice) { rememberVoices() }
            .onChange(of: quality) { rememberVoices() }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section {
            if isComplete {
                Label("This conversation uses ElevenLabs voices. Replaying is free.", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(palette.positive)
            } else {
                LabeledContent("Characters to generate", value: "\(pendingCharacters)")
                if cachedCount > 0 {
                    LabeledContent("Already generated", value: "\(cachedCount) of \(conversation.lines.count) lines")
                }
            }
            if let usage {
                LabeledContent("Credits left", value: "\(usage.remaining.formatted()) of \(usage.limit.formatted())")
            } else if isLoading {
                LabeledContent("Credits left") { ProgressView() }
            }
        }
    }

    private var qualitySection: some View {
        Section {
            Picker("Quality", selection: $quality) {
                ForEach(ElevenLabs.Quality.allCases) { option in
                    Text("\(option.label) · ≈\(credits(option)) credits").tag(option)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Quality")
        } footer: {
            Text("Credit saver uses half the credits and still sounds natural. Audio is generated once and saved on this iPhone.")
        }
    }

    @ViewBuilder
    private var voicesSection: some View {
        Section {
            if isLoading && voices.isEmpty {
                ProgressView()
            } else {
                if neededGenders.contains(.female) {
                    voicePicker("Female voice", selection: $femaleVoice, gender: "female")
                }
                if neededGenders.contains(.male) {
                    voicePicker("Male voice", selection: $maleVoice, gender: "male")
                }
            }
        } header: {
            Text("Voices")
        } footer: {
            if usage?.isFree == true {
                Text("Your current plan uses built-in multilingual voices. Native Voice Library voices may require a paid plan.")
            } else {
                Text("Add voices matching this conversation’s language and region to My Voices in ElevenLabs, then reopen this screen.")
            }
        }
    }

    private func voicePicker(_ title: String, selection: Binding<String>, gender: String) -> some View {
        Picker(title, selection: selection) {
            ForEach(sortedVoices(preferring: gender)) { voice in
                VStack(alignment: .leading) {
                    Text(voice.name)
                    if !voice.detail.isEmpty {
                        Text(voice.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tag(voice.id)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var actionsSection: some View {
        Section {
            if let progress {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: Double(progress.done), total: Double(progress.total))
                    Text("Generating line \(min(progress.done + 1, progress.total)) of \(progress.total)…")
                        .amgiFont(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            } else if isComplete {
                Button("Remove premium audio", role: .destructive) {
                    ConversationAudioCache.remove(conversation)
                    refreshCount()
                    onChange()
                }
            } else {
                Button {
                    Task { await generate() }
                } label: {
                    Label("Generate · ≈\(credits(quality)) credits", systemImage: "waveform")
                }
                .disabled(!canGenerate)
            }
        }
    }

    private var canGenerate: Bool {
        guard progress == nil, !isLoading else { return false }
        if neededGenders.contains(.female), femaleVoice.isEmpty { return false }
        if neededGenders.contains(.male), maleVoice.isEmpty { return false }
        if let usage, usage.remaining < credits(quality) { return false }
        return true
    }

    // MARK: - Actions

    private func load() async {
        errorMessage = nil
        refreshCount()
        guard ElevenLabs.apiKey != nil else {
            isLoading = false
            return
        }
        isLoading = true
        defer { isLoading = false }
        async let fetchedVoices = ElevenLabs.voices()
        async let fetchedUsage = ElevenLabs.usage()
        // Usage needs the user_read permission; a key without it can still
        // generate, so this one failing quietly is fine.
        usage = try? await fetchedUsage
        do {
            var all = try await fetchedVoices
            // Library voices return 402 on the free plan — don't offer them.
            if usage?.isFree == true { all = all.filter(\.isPremade) }
            voices = all
            let ids = Set(all.map(\.id))
            if !ids.contains(femaleVoice) { femaleVoice = sortedVoices(preferring: "female").first?.id ?? "" }
            if !ids.contains(maleVoice) { maleVoice = sortedVoices(preferring: "male").first?.id ?? "" }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rememberVoices() {
        guard !isLoading, progress == nil else { return }
        ElevenLabs.setQuality(quality, language: conversation.language)
        if !femaleVoice.isEmpty { ElevenLabs.setVoiceID(femaleVoice, for: .female, language: conversation.language) }
        if !maleVoice.isEmpty { ElevenLabs.setVoiceID(maleVoice, for: .male, language: conversation.language) }
        refreshCount()
        onChange()
    }

    private func generate() async {
        ElevenLabs.setQuality(quality, language: conversation.language)
        if !femaleVoice.isEmpty { ElevenLabs.setVoiceID(femaleVoice, for: .female, language: conversation.language) }
        if !maleVoice.isEmpty { ElevenLabs.setVoiceID(maleVoice, for: .male, language: conversation.language) }
        errorMessage = nil

        let pending = conversation.lines.filter { ConversationAudioCache.cachedURL(for: $0, in: conversation) == nil }
        progress = (0, pending.count)
        defer {
            progress = nil
            refreshCount()
            onChange()
        }
        for (index, line) in pending.enumerated() {
            let gender = conversation.speaker(for: line)?.gender ?? .female
            let voice = gender == .female ? femaleVoice : maleVoice
            do {
                let audio = try await ElevenLabs.synthesize(line.text, voiceID: voice, quality: quality, language: conversation.language)
                try ConversationAudioCache.save(audio, for: line, in: conversation)
                progress = (index + 1, pending.count)
            } catch {
                // Lines already generated are kept; tapping Generate again
                // resumes with only the missing ones.
                errorMessage = error.localizedDescription
                return
            }
        }
        usage = try? await ElevenLabs.usage()
    }

    private func refreshCount() {
        cachedCount = ConversationAudioCache.cachedCount(conversation)
    }

    /// Spanish / Latin American voices of the wanted gender first.
    private func sortedVoices(preferring gender: String) -> [ElevenLabs.Voice] {
        func score(_ voice: ElevenLabs.Voice) -> Int {
            var score = 0
            if voice.gender?.lowercased() == gender { score += 4 }
            let tags = "\(voice.accent ?? "") \(voice.language ?? "") \(voice.name)".lowercased()
            if conversation.language.hasPrefix("zh") {
                if tags.contains("mandarin") || tags.contains("chinese") || voice.language == "zh" { score += 10 }
                if tags.contains("mainland") || tags.contains("standard") || tags.contains("beijing") { score += 5 }
            } else if conversation.language.hasPrefix("es") {
                if tags.contains("mex") { score += 5 }
                if tags.contains("spanish") || tags.contains("latin") || voice.language == "es" { score += 10 }
            } else if voice.language == String(conversation.language.prefix(2)) {
                score += 10
            }
            return score
        }
        return voices.sorted { score($0) > score($1) }
    }
}
