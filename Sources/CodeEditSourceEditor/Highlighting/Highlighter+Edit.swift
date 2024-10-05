//
//  Highlighter+Edit.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/1/24.
//

import AppKit

extension Highlighter {
    func storageDidEdit(editedRange: NSRange, delta: Int) {
        guard let textView else { return }

        let range = NSRange(location: editedRange.location, length: editedRange.length - delta)
        if delta > 0 {
            visibleSet.insert(range: editedRange)
        }

        updateVisibleSet(textView: textView)

        for index in 0..<highlightProviders.count {
            let provider = highlightProviders[index]
            provider.applyEdit(textView: textView, range: range, delta: delta) { [weak self] result in
                switch result {
                case let .success(invalidIndexSet):
                    let indexSet = invalidIndexSet.union(IndexSet(integersIn: editedRange))

                    for range in indexSet.rangeView {
                        self?.invalidate(range: NSRange(range), for: index)
                    }
                case let .failure(error):
                    if case HighlightProvidingError.operationCancelled = error {
                        self?.invalidate(range: range, for: index)
                        return
                    } else {
                        Self.logger.error("Failed to apply edit. Query returned with error: \(error)")
                    }
                }
            }
        }
    }

    func storageWillEdit(editedRange: NSRange) {
        guard let textView else { return }
        highlightProviders.forEach {
            $0.willApplyEdit(textView: textView, range: editedRange)
        }
    }
}
