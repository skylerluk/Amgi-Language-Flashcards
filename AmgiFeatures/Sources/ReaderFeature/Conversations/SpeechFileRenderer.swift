//
//  SpeechFileRenderer.swift
//  ReaderFeature
//

import AVFoundation
import Foundation

/// Renders an utterance to an AAC `.m4a` in the temporary directory, so a
/// conversation line can go onto a flashcard as real audio that plays and
/// syncs like any other Anki `[sound:…]` file.
enum SpeechFileRenderer {
    enum Failure: Error { case noAudio }

    @MainActor
    static func render(_ utterance: AVSpeechUtterance) async throws -> URL {
        let job = Job()
        return try await withCheckedThrowingContinuation { continuation in
            job.start(utterance, continuation: continuation)
        }
    }

    /// Holds the synthesizer and output file for the life of one render.
    /// `AVSpeechSynthesizer.write` delivers buffers serially on its own
    /// queue; nothing else touches this object while it runs.
    private final class Job: @unchecked Sendable {
        private let synthesizer = AVSpeechSynthesizer()
        private let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("amgi-tts-\(UUID().uuidString.prefix(8)).m4a")
        private var file: AVAudioFile?
        private var continuation: CheckedContinuation<URL, any Error>?

        func start(_ utterance: AVSpeechUtterance, continuation: CheckedContinuation<URL, any Error>) {
            self.continuation = continuation
            synthesizer.write(utterance) { [self] buffer in
                guard let pcm = buffer as? AVAudioPCMBuffer else { return }
                // A zero-length buffer marks the end of the utterance.
                guard pcm.frameLength > 0 else {
                    finish()
                    return
                }
                do {
                    if file == nil {
                        let settings: [String: Any] = [
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: pcm.format.sampleRate,
                            AVNumberOfChannelsKey: pcm.format.channelCount,
                        ]
                        file = try AVAudioFile(
                            forWriting: url,
                            settings: settings,
                            commonFormat: pcm.format.commonFormat,
                            interleaved: pcm.format.isInterleaved
                        )
                    }
                    try file?.write(from: pcm)
                } catch {
                    fail(error)
                }
            }
        }

        private func finish() {
            guard let continuation else { return }
            self.continuation = nil
            let wroteAudio = file != nil
            file = nil // closes the file
            if wroteAudio {
                continuation.resume(returning: url)
            } else {
                continuation.resume(throwing: Failure.noAudio)
            }
        }

        private func fail(_ error: any Error) {
            guard let continuation else { return }
            self.continuation = nil
            file = nil
            try? FileManager.default.removeItem(at: url)
            continuation.resume(throwing: error)
        }
    }
}
