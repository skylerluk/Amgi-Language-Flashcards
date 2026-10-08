//
//  Conversation.swift
//  ReaderFeature
//

import Foundation

/// A short bundled dialogue for listening and reading practice.
struct Conversation: Identifiable, Hashable, Sendable {
    enum Level: String, CaseIterable, Sendable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }

    struct Speaker: Hashable, Sendable {
        enum Gender: Sendable { case female, male }
        let name: String
        let gender: Gender
    }

    struct Line: Identifiable, Hashable, Sendable {
        let id: Int
        let speaker: Int
        let text: String
        let translation: String

        /// Positional init for terse content tables; `id` is assigned by
        /// `Conversation.init` from the line's position.
        init(_ speaker: Int, _ text: String, _ translation: String) {
            self.id = 0
            self.speaker = speaker
            self.text = text
            self.translation = translation
        }

        fileprivate init(id: Int, copying line: Line) {
            self.id = id
            self.speaker = line.speaker
            self.text = line.text
            self.translation = line.translation
        }
    }

    let id: String
    let title: String
    let englishTitle: String
    let symbol: String
    let level: Level
    /// BCP-47 tag the speech voices are chosen for.
    let language: String
    let speakers: [Speaker]
    let lines: [Line]

    init(
        id: String,
        title: String,
        englishTitle: String,
        symbol: String,
        level: Level,
        language: String = "es-MX",
        speakers: [Speaker],
        lines: [Line]
    ) {
        self.id = id
        self.title = title
        self.englishTitle = englishTitle
        self.symbol = symbol
        self.level = level
        self.language = language
        self.speakers = speakers
        self.lines = lines.enumerated().map { Line(id: $0.offset, copying: $0.element) }
    }

    func speaker(for line: Line) -> Speaker? {
        speakers.indices.contains(line.speaker) ? speakers[line.speaker] : nil
    }
}
