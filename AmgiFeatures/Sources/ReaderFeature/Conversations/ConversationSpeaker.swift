//
//  ConversationSpeaker.swift
//  ReaderFeature
//

import AVFoundation
import Foundation
import Observation

/// Reads conversation lines aloud. A line with generated ElevenLabs audio
/// (see `ConversationAudioCache`) plays that file; every other line uses
/// Apple's on-device voices, one per speaker. Lines play from a queue, one at
/// a time, so "Play all" can mix the two and the UI can highlight the line
/// being spoken.
@Observable
@MainActor
final class ConversationSpeaker: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    /// Line id currently being spoken, if any.
    private(set) var speakingLineID: Int?
    private(set) var isPlayingAll = false
    var isSlow = false

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var queue: [Conversation.Line] = []
    @ObservationIgnored private var conversation: Conversation?
    @ObservationIgnored private var currentUtterance: ObjectIdentifier?
    /// Bumped by `stop()` so callbacks from a cancelled item are ignored.
    @ObservationIgnored private var generation = 0

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ line: Conversation.Line, in conversation: Conversation) {
        stop()
        self.conversation = conversation
        queue = [line]
        playNext()
    }

    func playAll(_ conversation: Conversation) {
        stop()
        self.conversation = conversation
        queue = conversation.lines
        isPlayingAll = true
        playNext()
    }

    /// Speaks free text (a tutor reply) with the best voice for `language`,
    /// highlighting `id` while it plays.
    func speak(text: String, id: Int, language: String = "es-MX") {
        stop()
        activatePlaybackSession()
        let utterance = AVSpeechUtterance(string: text)
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
        utterance.voice = voices.first { $0.gender == .female } ?? voices.first
            ?? AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (isSlow ? 0.7 : 0.95)
        speakingLineID = id
        currentUtterance = ObjectIdentifier(utterance)
        synthesizer.speak(utterance)
    }

    func stop() {
        generation += 1
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        player?.stop()
        player = nil
        queue = []
        currentUtterance = nil
        speakingLineID = nil
        isPlayingAll = false
    }

    /// The utterance a line is spoken with, shared with the audio-file
    /// renderer so a card's recording sounds exactly like playback.
    func utterance(for line: Conversation.Line, in conversation: Conversation) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: line.text)
        let (voice, pitch) = Self.voice(forSpeaker: line.speaker, in: conversation)
        utterance.voice = voice
        utterance.pitchMultiplier = pitch
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (isSlow ? 0.7 : 0.95)
        return utterance
    }

    // MARK: - Queue

    private func playNext() {
        guard let conversation, !queue.isEmpty else {
            finish()
            return
        }
        activatePlaybackSession()
        let line = queue.removeFirst()
        speakingLineID = line.id

        if let url = ConversationAudioCache.cachedURL(for: line, in: conversation),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.delegate = self
            player.enableRate = true
            player.rate = isSlow ? 0.8 : 1.0
            self.player = player
            player.play()
        } else {
            let utterance = utterance(for: line, in: conversation)
            currentUtterance = ObjectIdentifier(utterance)
            synthesizer.speak(utterance)
        }
    }

    private func itemEnded(generation token: Int) {
        guard token == generation else { return }
        player = nil
        currentUtterance = nil
        if isPlayingAll, !queue.isEmpty {
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                guard token == generation else { return }
                playNext()
            }
        } else {
            finish()
        }
    }

    private func finish() {
        queue = []
        speakingLineID = nil
        isPlayingAll = false
    }

    /// Plays through the silent switch, like any audio a user taps to hear.
    private func activatePlaybackSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func utteranceEnded(_ id: ObjectIdentifier) {
        guard id == currentUtterance else { return }
        itemEnded(generation: generation)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in
            guard let current = self.player, ObjectIdentifier(current) == id else { return }
            self.itemEnded(generation: self.generation)
        }
    }

    // MARK: - Voice choice

    /// Picks a voice per speaker: the best-quality installed voice matching
    /// the speaker's gender, then any voice for the language, then any
    /// Spanish voice. When two speakers land on the same voice, the second
    /// is pitched down so the conversation still reads as two people.
    static func voice(
        forSpeaker index: Int,
        in conversation: Conversation
    ) -> (AVSpeechSynthesisVoice?, Float) {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let base = conversation.language.prefix(2)
        let exact = all.filter { $0.language == conversation.language }
        let family = exact.isEmpty ? all.filter { $0.language.hasPrefix(String(base)) } : exact
        let ranked = family.sorted { $0.quality.rawValue > $1.quality.rawValue }

        func pick(_ speaker: Int) -> AVSpeechSynthesisVoice? {
            guard conversation.speakers.indices.contains(speaker) else { return ranked.first }
            let wanted: AVSpeechSynthesisVoiceGender =
                conversation.speakers[speaker].gender == .female ? .female : .male
            return ranked.first { $0.gender == wanted } ?? ranked.first
        }

        let voice = pick(index) ?? AVSpeechSynthesisVoice(language: conversation.language)
        let firstVoice = pick(0)
        let sharesVoice = index != 0 && voice?.identifier == firstVoice?.identifier
        return (voice, sharesVoice ? 0.85 : 1.0)
    }
}
