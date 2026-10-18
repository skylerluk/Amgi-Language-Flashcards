import Foundation
import Testing
import Dependencies
import AnkiClients
import AnkiKit
import ReaderEPUB
import Reader
@testable import ReaderFeature

@Suite("Mandarin learning")
struct MandarinLearningTests {
    @Test func bundledDialoguesAreCompleteAndRoundTrip() throws {
        #expect(Conversation.mandarin.count == 20)
        #expect(Set(Conversation.mandarin.map(\.id)).count == 20)
        #expect(Conversation.mandarin.filter { $0.level == .beginner }.count == 12)
        for dialogue in Conversation.mandarin {
            #expect(dialogue.language == "zh-CN")
            #expect(dialogue.lines.count == 16)
            #expect(dialogue.lines.allSatisfy { !$0.text.isEmpty && !$0.translation.isEmpty })
            let restored = try ConversationMarkdown.parse(ConversationMarkdown.serialize(dialogue), id: dialogue.id, fallbackTitle: "")
            #expect(restored.lines == dialogue.lines)
            #expect(restored.language == dialogue.language)
        }
    }

    @Test func languageRoutingDoesNotLeakSpanish() {
        #expect(LearningLanguage.resolve("zh-Hans") == .mandarin)
        #expect(LearningLanguage.resolve("es-ES") == .spanish)
        #expect(LearningLanguage.resolve("ja-JP") == .japanese)
        #expect(LearningLanguage.mandarin.matches("zh-Hans-CN"))
        #expect(!LearningLanguage.mandarin.matches("ja-JP"))
        for language in LearningLanguage.allCases where language != .spanish {
            let prompt = AIPrompts.tutorSystem(topic: "Friends", level: .beginner, language: language)
            #expect(!prompt.contains("Mexican Spanish"))
            #expect(AIPrompts.generatorSystem(level: .beginner, language: language).contains(language.rawValue))
        }
    }

    @Test func mandarinUsesIntermediateBaseline() {
        #expect(LearningLanguage.mandarin.levelName(.beginner) == "HSK 4")
        #expect(LearningLanguage.mandarin.levelName(.intermediate) == "HSK 5")
        #expect(LearningLanguage.spanish.levelName(.beginner) == "Beginner")
        #expect(LearningLanguage.pinyin("你好").contains("nǐ"))
    }

    @Test @MainActor func tutorParsesPinyinAndPreservesHistory() {
        let raw = #"{"reply":"最近怎么样？","pinyin":"Zuìjìn zěnmeyàng?","english":"How have you been?","hint":"还不错。"}"#
        let message = TutorModel.parse(raw, id: 7)
        #expect(message.pinyin == "Zuìjìn zěnmeyàng?")
        #expect(message.english == "How have you been?")
        #expect(message.raw == raw)
        #expect(TutorModel.parse("Plain reply", id: 8).text == "Plain reply")
    }

    @Test @MainActor func cardTextIsEscapedAndIdentityIncludesSource() {
        #expect(ReadingSentenceModel.escape("<script>&\"") == "&lt;script&gt;&amp;&quot;")
        #expect(ReadingSentenceModel.digest("book1|你好") != ReadingSentenceModel.digest("book2|你好"))
    }

    @Test func bundledTranslationWorksOffline() {
        #expect(BundledReadingSupport.translation(for: "星期六早上，小雨在小区门口发现了一张黄色的纸条。")?.contains("yellow note") == true)
        #expect(BundledReadingSupport.translation(for: "not in a bundled book") == nil)
    }

    @Test func bundledBooksImportWithChaptersAndChineseMetadata() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let library = EPUBLibraryStore(rootDirectory: directory)
        for (index, name) in BundledReadingSupport.bookNames.enumerated() {
            let url = try #require(BundledReadingSupport.bookURL(name))
            let book = try await library.importEPUB(from: url)
            #expect(book.language == "zh-CN")
            #expect(book.chapters.count == (index == 0 ? 8 : 10))
            let again = try await library.importEPUB(from: url)
            #expect(again.id == book.id)
        }
        #expect(await library.books().count == 2)
    }

    @Test @MainActor func existingSentenceDoesNotCreateAnotherNote() async {
        let model = withDependencies {
            $0.noteClient.search = { _, _ in
                [NoteRecord(id: NoteID(42), guid: "existing", mid: NotetypeID(1), mod: 0,
                            flds: "你好\u{1f}Hello", sfld: "你好", csum: 0)]
            }
        } operation: { ReadingSentenceModel() }
        model.english = "Hello"
        model.deckID = 1
        await model.save(text: "你好", language: "zh-CN", tags: ["test-book"], source: "Test")
        #expect(model.saved)
        #expect(!model.canUndo)
        #expect(model.errorMessage == nil)
    }

    @Test @MainActor func missingBasicTypeFailsWithoutCreatingAnEmptyCard() async {
        let model = withDependencies {
            $0.noteClient.search = { _, _ in [] }
            $0.notetypesClient.listAll = { [] }
        } operation: { ReadingSentenceModel() }
        model.english = "Hello"
        model.deckID = 1
        await model.save(text: "你好", language: "zh-CN", tags: [], source: "Test")
        #expect(!model.saved)
        #expect(model.errorMessage?.contains("Basic note type") == true)
        #expect(!model.isSaving)
    }
}
