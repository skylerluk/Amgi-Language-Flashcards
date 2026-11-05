package import SwiftUI
package import AnkiKit
import Theme

package struct ProductionCardButton: View {
    let note: NoteRecord
    var onSaved: () -> Void
    @State private var showEditor = false
    @State private var prompt = ""
    @State private var enabled = false
    @State private var busy = false
    @State private var error: String?
    package init(note: NoteRecord, onSaved: @escaping () -> Void = {}) { self.note = note; self.onSaved = onSaved }
    package var body: some View {
        Button {
            busy = true
            Task {
                defer { busy = false }
                do {
                    let state = try await MandarinStudyCards().productionPrompt(for: note)
                    prompt = state.0; enabled = state.1
                    if enabled { return }
                    if !prompt.isEmpty {
                        try await MandarinStudyCards().enableProduction(noteID: note.id, prompt: prompt)
                        enabled = true; onSaved()
                    } else { showEditor = true }
                } catch { self.error = error.localizedDescription }
            }
        } label: {
            Label(enabled ? "English → Chinese added" : "Add English → Chinese card", systemImage: enabled ? "checkmark.circle" : "arrow.left.arrow.right")
        }
        .disabled(busy || enabled)
        .contextMenu { Button("Edit English prompt") { showEditor = true } }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                Form {
                    TextField("English meaning or situation", text: $prompt, axis: .vertical)
                    Text("Give enough context to distinguish similar words. Chinese, pinyin, and audio appear after revealing the answer.").amgiFont(.caption)
                    if let error { Text(error) }
                }
                .navigationTitle("Production prompt")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showEditor = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            busy = true
                            Task {
                                defer { busy = false }
                                do { try await MandarinStudyCards().enableProduction(noteID: note.id, prompt: prompt); enabled = true; showEditor = false; onSaved() }
                                catch { self.error = error.localizedDescription }
                            }
                        }.disabled(busy || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .alert("Couldn't add production card", isPresented: Binding(get: { error != nil && !showEditor }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
        .task(id: note.id) {
            if let state = try? await MandarinStudyCards().productionPrompt(for: note) { prompt = state.0; enabled = state.1 }
        }
    }
}
