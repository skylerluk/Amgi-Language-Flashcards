//
//  ElevenLabs.swift
//  ReaderFeature
//
//  Optional premium voices. Nothing calls ElevenLabs unless the user taps
//  "Generate" on a specific conversation, and each line is synthesised once
//  and cached on device, so replays and flashcards cost no credits.
//

import Foundation
import Security
import CryptoKit

enum ElevenLabs {
    enum Quality: String, CaseIterable, Identifiable, Sendable {
        /// Most natural voice; ~1 credit per character.
        case best
        /// Half the credits; still far better than the system voice.
        case saver

        var id: String { rawValue }

        var model: String {
            switch self {
            case .best: "eleven_v4"
            case .saver: "eleven_v4_turbo"
            }
        }

        var label: String {
            switch self {
            case .best: "Best quality"
            case .saver: "Credit saver"
            }
        }

        var creditsPerCharacter: Double {
            switch self {
            case .best: 1
            case .saver: 0.5
            }
        }
    }

    struct Voice: Identifiable, Hashable, Sendable {
        let id: String
        let name: String
        let gender: String?
        let accent: String?
        let language: String?
        /// "premade", "professional", "cloned", … Free plans may only use
        /// premade voices through the API.
        let category: String?

        var isPremade: Bool { category == nil || category == "premade" }

        var detail: String {
            [gender, accent, language].compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: " · ")
        }
    }

    struct Usage: Sendable {
        let used: Int
        let limit: Int
        let tier: String
        var isFree: Bool { tier == "free" }
        var remaining: Int { max(0, limit - used) }
    }

    enum Failure: LocalizedError {
        case missingKey
        case http(Int, String)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                "Add your ElevenLabs API key in AI Keys first."
            case .http(401, _):
                "ElevenLabs rejected the API key (401). Check it in AI Keys, and that it has Text to Speech permission."
            case .http(let status, let message):
                "ElevenLabs request failed (\(status)): \(message)"
            }
        }
    }

    // MARK: - Settings

    static var apiKey: String? {
        if let saved = AIKeychain.loadRaw(account: "elevenlabs"), !saved.isEmpty { return saved }
        return AIKeychain.bundledValue(for: "ElevenLabs")
    }

    static func saveAPIKey(_ key: String) {
        AIKeychain.saveRaw(key, account: "elevenlabs")
    }

    /// The voice used for female / male speakers, chosen once in the
    /// premium-voice sheet and reused for every conversation.
    static func voiceID(for gender: Conversation.Speaker.Gender, language: String = "es-MX") -> String? {
        let suffix = gender == .female ? "f" : "m"
        return UserDefaults.standard.string(forKey: "elevenlabs.voice.\(language).\(suffix)")
            ?? (language == "es-MX" ? UserDefaults.standard.string(forKey: "elevenlabs.voice.\(suffix)") : nil)
    }

    static func setVoiceID(_ id: String, for gender: Conversation.Speaker.Gender, language: String = "es-MX") {
        UserDefaults.standard.set(id, forKey: "elevenlabs.voice.\(language).\(gender == .female ? "f" : "m")")
    }

    static var quality: Quality {
        get { Quality(rawValue: UserDefaults.standard.string(forKey: "elevenlabs.quality") ?? "") ?? .saver }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "elevenlabs.quality") }
    }

    static func quality(for language: String) -> Quality {
        Quality(rawValue: UserDefaults.standard.string(forKey: "elevenlabs.quality." + language) ?? "")
            ?? (language == "es-MX" ? quality : .saver)
    }

    static func setQuality(_ quality: Quality, language: String) {
        UserDefaults.standard.set(quality.rawValue, forKey: "elevenlabs.quality." + language)
    }

    // MARK: - API

    private static let base = URL(string: "https://api.elevenlabs.io")!

    static func voices() async throws -> [Voice] {
        let data = try await get("/v1/voices")
        struct Response: Decodable {
            struct Item: Decodable {
                let voice_id: String
                let name: String
                let labels: [String: String]?
                let category: String?
            }
            let voices: [Item]
        }
        return try JSONDecoder().decode(Response.self, from: data).voices.map {
            Voice(
                id: $0.voice_id,
                name: $0.name,
                gender: $0.labels?["gender"],
                accent: $0.labels?["accent"],
                language: $0.labels?["language"],
                category: $0.category
            )
        }
    }

    static func usage() async throws -> Usage {
        let data = try await get("/v1/user/subscription")
        struct Response: Decodable {
            let character_count: Int
            let character_limit: Int
            let tier: String?
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return Usage(used: decoded.character_count, limit: decoded.character_limit, tier: decoded.tier ?? "")
    }

    /// Returns MP3 audio for `text`.
    static func synthesize(_ text: String, voiceID: String, quality: Quality, language: String = "es-MX", slow: Bool = false) async throws -> Data {
        guard let key = apiKey else { throw Failure.missingKey }
        var components = URLComponents(url: base.appendingPathComponent("/v1/text-to-speech/\(voiceID)"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "output_format", value: "mp3_44100_128")]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "text": text,
            "language_code": String(language.prefix(2)),
            "model_id": quality.model,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                // Slightly unhurried by default: this is for learners.
                "speed": slow ? 0.8 : 0.95,
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200, !data.isEmpty else { throw Failure.http(status, message(from: data)) }
        return data
    }

    private static func get(_ path: String) async throws -> Data {
        guard let key = apiKey else { throw Failure.missingKey }
        var request = URLRequest(url: base.appendingPathComponent(path))
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw Failure.http(status, message(from: data)) }
        return data
    }

    private static func message(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let detail = object["detail"] as? [String: Any], let message = detail["message"] as? String {
                return message
            }
            if let detail = object["detail"] as? String { return detail }
        }
        return String(data: data.prefix(200), encoding: .utf8) ?? "Unknown error"
    }
}

/// Generated premium audio, one MP3 per line, in
/// `Library/Application Support/ConversationAudio/<conversation>/<line>.mp3`.
enum ConversationAudioCache {
    static func directory(for conversation: Conversation) -> URL {
        let safe = conversation.id.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" }
        return URL.applicationSupportDirectory
            .appendingPathComponent("ConversationAudio", isDirectory: true)
            .appendingPathComponent(String(safe), isDirectory: true)
    }

    static func url(for line: Conversation.Line, in conversation: Conversation) -> URL {
        let voice = ElevenLabs.voiceID(for: conversation.speaker(for: line)?.gender ?? .female, language: conversation.language) ?? "system"
        let identity = "\(conversation.language)|\(line.text)|\(voice)|\(ElevenLabs.quality(for: conversation.language).model)"
        let hash = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory(for: conversation).appendingPathComponent("\(line.id)-\(hash).mp3")
    }

    static func cachedURL(for line: Conversation.Line, in conversation: Conversation) -> URL? {
        let url = url(for: line, in: conversation)
        // One-time migration preserves previously generated Spanish recordings.
        // Moving (not copying) ensures a subsequent voice change cannot revive old audio.
        let legacy = directory(for: conversation).appendingPathComponent("\(line.id).mp3")
        if !FileManager.default.fileExists(atPath: url.path), conversation.language == "es-MX",
           FileManager.default.fileExists(atPath: legacy.path) {
            try? FileManager.default.moveItem(at: legacy, to: url)
        }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func cachedCount(_ conversation: Conversation) -> Int {
        conversation.lines.filter { cachedURL(for: $0, in: conversation) != nil }.count
    }

    static func isComplete(_ conversation: Conversation) -> Bool {
        cachedCount(conversation) == conversation.lines.count
    }

    static func save(_ data: Data, for line: Conversation.Line, in conversation: Conversation) throws {
        try FileManager.default.createDirectory(at: directory(for: conversation), withIntermediateDirectories: true)
        try data.write(to: url(for: line, in: conversation), options: .atomic)
    }

    static func remove(_ conversation: Conversation) {
        try? FileManager.default.removeItem(at: directory(for: conversation))
    }

    /// Characters still to generate — what ElevenLabs bills on.
    static func pendingCharacters(_ conversation: Conversation) -> Int {
        conversation.lines
            .filter { cachedURL(for: $0, in: conversation) == nil }
            .reduce(0) { $0 + $1.text.count }
    }
}
