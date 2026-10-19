import AppKit
import SwiftUI

// NSTextView handles large bodies and the find bar far better than SwiftUI Text.
struct BodyTextView: NSViewRepresentable {
    let rendered: RenderedBody?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.layoutManager?.allowsNonContiguousLayout = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView, let storage = textView.textStorage else { return }
        guard context.coordinator.rendered != rendered else { return }
        context.coordinator.rendered = rendered
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        storage.beginEditing()
        storage.setAttributedString(NSAttributedString(string: rendered?.text ?? "", attributes: [.font: font, .foregroundColor: NSColor.labelColor]))
        for (range, token) in rendered?.highlights ?? [] {
            storage.addAttribute(.foregroundColor, value: token.color, range: range)
        }
        storage.endEditing()
        textView.scrollToBeginningOfDocument(nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var rendered: RenderedBody?
    }
}

private extension RenderedBody.Token {
    var color: NSColor {
        switch self {
        case .key: .systemBlue
        case .string: .systemRed
        case .number: .systemPurple
        case .literal: .systemOrange
        }
    }
}
