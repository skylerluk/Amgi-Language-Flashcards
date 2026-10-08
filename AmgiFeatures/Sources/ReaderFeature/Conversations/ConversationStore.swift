//
//  ConversationStore.swift
//  ReaderFeature
//

import Foundation
import Observation
import OSLog
import ZIPFoundation

/// Conversations the user imported (or generated), stored as Markdown files
/// in `Documents/Conversations`. Plain files on purpose: they are visible in
/// the Files app, survive app updates, and use the same format the user
/// imports.
@Observable
@MainActor
final class ConversationStore {
    static let shared = ConversationStore()

    private(set) var imported: [Conversation] = []

    private static let log = Logger(subsystem: "com.skylerluk.amgi", category: "Conversations")
    private static let allowedExtensions: Set<String> = ["md", "markdown", "txt"]

    nonisolated static var directory: URL {
        URL.documentsDirectory.appendingPathComponent("Conversations", isDirectory: true)
    }

    private init() {
        reload()
    }

    func reload() {
        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(
            at: Self.directory,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []
        imported = files
            .filter { Self.allowedExtensions.contains($0.pathExtension.lowercased()) }
            // Newest day first; within a day (e.g. one zip), file-name order
            // so "01 - …", "02 - …" read in sequence.
            .sorted { lhs, rhs in
                let left = Calendar.current.startOfDay(for: creationDate(lhs))
                let right = Calendar.current.startOfDay(for: creationDate(rhs))
                if left != right { return left > right }
                return lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
            }
            .compactMap { url in
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                return try? ConversationMarkdown.parse(
                    text,
                    id: "file:" + url.lastPathComponent,
                    fallbackTitle: url.deletingPathExtension().lastPathComponent
                )
            }
    }

    struct ImportResult {
        var added = 0
        var failed: [String] = []

        var summary: String {
            var parts: [String] = []
            if added > 0 { parts.append(added == 1 ? "Added 1 conversation." : "Added \(added) conversations.") }
            if !failed.isEmpty { parts.append("Couldn't read: \(failed.joined(separator: ", ")).") }
            return parts.isEmpty ? "Nothing to import." : parts.joined(separator: " ")
        }
    }

    /// Imports `.md`/`.txt` files and `.zip` archives of them.
    func importFiles(_ urls: [URL]) -> ImportResult {
        var result = ImportResult()
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if url.pathExtension.lowercased() == "zip" {
                importZip(url, into: &result)
            } else if let data = try? Data(contentsOf: url) {
                save(data, named: url.lastPathComponent, into: &result)
            } else {
                result.failed.append(url.lastPathComponent)
            }
        }
        reload()
        return result
    }

    /// Saves a generated conversation and returns it as stored.
    @discardableResult
    func add(_ conversation: Conversation) throws -> Conversation? {
        try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let name = uniqueURL(for: conversation.title + ".md")
        try Data(ConversationMarkdown.serialize(conversation).utf8).write(to: name)
        reload()
        return imported.first { $0.id == "file:" + name.lastPathComponent }
    }

    func delete(_ conversation: Conversation) {
        guard conversation.id.hasPrefix("file:") else { return }
        let name = String(conversation.id.dropFirst("file:".count))
        try? FileManager.default.removeItem(at: Self.directory.appendingPathComponent(name))
        reload()
    }

    // MARK: - Private

    private func importZip(_ url: URL, into result: inout ImportResult) {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            for entry in archive where entry.type == .file {
                let name = (entry.path as NSString).lastPathComponent
                // Skip macOS resource-fork junk and anything that isn't text.
                guard !entry.path.contains("__MACOSX"), !name.hasPrefix("."),
                      Self.allowedExtensions.contains((name as NSString).pathExtension.lowercased())
                else { continue }
                var data = Data()
                _ = try archive.extract(entry) { data.append($0) }
                save(data, named: name, into: &result)
            }
        } catch {
            Self.log.error("Zip import failed: \(error)")
            result.failed.append(url.lastPathComponent)
        }
    }

    private func save(_ data: Data, named name: String, into result: inout ImportResult) {
        guard Self.allowedExtensions.contains((name as NSString).pathExtension.lowercased()),
              let text = String(data: data, encoding: .utf8),
              (try? ConversationMarkdown.parse(text, id: name, fallbackTitle: name)) != nil
        else {
            result.failed.append(name)
            return
        }
        do {
            try data.write(to: uniqueURL(for: name))
            result.added += 1
        } catch {
            result.failed.append(name)
        }
    }

    private func uniqueURL(for name: String) -> URL {
        let cleaned = name.replacingOccurrences(of: "/", with: "-")
        let base = (cleaned as NSString).deletingPathExtension
        let ext = (cleaned as NSString).pathExtension.isEmpty ? "md" : (cleaned as NSString).pathExtension
        var candidate = Self.directory.appendingPathComponent("\(base).\(ext)")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = Self.directory.appendingPathComponent("\(base) \(counter).\(ext)")
            counter += 1
        }
        return candidate
    }

    private func creationDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
    }
}
