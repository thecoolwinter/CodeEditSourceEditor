//
//  Highlighter+VisibleSet.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/1/24.
//

import AppKit
import CodeEditTextView

extension Highlighter {
    func updateVisibleSet(textView: TextView) {
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
        } else {
            return
        }

        updateVisibleSet(textView: textView)

        for idx in 0..<indexStates.count {
            // Any indices that are both *not* valid and in the visible text range should be invalidated
            let newlyInvalidSet = visibleSet.subtracting(indexStates[idx].validSet)

            for range in newlyInvalidSet.rangeView.map({ NSRange($0) }) {
                invalidate(range: range, for: idx)
            }
        }
    }
}
