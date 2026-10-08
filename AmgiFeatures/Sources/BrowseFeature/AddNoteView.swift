//
//  AddNoteView.swift
//  BrowseFeature
//
//  Created by Vladimir Gusev on 30.03.2026.
//

package import SwiftUI
package import AnkiKit
import PhotosUI
import Theme

/// Add Note container: owns the modal chrome (navigation, toolbar, dismissal)
/// and drives an `AddNoteModel` for deck/notetype loading and the note write.
/// The form itself is `AddNoteContent`, bound to the model.
package struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: AddNoteModel
    @State private var showDiscardConfirm = false
    #if canImport(UIKit)
    @State private var recorder = VoiceRecorder()
    #endif
    let keepsOpenAfterAdd: Bool
    let onSave: () -> Void

    /// - Parameter keepsOpenAfterAdd: when true (the default), "Add" clears the
    ///   fields and stays open for the next note, keeping deck, note type and
    ///   tags — Anki desktop's behaviour. Pass false for one-shot hosts such as
    ///   the reader's dictionary lookup.
    package init(
        preselectedDeckId: DeckID? = nil,
        initialDraft: AddNoteDraft? = nil,
        keepsOpenAfterAdd: Bool = true,
        onSave: @escaping () -> Void
    ) {
        let resolved = preselectedDeckId ?? initialDraft?.deckID.map { DeckID($0) }
        _model = State(initialValue: AddNoteModel(preselectedDeckId: resolved, initialDraft: initialDraft))
        self.keepsOpenAfterAdd = keepsOpenAfterAdd
        self.onSave = onSave
    }

    private func add() {
        #if canImport(UIKit)
        if recorder.isRecording, let clip = recorder.stop() {
            model.attachAudio(clip.url, toField: clip.fieldIndex)
        }
        recorder.stopPlayback()
        #endif
        Task {
            guard await model.save() else { return }
            onSave()
            if keepsOpenAfterAdd {
                model.resetForNextNote()
            } else {
                dismiss()
            }
        }
    }

    package var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add Note")
                .navigationBarTitleDisplayMode(.inline)
                .interactiveDismissDisabled(model.hasUnsavedChanges)
                .confirmationDialog(
                    "Discard this note?",
                    isPresented: $showDiscardConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Discard", role: .destructive) {
                        #if canImport(UIKit)
                        recorder.cancel()
                        #endif
                        model.discardAudio()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The note hasn't been added yet. Discarding loses what you typed.")
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(model.addedCount > 0 && !model.hasUnsavedChanges ? "Done" : "Cancel") {
                            if model.hasUnsavedChanges {
                                showDiscardConfirm = true
                            } else {
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: add)
                            .disabled(!model.canAdd && !isRecordingNow)
                    }
                }
                .sensoryFeedback(.success, trigger: model.addedCount)
                .task { await model.loadData() }
                .onDisappear {
                    #if canImport(UIKit)
                    recorder.cancel()
                    #endif
                    model.discardAudio()
                }
        }
    }
}

extension AddNoteView {
    @ViewBuilder
    private var content: some View {
        #if canImport(UIKit)
        AddNoteContent(model: model, recorder: recorder)
            .alert(
                "Microphone access is off",
                isPresented: Binding(
                    get: { recorder.failure == .permissionDenied },
                    set: { if !$0 { recorder.failure = nil } }
                )
            ) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Allow microphone access in Settings to record voice onto cards.")
            }
        #else
        AddNoteContent(model: model)
        #endif
    }

    private var isRecordingNow: Bool {
        #if canImport(UIKit)
        recorder.isRecording
        #else
        false
        #endif
    }
}

// MARK: - AddNoteContent

/// The Add Note form: deck + note-type pickers, the note-type's fields, and a
/// tags field. Bound to an `AddNoteModel`; owns no I/O of its own, so it
/// renders in a `#Preview` from a seeded model.
struct AddNoteContent: View {
    @Environment(\.palette) private var palette
    @Bindable var model: AddNoteModel
    #if canImport(UIKit)
    var recorder: VoiceRecorder?
    #endif

    var body: some View {
        Form {
            if model.addedCount > 0 {
                Section {
                    Label(
                        model.addedCount == 1 ? "Added 1 note" : "Added \(model.addedCount) notes",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(palette.positive)
                    .amgiFont(.caption)
                }
            }

            Section("Deck") {
                Picker("Deck", selection: $model.selectedDeckId) {
                    ForEach(model.decks) { deck in
                        Text(deck.name).tag(deck.id)
                    }
                }
            }

            Section("Note Type") {
                Picker("Type", selection: $model.selectedNotetypeId) {
                    ForEach(model.notetypeNames, id: \.id) { entry in
                        Text(entry.name).tag(entry.id)
                    }
                }
                .onChange(of: model.selectedNotetypeId) {
                    Task { await model.loadFields() }
                }
            }

            Section("Fields") {
                ForEach(Array(model.fieldNames.enumerated()), id: \.element) { index, name in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(name)
                                .amgiFont(.caption)
                                .foregroundStyle(palette.textSecondary)
                            Spacer()
                            #if canImport(UIKit)
                            FieldPhotoButton { data in
                                model.attachImage(data, toField: index)
                            }
                            if let recorder {
                                VoiceRecordButton(recorder: recorder, fieldIndex: index) { url in
                                    model.attachAudio(url, toField: index)
                                }
                            }
                            #endif
                        }
                        RichNoteFieldEditor(htmlText: $model[fieldAt: index])
                            // New identity per added note, so the text view
                            // clears even if it still holds keyboard focus.
                            .id(model.addedCount)
                        #if canImport(UIKit)
                        if index < model.fieldImages.count, !model.fieldImages[index].isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(model.fieldImages[index], id: \.self) { url in
                                        AttachedPhotoThumbnail(url: url) {
                                            model.removeImage(url, fromField: index)
                                        }
                                    }
                                }
                            }
                        }
                        if let recorder, index < model.fieldAudio.count {
                            ForEach(Array(model.fieldAudio[index].enumerated()), id: \.element) { clipIndex, url in
                                VoiceClipRow(
                                    title: "Voice \(clipIndex + 1)",
                                    isPlaying: recorder.playingURL == url,
                                    onPlay: { recorder.togglePlayback(url) },
                                    onDelete: {
                                        if recorder.playingURL == url { recorder.stopPlayback() }
                                        model.removeAudio(url, fromField: index)
                                    }
                                )
                            }
                        }
                        #endif
                    }
                }
            }

            Section("Tags") {
                TextField("Tags (space-separated)", text: $model.tags)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if let errorMessage = model.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(palette.danger)
                        .amgiFont(.caption)
                }
            }
        }
    }
}

// MARK: - Voice recording controls

#if canImport(UIKit)
/// Tap to start recording into a field, tap again to stop and attach the clip.
private struct VoiceRecordButton: View {
    @Environment(\.palette) private var palette
    let recorder: VoiceRecorder
    let fieldIndex: Int
    let onRecorded: (URL) -> Void

    private var isRecordingHere: Bool { recorder.recordingFieldIndex == fieldIndex }

    var body: some View {
        Button {
            if isRecordingHere {
                if let clip = recorder.stop() { onRecorded(clip.url) }
            } else {
                Task { await recorder.start(fieldIndex: fieldIndex) }
            }
        } label: {
            if isRecordingHere, let startedAt = recorder.recordingStartedAt {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle.fill")
                        .symbolEffect(.pulse)
                    TimelineView(.periodic(from: startedAt, by: 1)) { context in
                        let seconds = Int(context.date.timeIntervalSince(startedAt))
                        Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(palette.danger)
            } else {
                Label("Record", systemImage: "mic.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(palette.accent)
            }
        }
        .buttonStyle(.borderless)
        .font(.title3)
        .disabled(recorder.isRecording && !isRecordingHere)
        .accessibilityLabel(isRecordingHere ? "Stop recording" : "Record voice")
        .sensoryFeedback(.impact, trigger: isRecordingHere)
    }
}

/// Picks a photo from the library, downscales it, and hands back JPEG data.
private struct FieldPhotoButton: View {
    @Environment(\.palette) private var palette
    @State private var item: PhotosPickerItem?
    let onPicked: (Data) -> Void

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            Image(systemName: "photo")
        }
        .foregroundStyle(palette.accent)
        .accessibilityLabel("Add photo")
        .buttonStyle(.borderless)
        .font(.title3)
        .onChange(of: item) {
            guard let item else { return }
            Task {
                defer { self.item = nil }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let jpeg = Self.downscaledJPEG(data) else { return }
                onPicked(jpeg)
            }
        }
    }

    /// Caps the long edge at 1600px so phone photos don't bloat the
    /// collection and its sync.
    static func downscaledJPEG(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxEdge: CGFloat = 1600
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxEdge / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

private struct AttachedPhotoThumbnail: View {
    let url: URL
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(.rect(cornerRadius: 8))
            }
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .buttonStyle(.borderless)
            .padding(2)
            .accessibilityLabel("Remove photo")
        }
    }
}

private struct VoiceClipRow: View {
    @Environment(\.palette) private var palette
    let title: String
    let isPlaying: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onPlay) {
                Label(title, systemImage: isPlaying ? "stop.circle.fill" : "play.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(palette.accent)
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Label("Delete \(title)", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
        .amgiFont(.caption)
    }
}
#endif

// MARK: - Preview

#if DEBUG
#Preview {
    // Seed the model directly: AddNoteContent has no `.task`, so the sample
    // fields aren't overwritten by a load and no live backend is touched.
    let model = AddNoteModel()
    model.decks = [.sample, .filtered]
    model.selectedDeckId = DeckInfo.sample.id
    model.notetypeNames = [(NotetypeID(1), "Basic"), (NotetypeID(2), "Cloze")]
    model.selectedNotetypeId = NotetypeID(1)
    model.fieldNames = ["Front", "Back"]
    model.fieldValues = ["안녕하세요", "Hello"]
    model.tags = "vocab korean"
    return NavigationStack {
        AddNoteContent(model: model)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
