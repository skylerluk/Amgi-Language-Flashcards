//
//  SelectableLineText.swift
//  ReaderFeature
//

import SwiftUI
import UIKit

/// A read-only line of dialogue whose words can be selected. The selection
/// menu leads with "English" and "Ask DeepSeek", ahead of the system items.
/// A plain single tap is passed through as `onTap` (it toggles the line's
/// translation), and waits for the text view's own double-tap so selecting a
/// word doesn't also toggle the translation.
struct SelectableLineText: UIViewRepresentable {
    let text: String
    let color: UIColor
    var onTap: () -> Void
    var onTranslate: (String) -> Void
    var onAsk: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = true
        view.font = .preferredFont(forTextStyle: .body)
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        tap.cancelsTouchesInView = false
        for recognizer in view.gestureRecognizers ?? [] {
            if let other = recognizer as? UITapGestureRecognizer, other.numberOfTapsRequired == 2 {
                tap.require(toFail: other)
            }
        }
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        if view.text != text { view.text = text }
        view.textColor = color
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 280
        let fit = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fit.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: SelectableLineText

        init(parent: SelectableLineText) {
            self.parent = parent
        }

        @objc func tapped(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? UITextView else { return }
            if view.selectedRange.length > 0 {
                // A tap while words are selected just clears the selection.
                view.selectedRange = NSRange(location: 0, length: 0)
                return
            }
            parent.onTap()
        }

        func textView(
            _ textView: UITextView,
            editMenuForTextIn range: NSRange,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            guard let swiftRange = Range(range, in: textView.text ?? "") else { return nil }
            let selected = String((textView.text ?? "")[swiftRange])
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            guard !selected.isEmpty else { return UIMenu(children: suggestedActions) }

            let translate = UIAction(title: "English", image: UIImage(systemName: "character.bubble")) { [weak self] _ in
                self?.parent.onTranslate(selected)
            }
            let ask = UIAction(title: "Ask DeepSeek", image: UIImage(systemName: "sparkles")) { [weak self] _ in
                self?.parent.onAsk(selected)
            }
            return UIMenu(children: [translate, ask] + suggestedActions)
        }
    }
}
