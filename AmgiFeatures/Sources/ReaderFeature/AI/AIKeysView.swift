//
//  AIKeysView.swift
//  ReaderFeature
//

import SwiftUI
import Theme

/// Paste-in screen for the OpenRouter and Groq keys, plus the model ids.
struct AIKeysView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette

    @State private var keys: [AIProvider: String] = [:]
    @State private var models: [AIProvider: String] = [:]
    @State private var elevenLabsKey = ""

    var body: some View {
        NavigationStack {
            Form {
                ForEach(AIProvider.allCases) { provider in
                    Section {
                        SecureField(provider.keyPlaceholder, text: binding(for: provider, in: $keys))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Model", text: binding(for: provider, in: $models))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .amgiFont(.caption)
                            .foregroundStyle(palette.textSecondary)
                    } header: {
                        Text(provider.displayName)
                    } footer: {
                        Link("Get a key", destination: provider.keySignupURL)
                    }
                }
                Section {
                    SecureField("ElevenLabs API key", text: $elevenLabsKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("ElevenLabs (Premium voices)")
                } footer: {
                    Link("Get a key", destination: URL(string: "https://elevenlabs.io/app/settings/api-keys")!)
                }
                Section {
                    Text("Keys are stored in this iPhone's Keychain and only sent to the provider you entered them for. They are not synced or backed up.")
                        .amgiFont(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .navigationTitle("AI Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func binding(for provider: AIProvider, in dict: Binding<[AIProvider: String]>) -> Binding<String> {
        Binding(
            get: { dict.wrappedValue[provider] ?? "" },
            set: { dict.wrappedValue[provider] = $0 }
        )
    }

    private func load() {
        for provider in AIProvider.allCases {
            keys[provider] = provider.apiKey ?? ""
            models[provider] = provider.model
        }
        elevenLabsKey = ElevenLabs.apiKey ?? ""
    }

    private func save() {
        for provider in AIProvider.allCases {
            AIKeychain.save(keys[provider] ?? "", for: provider)
            provider.model = models[provider] ?? ""
        }
        ElevenLabs.saveAPIKey(elevenLabsKey)
    }
}

/// Renders the inline Markdown models return (bold, italics, code), keeping
/// line breaks so bullet lists and labelled sections stay readable.
func markdownText(_ string: String) -> Text {
    let options = AttributedString.MarkdownParsingOptions(
        interpretedSyntax: .inlineOnlyPreservingWhitespace
    )
    if let attributed = try? AttributedString(markdown: string, options: options) {
        return Text(attributed)
    }
    return Text(string)
}
