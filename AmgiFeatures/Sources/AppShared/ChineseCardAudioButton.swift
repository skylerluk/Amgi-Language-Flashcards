package import SwiftUI
import AVFoundation
import Foundation
import Observation

package struct ChineseCardAudioButton: View {
    let text: String
    @State private var audio = ChineseCardSpeech()
    package init(text: String) { self.text = text }
    package var body: some View {
        Button(audio.isActive ? "Stop" : "Listen",
               systemImage: audio.isActive ? "stop.circle" : "speaker.wave.2") {
            if audio.isActive { audio.stop() } else { audio.play(text) }
        }
        .accessibilityLabel(audio.isActive ? "Stop Chinese audio" : "Listen to Chinese")
        .accessibilityValue(audio.isSpeaking ? "Speaking" : (audio.isActive ? "Preparing audio" : (audio.didPlay ? "Played" : "Ready")))
        .onChange(of: text) { audio.stop() }
        .onDisappear { audio.stop() }
        .alert("Couldn't play Chinese audio", isPresented: Binding(
            get: { audio.error != nil }, set: { if !$0 { audio.error = nil } }
        )) { Button("OK", role: .cancel) { audio.error = nil } } message: {
            Text(audio.error ?? "")
        }
    }
}

/// Retains the synthesizer for the button's lifetime and explicitly activates
/// playback, so a deliberate Listen tap works even when the phone is silenced.
@MainActor @Observable
private final class ChineseCardSpeech: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var didPlay = false
    private var utteranceID: ObjectIdentifier?
    var isSpeaking = false
    private var isPreparing = false
    var isActive: Bool { isSpeaking || isPreparing }
    private var previousSession: (AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions)?
    var error: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func play(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let voice = AVSpeechSynthesisVoice(language: "zh-CN") else {
            error = "Download a Mandarin voice in iPhone Settings → Accessibility → Read & Speak → Voices."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            previousSession = (session.category, session.mode, session.categoryOptions)
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice
            utterance.rate = 0.43
            utteranceID = ObjectIdentifier(utterance)
            didPlay = false
            isPreparing = true
            synthesizer.speak(utterance)
        } catch {
            isSpeaking = false
            restoreSession()
            self.error = error.localizedDescription
        }
    }

    func stop() {
        utteranceID = nil
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPreparing = false
        restoreSession()
    }

    private func restoreSession() {
        guard let previous = previousSession else { return }
        previousSession = nil
        try? AVAudioSession.sharedInstance().setCategory(previous.0, mode: previous.1, options: previous.2)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, self.utteranceID == id else { return }
            self.isPreparing = false
            self.isSpeaking = true
            self.didPlay = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finished(ObjectIdentifier(utterance))
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finished(ObjectIdentifier(utterance))
    }

    private nonisolated func finished(_ id: ObjectIdentifier) {
        Task { @MainActor [weak self] in
            guard let self, self.utteranceID == id else { return }
            self.utteranceID = nil
            self.isSpeaking = false
            self.isPreparing = false
            self.restoreSession()
        }
    }
}
