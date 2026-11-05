//
//  DeckListView.swift
//  DecksFeature
//
//  Created by Vladimir Gusev on 14.05.2026.
//

package import SwiftUI
package import AppCore
import AppShared
import UI
import Theme
import AnkiKit
import AnkiClients
import Dependencies
import Sharing
import BrowseFeature
import ReviewFeature

package struct DeckListView: View {
    private let onSwitchProfile: (AmgiAccount) async -> Void
    private let onSync: () -> Void
    private let onImport: () -> Void
    @Dependency(\.collectionStore) private var store
    @State private var model: DeckListModel
    @State private var showCreateSheet = false
    @State private var showAddNote = false
    @State private var showBrowse = false
    @State private var budget = DailyStudyBudget.shared
    @State private var allDecks: [DeckInfo] = []
    @State private var showDeckSelection = false
    @State private var showLimits = false
    @State private var showReview = false
    @State private var packError: String?
    @State private var renameTarget: DeckRowViewData?
    @State private var pendingDeck: DeckInfo?
    @State private var accounts = AccountStore.shared
    @Shared(.appStorage(AppearancePreferences.Keys.showProfileInToolbar))
    private var showProfileInToolbar = true

    package init(
        onSwitchProfile: @escaping (AmgiAccount) async -> Void,
        onSync: @escaping () -> Void,
        onImport: @escaping () -> Void
    ) {
        self.onSwitchProfile = onSwitchProfile
        self.onSync = onSync
        self.onImport = onImport
        _model = State(initialValue: DeckListModel())
    }

    /// Preview / test seam — internal so the model stays module-private.
    init(
        model: DeckListModel,
        onSwitchProfile: @escaping (AmgiAccount) async -> Void = { _ in },
        onSync: @escaping () -> Void = {},
        onImport: @escaping () -> Void = {}
    ) {
        self.onSwitchProfile = onSwitchProfile
        self.onSync = onSync
        self.onImport = onImport
        _model = State(initialValue: model)
    }

    package var body: some View {
        LibraryListContent(
            state: selectedState,
            selectedDeckID: pendingDeck?.id.rawValue,
            onRefresh: { await model.load() },
            onStartReview: { showReview = !selectedDecks.isEmpty },
            onTapDeck: { row in pendingDeck = row.asDeckInfo },
            onDeleteDeck: { rawID in await model.delete(DeckID(rawID)) },
            onRenameDeck: { row in renameTarget = row },
            onCreateDeck: { showCreateSheet = true },
            reviewControls: AnyView(reviewControls)
        )
        .navigationTitle("Library")
        .navigationDestination(item: $pendingDeck) { deck in
            DeckDetailView(deck: deck)
        }
        #if canImport(UIKit)
        .navigationDestination(isPresented: $showBrowse) {
            BrowseView()
        }
        #endif
        .toolbar { toolbarContent }
        .sheet(isPresented: $showCreateSheet) {
            CreateDeckSheet {
                showCreateSheet = false
            }
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView {}
        }
        .sheet(item: $renameTarget) { row in
            RenameDeckSheet(deckId: DeckID(row.id), currentName: row.fullName) {
                renameTarget = nil
            }
        }
        .sheet(isPresented: $showLimits) { StudyBudgetSettings() }
        .sheet(isPresented: $showDeckSelection) { deckSelection }
        .fullScreenCover(isPresented: $showReview) {
            if let first = selectedDecks.first {
                ReviewView(deckId: first.id, selectedDeckIDs: selectedDecks.map(\.id)) { showReview = false; Task { await model.load(); await refreshDecks() } }
            }
        }
        .alert("Couldn't delete deck", isPresented: Binding(get: { model.operationError != nil }, set: { if !$0 { model.operationError = nil } })) {
            Button("OK") { model.operationError = nil }
        } message: { Text(model.operationError ?? "") }
        .task {
            do { try await MandarinStudyCards().install() }
            catch { packError = error.localizedDescription }
            await model.load()
            await refreshDecks()
        }
        .task(id: store.generation) { await model.load(); await refreshDecks() }
    }

    private var selectedDecks: [DeckInfo] {
        let ids = budget.selectedIDs
        let selected = allDecks.filter { ids?.contains($0.id.rawValue) ?? $0.name.hasPrefix("Mandarin") }
        return selected.filter { child in !selected.contains { parent in parent.id != child.id && child.name.hasPrefix(parent.name + "::") } }
    }
    private var selectedState: LibraryListContent.State {
        guard case .loaded(let rows, let previous, let heatmap) = model.state else { return model.state }
        let scheduled = selectedDecks.reduce(0) { $0 + $1.counts.learnCount + $1.counts.reviewCount }
        let newAvailable = selectedDecks.reduce(0) { $0 + $1.counts.newCount }
        let available = scheduled + min(newAvailable, max(0, budget.newLimit - budget.introduced))
        let hero = HeroData(totalDue: budget.reached ? available : min(available, max(0, budget.limit - budget.answered)), deckCount: selectedDecks.count, streak: previous.streak, last14Days: previous.last14Days)
        return .loaded(rows: rows, hero: hero, heatmap: heatmap)
    }
    private func refreshDecks() async {
        @Dependency(\.deckClient) var client
        do { allDecks = try await client.fetchAll() }
        catch { packError = error.localizedDescription }
    }
    private var reviewControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button { showDeckSelection = true } label: { Label("Decks: \(selectedDecks.count)", systemImage: "chevron.down") }
                Spacer()
                Button("Daily cap: \(budget.limit)") { showLimits = true }
            }.buttonStyle(.borderless)
            Text("\(budget.answered)/\(budget.limit) answers today · \(budget.introduced)/\(budget.newLimit) new cards").amgiFont(.caption)
            Text("\(selectedDecks.reduce(0) { $0 + $1.counts.learnCount + $1.counts.reviewCount }) scheduled reviews due in selected decks").amgiFont(.caption)
            if budget.reached { Text("Daily goal reached. Start review to add 20 more; remaining cards stay due.").amgiFont(.caption) }
            if let packError {
                Text(packError).amgiFont(.caption)
                Button("Retry Mandarin pack") { Task { do { try await MandarinStudyCards().install(); self.packError = nil; await model.load(); await refreshDecks() } catch { self.packError = error.localizedDescription } } }
            }
        }
    }
    private var deckSelection: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button("Select all") { budget.selectedIDs = allDecks.map { $0.id.rawValue } }
                        Spacer()
                        Button("Clear") { budget.selectedIDs = [] }
                    }
                }
                Section("Include these decks (and their subdecks)") {
                    ForEach(allDecks) { deck in
                        Toggle(deck.name, isOn: Binding(
                            get: { budget.selectedIDs?.contains(deck.id.rawValue) ?? deck.name.hasPrefix("Mandarin") },
                            set: { included in
                                var ids = budget.selectedIDs ?? selectedDecks.map { $0.id.rawValue }
                                ids.removeAll { $0 == deck.id.rawValue }
                                if included { ids.append(deck.id.rawValue) }
                                budget.selectedIDs = ids
                            }))
                    }
                }
            }.navigationTitle("Today's decks")
                .toolbar { Button("Done") { showDeckSelection = false } }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if showsProfilePicker {
            ToolbarItem(placement: .navigation) {
                ProfilePickerMenu(onSwitch: onSwitchProfile)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Sync", systemImage: "arrow.triangle.2.circlepath", action: onSync)
                .keyboardShortcut("r", modifiers: .command)
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Add Card", systemImage: "rectangle.stack.badge.plus") {
                    showAddNote = true
                }
                .keyboardShortcut("e", modifiers: .command)
                Button("New Deck", systemImage: "folder.badge.plus") {
                    showCreateSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                #if canImport(UIKit)
                Button {
                    showBrowse = true
                } label: {
                    Label("Browse Notes", systemImage: "doc.text")
                }
                #endif
                Button(action: onImport) {
                    Label("Import Deck…", systemImage: "square.and.arrow.down")
                }
            } label: {
                Label("More", systemImage: "ellipsis")
            }
        }
    }

    private var showsProfilePicker: Bool {
        showProfileInToolbar && accounts.accounts.count > 1
    }
}
