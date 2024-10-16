//
//  VisibleRangeProvider.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/13/24.
//

import AppKit
import CodeEditTextView

class VisibleRangeProvider {
    private weak var textView: TextView?

    var documentRange: NSRange {
        textView?.documentRange ?? .notFound
    }

    /// The set of visible indexes in the text view
    lazy var visibleSet: IndexSet = {
        return IndexSet(integersIn: textView?.visibleTextRange ?? NSRange())
    }()

    init(textView: TextView) {
        self.textView = textView

        if let scrollView = textView.enclosingScrollView {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.frameDidChangeNotification,
                object: scrollView
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(visibleTextChanged(_:)),
                name: NSView.frameDidChangeNotification,
                object: textView
            )
        }
    }

    private func updateVisibleSet(textView: TextView) {
        if let newVisibleRange = textView.visibleTextRange {
            visibleSet = IndexSet(integersIn: newVisibleRange)
        }
    }

    /// Updates the view to highlight newly visible text when the textview is scrolled or bounds change.
    @objc func visibleTextChanged(_ notification: Notification) {
        let textView: TextView
        if let clipView = notification.object as? NSClipView,
           let documentView = clipView.enclosingScrollView?.documentView as? TextView {
            textView = documentView
        } else if let scrollView = notification.object as? NSScrollView,
                  let documentView = scrollView.documentView as? TextView {
            textView = documentView
        } else if let documentView = notification.object as? TextView {
            textView = documentView
        } else {
            return
        }

        updateVisibleSet(textView: textView)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
