//
//  ConversationMarkdown.swift
//  ReaderFeature
//
//  The plain-text file format for importable conversations:
//
//      ---
//      title: En la cafetería
//      english: At the coffee shop
//      level: beginner            (beginner | intermediate | advanced)
//      language: es-MX            (optional, defaults to es-MX)
//      ---
//
//      **Barista (m):** Buenos días. ¿Qué le sirvo?
//      > Good morning. What can I get you?
//
//      **Sofía (f):** Un café con leche, por favor.
//      > A coffee with milk, please.
//
//  Each line is a bold speaker name, then the text; the `>` quote under it is
//  the English. `(f)`/`(m)` picks the voice and only needs to appear on a
//  speaker's first line. The front matter is optional — a file with only
//  lines takes its title from the filename.
//

import Foundation

enum ConversationMarkdown {
    enum ParseError: Error, LocalizedError {
        case noLines

        var errorDescription: String? {
            "No dialogue lines found. Each line should look like **Name:** text"
        }
    }

    static func parse(_ text: String, id: String, fallbackTitle: String) throws -> Conversation {
        var meta: [String: String] = [:]
        var body = Substring(text)

        // Front matter between leading `---` fences.
        let trimmedStart = text.drop { $0.isWhitespace }
        if trimmedStart.hasPrefix("---") {
            let afterOpen = trimmedStart.dropFirst(3)
            if let close = afterOpen.range(of: "\n---") {
                for raw in afterOpen[..<close.lowerBound].split(separator: "\n") {
                    guard let colon = raw.firstIndex(of: ":") else { continue }
                    let key = raw[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
                    let value = raw[raw.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                    meta[key] = value
                }
                body = afterOpen[close.upperBound...]
            }
        }

        var speakers: [Conversation.Speaker] = []
        var lines: [Conversation.Line] = []
        var pendingText: (speaker: Int, text: String)?
        var pendingTranslation: [String] = []

        func flush() {
            guard let pending = pendingText else { return }
            lines.append(.init(pending.speaker, pending.text, pendingTranslation.joined(separator: " ")))
            pendingText = nil
            pendingTranslation = []
        }

        for rawLine in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix(">") {
                let translation = line.drop { $0 == ">" || $0 == " " }
                if pendingText != nil, !translation.isEmpty {
                    pendingTranslation.append(String(translation))
                }
                continue
            }
            guard let (name, gender, spoken) = speakerLine(line) else { continue }
            flush()
            let index: Int
            if let existing = speakers.firstIndex(where: { $0.name == name }) {
                index = existing
            } else {
                // Without an explicit (f)/(m), alternate voices by order.
                let resolved = gender ?? (speakers.count.isMultiple(of: 2) ? .female : .male)
                speakers.append(.init(name: name, gender: resolved))
                index = speakers.count - 1
            }
            pendingText = (index, spoken)
        }
        flush()

        guard !lines.isEmpty else { throw ParseError.noLines }

        let level = Conversation.Level.allCases.first {
            $0.rawValue.lowercased() == meta["level"]?.lowercased()
        } ?? .beginner

        return Conversation(
            id: id,
            title: meta["title"].flatMap { $0.isEmpty ? nil : $0 } ?? fallbackTitle,
            englishTitle: meta["english"] ?? meta["subtitle"] ?? "",
            symbol: meta["symbol"] ?? "text.bubble",
            level: level,
            language: meta["language"] ?? "es-MX",
            speakers: speakers,
            lines: lines
        )
    }

    /// `**Name (f):** text`, `**Name:** text` or `**Name**: text`.
    private static func speakerLine(_ line: String) -> (String, Conversation.Speaker.Gender?, String)? {
        guard line.hasPrefix("**") else { return nil }
        let rest = line.dropFirst(2)
        guard let close = rest.range(of: "**") else { return nil }
        var name = rest[..<close.lowerBound].trimmingCharacters(in: .whitespaces)
        var spoken = rest[close.upperBound...].trimmingCharacters(in: .whitespaces)
        if name.hasSuffix(":") { name.removeLast() }
        if spoken.hasPrefix(":") { spoken = spoken.dropFirst().trimmingCharacters(in: .whitespaces) }

        var gender: Conversation.Speaker.Gender?
        let lowered = name.lowercased()
        if lowered.hasSuffix("(f)") {
            gender = .female
        } else if lowered.hasSuffix("(m)") {
            gender = .male
        }
        if gender != nil {
            name = String(name.dropLast(3)).trimmingCharacters(in: .whitespaces)
        }
        guard !name.isEmpty, !spoken.isEmpty else { return nil }
        return (name, gender, spoken)
    }

    /// Serialises back to the same format — used for AI-generated
    /// conversations so they are saved exactly like imported files.
    static func serialize(_ conversation: Conversation) -> String {
        var out = """
        ---
        title: \(conversation.title)
        english: \(conversation.englishTitle)
        level: \(conversation.level.rawValue.lowercased())
        language: \(conversation.language)
        ---

        """
        var introduced = Set<Int>()
        for line in conversation.lines {
            guard let speaker = conversation.speaker(for: line) else { continue }
            var name = speaker.name
            if introduced.insert(line.speaker).inserted {
                name += speaker.gender == .female ? " (f)" : " (m)"
            }
            out += "\n**\(name):** \(line.text)\n"
            if !line.translation.isEmpty { out += "> \(line.translation)\n" }
        }
        return out
    }
}
