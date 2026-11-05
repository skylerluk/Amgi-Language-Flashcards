import Foundation
import Testing
import Dependencies
import AnkiBackend
import AnkiClients
import AnkiServices
import AnkiKit
import AppCore
import ReviewCore
@testable import AppShared

@Suite @MainActor struct MandarinStudyCardTests {
    @Test func packsAreCompleteAndVocabularyDoesNotOverlap() throws {
        let entries = try MandarinStudyCards.entries()
        for (deck, count) in [("hsk34", 150), ("hsk45", 150), ("phrases", 60)] {
            #expect(entries.filter { $0.deck == deck }.count == count)
        }
        #expect(Set(entries.filter { $0.deck != "phrases" }.map(\.word)).count == 300)
        #expect(entries.allSatisfy { !$0.example.isEmpty && !$0.prompt.isEmpty && !$0.pinyin.isEmpty && !$0.usage.isEmpty })
    }

    @Test func liveInstallIsIdempotentAndReverseKeepsOriginalCard() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let backend = try AnkiBackend()
        try backend.openCollection(collectionPath: directory.appendingPathComponent("collection.anki2").path,
                                   mediaFolderPath: directory.appendingPathComponent("media").path,
                                   mediaDbPath: directory.appendingPathComponent("media.db").path)
        defer { try? backend.closeCollection() }
        try await withDependencies { $0.ankiBackend = backend } operation: {
            try await withDependencies {
                $0.decksService = .liveValue
                $0.notesService = .liveValue
                $0.notetypesService = .liveValue
                $0.schedulerService = .liveValue
                $0.cardRenderingService = .liveValue
            } operation: {
            try await withDependencies {
                $0.notetypesClient = .liveValue
                $0.noteClient = .liveValue
                $0.notesService = .liveValue
                $0.deckClient = .liveValue
                $0.cardClient = .liveValue
            } operation: {
                let cards = MandarinStudyCards()
                let profile = UUID().uuidString
                defer { UserDefaults.standard.removeObject(forKey: "mandarin.study.v1." + profile) }
                try await cards.install(profileID: profile, updateSelection: false)
                @Dependency(\.noteClient) var notes
                @Dependency(\.cardClient) var cardClient
                let initial = try await notes.searchAll("tag:Mandarin", nil)
                #expect(initial.count == 360)
                try await cards.install(profileID: profile, updateSelection: false)
                #expect(try await notes.searchAll("tag:Mandarin", nil).count == 360)
                let note = try #require(initial.first)
                let before = try await cardClient.fetchByNote(note.id).map(\.id)
                #expect(before.count == 1)
                try await cards.enableProduction(noteID: note.id, prompt: "A clear English cue")
                try await cards.enableProduction(noteID: note.id, prompt: "A clear English cue")
                let after = try await cardClient.fetchByNote(note.id).map(\.id)
                #expect(after.count == 2)
                #expect(Set(before).isSubset(of: Set(after)))
                @Dependency(\.notetypesClient) var types
                @Dependency(\.notesService) var writer
                let basic = try #require(try await types.listAll().first { $0.name == "Basic" })
                let destination = try #require(try await deckClientForTest().first { $0.name == "Mandarin · HSK 3–4" })
                var basicNote = try writer.newNote(basic.id)
                basicNote.fields = ["安排", "arrange; plan"]
                basicNote.tags = ["generic-reverse-test"]
                try writer.addNote(basicNote, destination.id)
                let generic = try #require(try await notes.searchAll("tag:generic-reverse-test", nil).first)
                let genericBefore = try await cardClient.fetchByNote(generic.id).map(\.id)
                try await cards.enableProduction(noteID: generic.id, prompt: "Arrange or plan something")
                let genericAfter = try await cardClient.fetchByNote(generic.id).map(\.id)
                #expect(genericAfter.count == 2)
                #expect(Set(genericBefore).isSubset(of: Set(genericAfter)))
                #expect(try await types.get(basic.id).fields.map(\.name) == ["Front", "Back", MandarinStudyCards.productionField])
                let customID = try await types.create(Notetype(name: "Imported vocabulary", fields: [.init(name: "Hanzi"), .init(name: "English")],
                    templates: [.init(name: "Recognize", config: .init(qFormat: "{{Hanzi}}", aFormat: "{{English}}"))]))
                var customNote = try writer.newNote(customID)
                customNote.fields = ["联系", "get in touch"]
                customNote.tags = ["custom-reverse-test"]
                try writer.addNote(customNote, destination.id)
                let custom = try #require(try await notes.searchAll("tag:custom-reverse-test", nil).first)
                #expect(try await cards.productionPrompt(for: custom).0 == "get in touch")
                try await cards.enableProduction(noteID: custom.id, prompt: "Get in touch with someone")
                #expect(try await cardClient.fetchByNote(custom.id).count == 2)
                @Dependency(\.deckClient) var deckClient
                let allDecks = try await deckClient.fetchAll()
                let chosen = try #require(allDecks.first { $0.name == "Mandarin · HSK 3–4" })
                let budget = DailyStudyBudget.shared
                let oldLimit = budget.limit
                let oldNew = budget.newLimit
                let oldCount = budget.answered
                budget.setLimit(oldCount + 1, todayOnly: true)
                budget.setNewLimit(5)
                defer { budget.setLimit(oldLimit, todayOnly: true); budget.setNewLimit(oldNew); if budget.answered > oldCount { budget.undo(wasNew: true) } }
                let session = ReviewSession(deckId: chosen.id)
                session.start()
                for _ in 0..<250 { if !session.isAdvancing { break }; try await Task.sleep(for: .milliseconds(20)) }
                #expect(session.startError == nil)
                let current = try #require(session.currentNote)
                #expect(current.tags.contains("hsk34"))
                session.revealAnswer()
                session.answer(rating: .good)
                for _ in 0..<250 { if !session.isAdvancing { break }; try await Task.sleep(for: .milliseconds(20)) }
                #expect(session.answerError == nil)
                #expect(session.limitReached)
                #expect(budget.answered == oldCount + 1)
            }
            }
        }
    }

    private func deckClientForTest() async throws -> [DeckInfo] {
        @Dependency(\.deckClient) var client
        return try await client.fetchAll()
    }
}
