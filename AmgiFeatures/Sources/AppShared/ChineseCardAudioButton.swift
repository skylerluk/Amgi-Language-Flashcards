package import SwiftUI
import AVFoundation

package struct ChineseCardAudioButton: View {
    let text: String
    @State private var speech = AVSpeechSynthesizer()
    package init(text: String) { self.text = text }
    package var body: some View {
        Button("Listen", systemImage: "speaker.wave.2") {
            speech.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.rate = 0.43
            speech.speak(utterance)
        }
        .accessibilityLabel("Listen to Chinese")
        .onChange(of: text) { speech.stopSpeaking(at: .immediate) }
        .onDisappear { speech.stopSpeaking(at: .immediate) }
    }
}
