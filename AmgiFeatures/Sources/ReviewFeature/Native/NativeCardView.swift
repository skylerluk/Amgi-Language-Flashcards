//
//  NativeCardView.swift
//  ReviewFeature
//
//  Created by Vladimir Gusev on 20.07.2026.
//

import SwiftUI
import Foundation
import UI
import Theme
import AmgiCardWeb
#if canImport(UIKit)
import UIKit
#endif

/// Native SwiftUI renderer for allowlist-simple cards (R11). Renders the
/// side's parsed blocks on a radius-24 `AmgiCard` surface: the first text
/// block is the serif headword (large on the front, reduced on the back —
/// Anki back HTML already contains `{{FrontSide}}` plus an `<hr>` divider),
/// remaining text blocks are body copy, `<hr>` becomes a hairline.
struct NativeCardView: View {
    let content: NativeCardContent
    let isAnswerSide: Bool
    let mediaFolder: URL?

    @Environment(\.palette) private var palette

    @ScaledMetric(relativeTo: .largeTitle) private var headwordFront: CGFloat = 48
    @ScaledMetric(relativeTo: .title) private var headwordBack: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 20

    var body: some View {
        ScrollView {
            AmgiCard(
                background: .surface,
                cornerRadius: AmgiRadius.card,
                contentInsets: EdgeInsets(top: 40, leading: 24, bottom: 40, trailing: 24)
            ) {
                VStack(spacing: AmgiSpacing.lg) {
                    ForEach(Array(content.blocks.enumerated()), id: \.offset) { index, block in
                        blockView(block, isFirst: index == firstTextIndex)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var firstTextIndex: Int? {
        content.blocks.firstIndex {
            if case .text = $0 { return true }
            return false
        }
    }

    @ViewBuilder
    private func blockView(_ block: NativeCardContent.Block, isFirst: Bool) -> some View {
        switch block {
        case .text(let attributed):
            #if canImport(UIKit)
            SelectableCardText(
                text: attributed,
                fontSize: isFirst ? (isAnswerSide ? headwordBack : headwordFront) : bodySize,
                emphasized: isFirst,
                color: UIColor(palette.textPrimary)
            )
            #else
            Text(attributed)
                .font(.system(size: isFirst ? (isAnswerSide ? headwordBack : headwordFront) : bodySize,
                              weight: isFirst ? .semibold : .regular, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textPrimary)
                .textSelection(.enabled)
            #endif
        case .image(let filename):
            // Decoded and downsampled off the main thread — a full-resolution
            // decode here lands squarely in the answer-reveal frame.
            DownsampledImage(
                url: mediaFolder?.appendingPathComponent(filename),
                maxPixelSize: AmgiImagePixelSize.card
            ) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: AmgiRadius.small, style: .continuous))
            } placeholder: {
                EmptyView()
            }
        case .divider:
            Rectangle()
                .fill(palette.separator)
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
    }
}

#if canImport(UIKit)
/// UITextView exposes iOS's selection handles and Look Up / Translate menu,
/// including selection of individual Chinese words inside an example sentence.
private struct SelectableCardText: UIViewRepresentable {
    let text: AttributedString
    let fontSize: CGFloat
    let emphasized: Bool
    let color: UIColor

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let value = NSMutableAttributedString(text)
        let range = NSRange(location: 0, length: value.length)
        var offset = 0
        for run in text.runs {
            let length = String(text[run.range].characters).utf16.count
            let intent = run.inlinePresentationIntent ?? []
            let font = UIFont.systemFont(ofSize: fontSize,
                weight: emphasized || intent.contains(.stronglyEmphasized) ? .semibold : .regular)
            var descriptor = font.fontDescriptor.withDesign(.serif) ?? font.fontDescriptor
            if intent.contains(.emphasized) {
                descriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) ?? descriptor
            }
            value.addAttribute(.font, value: UIFont(descriptor: descriptor, size: fontSize),
                               range: NSRange(location: offset, length: length))
            offset += length
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        value.addAttributes([.foregroundColor: color, .paragraphStyle: paragraph], range: range)
        if !view.attributedText.isEqual(to: value) {
            view.attributedText = value
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 280
        let fit = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fit.height))
    }
}
#endif

#if DEBUG
#Preview("Front") {
    NativeCardView(
        content: .parse(html: "猫"),
        isAnswerSide: false,
        mediaFolder: nil
    )
}

#Preview("Back") {
    NativeCardView(
        content: .parse(html: "猫<hr>cat<br><i>The cat sat on the mat.</i>"),
        isAnswerSide: true,
        mediaFolder: nil
    )
}
#endif
