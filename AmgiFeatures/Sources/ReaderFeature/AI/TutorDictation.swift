import Foundation
import Observation
@preconcurrency import Speech
@preconcurrency import AVFoundation

/// Recording belongs to a single tutor turn. A generation token rejects callbacks
/// from a cancelled recognizer, including those arriving after a language switch.
@Observable @MainActor
final class TutorDictation {
    private(set) var transcript = ""
    private(set) var isRecording = false
    private(set) var isStarting = false
    var errorMessage: String?
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognition: SFSpeechRecognitionTask?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var hasTap = false
    @ObservationIgnored private var timeout: Task<Void, Never>?

    func start(language: String) async {
        guard !isStarting, !isRecording else { return }
        stop()
        let token = generation
        isStarting = true
        errorMessage = nil
        defer { if token == generation { isStarting = false } }
        let permission = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard token == generation else { return }
        guard permission == .authorized else {
            errorMessage = "Enable Speech Recognition for Amgi in Settings, or type your reply."
            return
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard token == generation else { return }
        guard microphone else {
            errorMessage = "Enable Microphone for Amgi in Settings, or type your reply."
            return
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)), recognizer.isAvailable else {
            errorMessage = "Speech recognition is unavailable for this language right now. Check your connection or type your reply."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
            request.taskHint = .dictation
            self.request = request
            transcript = ""
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw NSError(domain: "Dictation", code: 1, userInfo: [NSLocalizedDescriptionKey: "No microphone input is available."])
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            hasTap = true
            recognition = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let final = result?.isFinal == true
                let failure = error?.localizedDescription
                Task { @MainActor [weak self] in
                    guard let self, self.generation == token else { return }
                    if let text { self.transcript = text }
                    if final || failure != nil {
                        self.stop()
                        if let failure, self.transcript.isEmpty { self.errorMessage = failure }
                    }
                }
            }
            engine.prepare()
            try engine.start()
            isRecording = true
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(55))
                guard !Task.isCancelled, let self, self.generation == token else { return }
                self.stop()
                if self.transcript.isEmpty { self.errorMessage = "No speech detected. Tap the microphone to try again." }
            }
        } catch {
            stop()
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        generation = UUID()
        timeout?.cancel()
        timeout = nil
        engine.stop()
        if hasTap { engine.inputNode.removeTap(onBus: 0); hasTap = false }
        request?.endAudio()
        recognition?.cancel()
        recognition = nil
        request = nil
        if isRecording || isStarting { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        isRecording = false
        isStarting = false
    }
}
