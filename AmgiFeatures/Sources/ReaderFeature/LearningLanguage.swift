import Foundation
import SwiftUI

/// The learning language is shared across Books, Conversations and Tutor.
enum LearningLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case mandarin = "zh-CN"
    case spanish = "es-MX"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case french = "fr-FR"
    case german = "de-DE"
    var id: String { rawValue }
    var name: String {
        switch self {
        case .mandarin: "Mandarin · 中文"
        case .spanish: "Spanish · Español"
        case .japanese: "Japanese · 日本語"
        case .korean: "Korean · 한국어"
        case .french: "French · Français"
        case .german: "German · Deutsch"
        }
    }
    var promptName: String {
        switch self {
        case .mandarin: "mainland Mandarin Chinese, Simplified characters (zh-CN)"
        case .spanish: "Mexican Spanish (es-MX)"
        case .japanese: "standard Japanese (ja-JP)"
        case .korean: "South Korean Korean (ko-KR)"
        case .french: "French as spoken in France (fr-FR)"
        case .german: "German as spoken in Germany (de-DE)"
        }
    }
    var isChinese: Bool { self == .mandarin }
    static let preferenceKey = "reader.learningLanguage"
    static func resolve(_ tag: String) -> Self { allCases.first { tag.lowercased().hasPrefix(String($0.rawValue.prefix(2))) } ?? .spanish }
    func levelName(_ level: Conversation.Level) -> String {
        guard isChinese else { return level.rawValue }
        switch level { case .beginner: return "HSK 4"; case .intermediate: return "HSK 5"; case .advanced: return "HSK 6+" }
    }
    func matches(_ tag: String?) -> Bool {
        guard let tag, !tag.isEmpty else { return false }
        return tag.lowercased().hasPrefix(String(rawValue.prefix(2))) || tag.lowercased() == name.components(separatedBy: " · ").first?.lowercased() || (isChinese && tag.lowercased() == "chinese")
    }
    static func pinyin(_ text: String) -> String {
        text.applyingTransform(.mandarinToLatin, reverse: false) ?? text
    }
}

struct LearningLanguagePicker: View {
    @AppStorage(LearningLanguage.preferenceKey) private var language = LearningLanguage.mandarin.rawValue
    @AppStorage("reader.installedLanguages") private var installed = "zh-CN,es-MX"
    @State private var showLanguages = false
    var body: some View {
        HStack {
            Picker("Learning language", selection: $language) {
                ForEach(LearningLanguage.allCases.filter { installed.split(separator: ",").contains(Substring($0.rawValue)) }) {
                    Text($0.name).tag($0.rawValue)
                }
            }
            Spacer()
            Button("Add language", systemImage: "plus.circle") { showLanguages = true }.font(.caption)
        }
        .sheet(isPresented: $showLanguages) {
            NavigationStack {
                List {
                    Section {
                        Text("Add a language for online tutor practice and generated conversations. Import EPUBs and conversation files for reading. Mandarin and Spanish include starter conversations; Mandarin includes two books.")
                    }
                    Section("Languages") {
                        ForEach(LearningLanguage.allCases) { option in
                            Button {
                                if !installed.split(separator: ",").contains(Substring(option.rawValue)) { installed += "," + option.rawValue }
                                language = option.rawValue
                                showLanguages = false
                            } label: {
                                HStack { Text(option.name); Spacer(); if installed.contains(option.rawValue) { Image(systemName: "checkmark") } }
                            }
                        }
                    }
                    Section {
                        Text("Offline content stays on this iPhone. Tutor replies and new AI translations need internet. Download enhanced system voices in iOS Settings → Accessibility → Read & Speak or Spoken Content → Voices; dictation availability depends on your device and language.")
                    }
                }
                .navigationTitle("Languages")
                .toolbar { Button("Done") { showLanguages = false } }
            }
        }
    }
}
