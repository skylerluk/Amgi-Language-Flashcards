package import Foundation
package import AnkiKit
import AnkiClients
import AnkiServices
import AnkiBackend
import AppCore
import Dependencies

package struct MandarinStudyEntry: Codable, Sendable {
    package let word: String
    package let pinyin: String
    package let english: String
    package let example: String
    package let exampleEnglish: String
    package let usage: String
    package let prompt: String
    package let hsk: Int
    package let deck: String
}

@MainActor
package final class MandarinStudyCards {
    package static let typeName = "Amgi Mandarin Vocabulary"
    package static let productionField = "AmgiEnglishPrompt"
    @Dependency(\.notetypesClient) private var types
    @Dependency(\.noteClient) private var notes
    @Dependency(\.notesService) private var writer
    @Dependency(\.deckClient) private var decks
    @Dependency(\.collectionStore) private var store
    package init() {}

    package static func entries() throws -> [MandarinStudyEntry] {
        guard let url = Bundle.module.url(forResource: "mandarin-study", withExtension: "json") else {
            throw StudyCardError.message("The Mandarin study pack is missing. Please update Amgi.")
        }
        return try JSONDecoder().decode([MandarinStudyEntry].self, from: Data(contentsOf: url))
    }
    package static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
    package func install(profileID: String? = nil, updateSelection: Bool = true) async throws {
        let key = "mandarin.study.v1." + (profileID ?? AccountStore.shared.selectedID)
        let existingTypes = try await types.listAll()
        if let owned = existingTypes.first(where: { $0.name == Self.typeName }) {
            var type = try await types.get(owned.id)
            if type.templates.contains(where: { $0.config.aFormat.contains("{{tts zh_CN:Chinese}}") }) {
                for index in type.templates.indices {
                    type.templates[index].config.aFormat = type.templates[index].config.aFormat.replacingOccurrences(of: "{{tts zh_CN:Chinese}}", with: "")
                }
                try await types.update(type)
            }
        }
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let entries = try Self.entries()
        guard entries.count == 360 else { throw StudyCardError.message("The Mandarin pack could not be validated.") }
        let typeID: NotetypeID
        if let type = existingTypes.first(where: { $0.name == Self.typeName }) { typeID = type.id }
        else { typeID = try await types.create(Self.notetype()) }
        let names = [("hsk34", "Mandarin · HSK 3–4"), ("hsk45", "Mandarin · HSK 4–5"), ("phrases", "Mandarin · Conversation phrases")]
        var ids: [Int64] = []
        for (pack, name) in names {
            let existing = try await decks.fetchAll().first { $0.name == name }
            let id: DeckID
            if let existing { id = existing.id }
            else {
                id = try await decks.create(name).id
                let config = try await decks.getDeckConfig(id)
                try await decks.createDeckPreset(id, config, "Amgi Mandarin · " + pack, false)
                var own = try await decks.getDeckConfig(id)
                own.config.newPerDay = 100
                own.config.buryNew = true
                own.config.buryReviews = true
                own.config.buryInterdayLearning = true
                let context = try await decks.fetchDeckConfigContext(id)
                try await decks.updateDeckConfig(id, own, false, context.fsrs, context.newCardsIgnoreReviewLimit, context.applyAllParentLimits, context.fsrsHealthCheck)
            }
            ids.append(id.rawValue)
            let existingTags = Set(try await notes.searchAll("tag:amgi::mandarin::" + pack + "::*", nil).flatMap { $0.tags.split(separator: " ").map(String.init) })
            for (index, entry) in entries.filter({ $0.deck == pack }).enumerated() {
                let tag = "amgi::mandarin::\(pack)::\(index)"
                if existingTags.contains(tag) { continue }
                let service = writer
                let fields = [entry.word, entry.pinyin, entry.english, entry.example, entry.exampleEnglish, entry.usage, entry.prompt, ""].map(Self.escape)
                try await backendOffload {
                    var note = try service.newNote(typeID)
                    note.fields = fields
                    note.tags = [tag, "Mandarin"] + (entry.hsk > 0 ? ["HSK\(entry.hsk)"] : ["conversation-phrases"])
                    try service.addNote(note, id)
                }
            }
        }
        UserDefaults.standard.set(true, forKey: key)
        if updateSelection, DailyStudyBudget.shared.selectedIDs == nil { DailyStudyBudget.shared.selectedIDs = ids }
        store.apply(CollectionChanges(card: true, note: true, studyQueues: true))
    }

    package static func notetype() -> Notetype {
        let answer = "{{Chinese}}<br>{{Pinyin}}<hr>{{Meaning}}<br><br>{{Example}}<br>{{ExampleEnglish}}<br><br>{{Usage}}"
        return Notetype(name: typeName, config: .init(css: ".card {font-family: -apple-system, 'PingFang SC', sans-serif; font-size:24px; text-align:center; padding:20px;}"),
            fields: ["Chinese", "Pinyin", "Meaning", "Example", "ExampleEnglish", "Usage", "Prompt", productionField].map { .init(name: $0) },
            templates: [
                .init(name: "Chinese → English", config: .init(qFormat: "{{Chinese}}", aFormat: answer)),
                .init(name: "English → Chinese", config: .init(qFormat: "{{#AmgiEnglishPrompt}}{{AmgiEnglishPrompt}}{{/AmgiEnglishPrompt}}", aFormat: answer))
            ])
    }

    package func productionPrompt(for note: NoteRecord) async throws -> (String, Bool) {
        let type = try await types.get(note.mid)
        let fields = note.flds.components(separatedBy: "\u{1f}")
        if let i = type.fields.firstIndex(where: { $0.name == Self.productionField }), i < fields.count, !fields[i].isEmpty { return (fields[i], true) }
        if let i = type.fields.firstIndex(where: { $0.name == "Prompt" }), i < fields.count { return (fields[i], false) }
        let meaningIndex = type.fields.firstIndex { ["english", "meaning", "translation", "definition", "back"].contains($0.name.lowercased()) }
        let back = meaningIndex.flatMap { $0 < fields.count ? fields[$0] : nil } ?? fields.dropFirst().first ?? ""
        let plain = back.replacingOccurrences(of: "<br>", with: "\n").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let firstEnglish = plain.components(separatedBy: .newlines).first { !$0.isEmpty && $0.range(of: "[\\p{Han}āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]", options: .regularExpression) == nil } ?? ""
        return (firstEnglish, false)
    }

    package func enableProduction(noteID: NoteID, prompt: String) async throws {
        guard let note = try await notes.fetch(noteID) else { throw StudyCardError.message("This note no longer exists.") }
        var type = try await types.get(note.mid)
        guard type.config.kind == .normal else { throw StudyCardError.message("Reverse practice supports vocabulary and Basic notes. Cloze and image cards need their own prompts.") }
        if !type.fields.contains(where: { $0.name == Self.productionField }) {
            guard type.templates.count == 1 else { throw StudyCardError.message("This custom note already has multiple card templates. Add a reverse template in Edit Template.") }
            let front = type.templates[0].config.qFormat
            let back = type.templates[0].config.aFormat
            let answer = back.contains("{{FrontSide}}") ? back.replacingOccurrences(of: "{{FrontSide}}", with: front) : front + "<hr>" + back
            type.fields.append(.init(name: Self.productionField))
            type.templates.append(.init(name: "English → Chinese", config: .init(qFormat: "{{#AmgiEnglishPrompt}}{{AmgiEnglishPrompt}}{{/AmgiEnglishPrompt}}", aFormat: answer)))
            try await types.update(type)
        }
        guard var fresh = try await notes.fetch(noteID), let index = type.fields.firstIndex(where: { $0.name == Self.productionField }) else { return }
        var fields = fresh.flds.components(separatedBy: "\u{1f}")
        while fields.count < type.fields.count { fields.append("") }
        fields[index] = Self.escape(prompt.trimmingCharacters(in: .whitespacesAndNewlines))
        fresh.flds = fields.joined(separator: "\u{1f}")
        try await notes.save(fresh)
        store.apply(CollectionChanges(card: true, note: true, studyQueues: true))
    }
}

package enum StudyCardError: LocalizedError {
    case message(String)
    package var errorDescription: String? { switch self { case .message(let text): return text } }
}
