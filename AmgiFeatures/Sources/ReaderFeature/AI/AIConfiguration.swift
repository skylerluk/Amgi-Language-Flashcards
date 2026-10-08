//
//  AIConfiguration.swift
//  ReaderFeature
//
//  API keys live in the Keychain (this device only, never in source or the
//  synced collection); model ids live in UserDefaults so they can be changed
//  without an app update when a provider retires a model.
//

import Foundation
import Security

enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    /// DeepSeek through OpenRouter — word explanations and generating conversations.
    case openRouter
    /// Groq — the low-latency conversation tutor.
    case groq

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openRouter: "OpenRouter (DeepSeek)"
        case .groq: "Groq (Tutor)"
        }
    }

    var baseURL: URL {
        switch self {
        case .openRouter: URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        case .groq: URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        }
    }

    var defaultModel: String {
        switch self {
        case .openRouter: "deepseek/deepseek-v4-flash"
        case .groq: "openai/gpt-oss-120b"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .openRouter: "sk-or-…"
        case .groq: "gsk_…"
        }
    }

    var keySignupURL: URL {
        switch self {
        case .openRouter: URL(string: "https://openrouter.ai/keys")!
        case .groq: URL(string: "https://console.groq.com/keys")!
        }
    }

    private var modelDefaultsKey: String { "ai.model.\(rawValue)" }

    var model: String {
        get {
            let stored = UserDefaults.standard.string(forKey: modelDefaultsKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (stored?.isEmpty == false ? stored : nil) ?? defaultModel
        }
        nonmutating set {
            UserDefaults.standard.set(newValue, forKey: modelDefaultsKey)
        }
    }

    /// A key pasted in the app wins; otherwise the build's bundled default
    /// from the gitignored `AIKeys.local.plist`, if this build has one.
    var apiKey: String? {
        if let saved = AIKeychain.load(self), !saved.isEmpty { return saved }
        return bundledKey
    }

    private var bundledKey: String? { AIKeychain.bundledValue(for: plistKey) }

    private var plistKey: String {
        switch self {
        case .openRouter: "OpenRouter"
        case .groq: "Groq"
        }
    }

    var endpoint: ChatEndpoint? {
        guard let key = apiKey, !key.isEmpty else { return nil }
        return ChatEndpoint(provider: self, url: baseURL, apiKey: key, model: model)
    }
}

enum AIKeychain {
    private static let service = "com.skylerluk.amgi.ai"

    static func load(_ provider: AIProvider) -> String? {
        loadRaw(account: provider.rawValue)
    }

    static func save(_ key: String, for provider: AIProvider) {
        saveRaw(key, account: provider.rawValue)
    }

    static func delete(_ provider: AIProvider) {
        deleteRaw(account: provider.rawValue)
    }

    /// A value from the build's gitignored `AIKeys.local.plist`, if present
    /// and not still the placeholder.
    static func bundledValue(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "AIKeys.local", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: String],
              let value = dict[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty, !value.hasPrefix("PASTE")
        else { return nil }
        return value
    }

    static func loadRaw(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func saveRaw(_ key: String, account: String) {
        deleteRaw(account: account)
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(trimmed.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func deleteRaw(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
