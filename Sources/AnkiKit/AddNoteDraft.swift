//
//  AddNoteDraft.swift
//  AnkiKit
//
//  Created by Vladimir Gusev on 28.04.2026.
//

public import Foundation

public struct AddNoteDraft: Sendable, Hashable {
    public var deckID: Int64?
    public var notetypeID: Int64?
    public var fieldValues: [String: String]
    public var tags: [String]
    /// Local audio files to attach, keyed by field name. Copied into the
    /// media folder only if the note is actually added.
    public var audioFiles: [String: [URL]]

    public init(
        deckID: Int64? = nil,
        notetypeID: Int64? = nil,
        fieldValues: [String: String] = [:],
        tags: [String] = [],
        audioFiles: [String: [URL]] = [:]
    ) {
        self.deckID = deckID
        self.notetypeID = notetypeID
        self.fieldValues = fieldValues
        self.tags = tags
        self.audioFiles = audioFiles
    }
}
