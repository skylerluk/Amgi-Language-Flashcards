//
//  AddNoteModel.swift
//  BrowseFeature
//
//  Created by Vladimir Gusev on 22.06.2026.
//

import OSLog
import AppCore
import AppShared
import AnkiBackend
import AnkiKit
import AnkiClients
import AnkiServices
import Dependencies
import SwiftUI

/// Data state + load/save logic for the Add Note form. Mirrors the other
/// screen models: the View owns navigation, the toolbar, and dismissal,
/// while the model owns deck/notetype loading, field assembly, and the note
/// write so the form stays testable and the View stays thin.
@Observable
@MainActor
final class AddNoteModel {
    var decks: [DeckInfo] = []
    var notetypeNames: [(id: NotetypeID, name: String)] = []
    var selectedDeckId: DeckID = DeckID(1)
    var selectedNotetypeId: NotetypeID = NotetypeID(0)
    var fieldNames: [String] = []
    var fieldValues: [String] = []
    var tags: String = ""
    /// Recorded voice clips per field, parallel to `fieldValues`. Temporary
    /// files until `save()` copies them into the media folder and appends a
    /// `[sound:…]` marker to the field.
    var fieldAudio: [[URL]] = []
    /// Attached photos per field, parallel to `fieldValues`; temporary JPEGs
    /// until `save()` copies them in and appends an `<img>` tag.
    var fieldImages: [[URL]] = []
    var isSaving = false
    var errorMessage: String?
    /// Notes added since the sheet opened, for the "keep adding" flow.
    var addedCount = 0

    @ObservationIgnored @Dependency(\.deckClient) private var deckClient
    @ObservationIgnored @Dependency(\.notetypesService) private var notetypesService
    @ObservationIgnored @Dependency(\.notesService) private var notesService
    @ObservationIgnored @Dependency(\.collectionStore) private var store
    @ObservationIgnored @Dependency(\.mediaClient) private var mediaClient

    @ObservationIgnored private let preselectedDeckId: DeckID?
    @ObservationIgnored private let initialDraft: AddNoteDraft?

    @ObservationIgnored private var baselineFieldValues: [String] = []
    @ObservationIgnored private var baselineTags: String = ""

    var hasUnsavedChanges: Bool {
        fieldValues != baselineFieldValues || tags != baselineTags || hasAudio
    }

    var hasAudio: Bool {
        fieldAudio.contains { !$0.isEmpty } || fieldImages.contains { !$0.isEmpty }
    }

    /// Whether there is anything to add: text in any field, a voice clip or a photo.
    var canAdd: Bool {
        !isSaving && (!fieldValues.allSatisfy(\.isEmpty) || hasAudio)
    }

    /// Stores already-encoded JPEG data as a temporary attachment on a field.
    func attachImage(_ jpegData: Data, toField index: Int) {
        guard fieldImages.indices.contains(index) else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("amgi-image-\(UUID().uuidString.prefix(8)).jpg")
        do {
            try jpegData.write(to: url)
            fieldImages[index].append(url)
        } catch {
            errorMessage = "Couldn't attach the photo: \(error.localizedDescription)"
        }
    }

    func removeImage(_ url: URL, fromField index: Int) {
        guard fieldImages.indices.contains(index) else { return }
        fieldImages[index].removeAll { $0 == url }
        try? FileManager.default.removeItem(at: url)
    }

    func attachAudio(_ url: URL, toField index: Int) {
        guard fieldAudio.indices.contains(index) else { return }
        fieldAudio[index].append(url)
    }

    func removeAudio(_ url: URL, fromField index: Int) {
        guard fieldAudio.indices.contains(index) else { return }
        fieldAudio[index].removeAll { $0 == url }
        try? FileManager.default.removeItem(at: url)
    }

    /// Deletes clips that were recorded but never added.
    func discardAudio() {
        for url in (fieldAudio + fieldImages).flatMap({ $0 }) {
            try? FileManager.default.removeItem(at: url)
        }
        fieldAudio = fieldAudio.map { _ in [] }
        fieldImages = fieldImages.map { _ in [] }
    }

    init(preselectedDeckId: DeckID? = nil, initialDraft: AddNoteDraft? = nil) {
        self.preselectedDeckId = preselectedDeckId
        self.initialDraft = initialDraft
    }

    /// Positional projection into `fieldValues`, read through `@Bindable` as
    /// `$model[fieldAt: index]`. A subscript rather than a
    /// `Binding(get:set:)`-returning method so the field editors get a stable
    /// binding instead of a freshly-allocated closure pair on every body pass.
    subscript(fieldAt index: Int) -> String {
        get { index < fieldValues.count ? fieldValues[index] : "" }
        set { if index < fieldValues.count { fieldValues[index] = newValue } }
    }

    func loadData() async {
        decks = (try? await deckClient.fetchAll()) ?? []
        if let preselectedDeckId, decks.contains(where: { $0.id == preselectedDeckId }) {
            selectedDeckId = preselectedDeckId
        } else if let first = decks.first {
            selectedDeckId = first.id
        }

        do {
            let service = notetypesService
            notetypeNames = try await backendOffload { try service.getNotetypeNames() }
            // Honour an incoming draft's preferred notetype when it matches
            // one the user actually has; otherwise fall back to the first.
            let chosen = initialDraft?.notetypeID
                .flatMap { id in notetypeNames.first(where: { $0.id.rawValue == id }) }
                ?? notetypeNames.first
            if let chosen {
                selectedNotetypeId = chosen.id
                await loadFields()
            }
        } catch {
            Log.browse.error("Error loading notetypes: \(error)")
        }

        if let initialDraft, !initialDraft.tags.isEmpty {
            tags = initialDraft.tags.joined(separator: " ")
        }
        baselineTags = tags
    }

    func loadFields() async {
        guard selectedNotetypeId.rawValue != 0 else { return }
        do {
            let service = notetypesService
            let id = selectedNotetypeId
            let notetype = try await backendOffload { try service.getNotetype(id) }
            let isFirstLoad = fieldNames.isEmpty
            let previousNames = fieldNames
            let previousAudio = fieldAudio
            let previousImages = fieldImages
            fieldNames = notetype.fieldNames
            // Pre-fill from the incoming draft by mapping
            // `fieldValues[name] → fieldValues[positionalIndex]` against the
            // notetype's actual field-name list. Names not present on this
            // notetype are silently dropped.
            fieldValues = fieldNames.map { name in
                initialDraft?.fieldValues[name] ?? ""
            }
            // Carry attachments across a note-type switch by field name; the
            // first load takes them from the incoming draft instead.
            func carried(_ previous: [[URL]], draft: [String: [URL]]) -> [[URL]] {
                fieldNames.map { name in
                    if isFirstLoad { return draft[name] ?? [] }
                    guard let old = previousNames.firstIndex(of: name),
                          old < previous.count else { return [] }
                    return previous[old]
                }
            }
            fieldAudio = carried(previousAudio, draft: initialDraft?.audioFiles ?? [:])
            fieldImages = carried(previousImages, draft: [:])
            let kept = Set((fieldAudio + fieldImages).flatMap { $0 })
            for url in (previousAudio + previousImages).flatMap({ $0 }) where !kept.contains(url) {
                try? FileManager.default.removeItem(at: url)
            }
            baselineFieldValues = fieldValues
        } catch {
            Log.browse.error("Error loading fields: \(error)")
        }
    }

    /// Persist the note. Returns whether the write succeeded; on failure
    /// `errorMessage` carries the reason. Navigation/dismissal stays with
    /// the View.
    func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let notes = notesService
            let notetypeID = selectedNotetypeId
            let deckID = selectedDeckId
            let fields = try await fieldsWithAudio()
            let tagList = tags.split(separator: " ").map(String.init)
            try await backendOffload {
                var template = try notes.newNote(notetypeID)
                template.fields = fields
                template.tags = tagList
                try notes.addNote(template, deckID)
            }
            // addNote doesn't surface OpChanges yet — invalidate the shared
            // tree cache conservatively so every host (DeckDetail, reader
            // lookup, Browse) sees fresh counts.
            store.apply(CollectionChanges(card: true, note: true, studyQueues: true))
            discardAudio()
            addedCount += 1
            return true
        } catch {
            errorMessage = "Failed to add note: \(error.localizedDescription)"
            return false
        }
    }

    /// Clears the fields for the next note while keeping the deck, note type
    /// and tags — the Anki desktop "Add" behaviour for entering many cards.
    func resetForNextNote() {
        fieldValues = fieldNames.map { _ in "" }
        baselineFieldValues = fieldValues
        baselineTags = tags
        fieldAudio = fieldNames.map { _ in [] }
        fieldImages = fieldNames.map { _ in [] }
    }

    /// Copies each recorded clip into the collection's media folder and
    /// appends its `[sound:…]` marker to the field it was recorded for.
    private func fieldsWithAudio() async throws -> [String] {
        var fields = fieldValues
        for (index, images) in fieldImages.enumerated() where index < fields.count {
            for url in images {
                let data = try Data(contentsOf: url)
                let filename = "amgi-image-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(6)).jpg"
                try await mediaClient.save(data, filename)
                let tag = "<img src=\"\(filename)\">"
                fields[index] = fields[index].isEmpty ? tag : fields[index] + "<br>" + tag
            }
        }
        for (index, clips) in fieldAudio.enumerated() where index < fields.count {
            for url in clips {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
                let filename = "amgi-voice-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(6)).\(ext)"
                try await mediaClient.save(data, filename)
                let marker = "[sound:\(filename)]"
                fields[index] = fields[index].isEmpty ? marker : fields[index] + " " + marker
            }
        }
        return fields
    }
}
