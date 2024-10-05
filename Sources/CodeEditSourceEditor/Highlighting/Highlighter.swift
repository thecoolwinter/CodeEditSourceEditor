//
//  Highlighter.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/12/22.
//

import Foundation
import AppKit
import CodeEditTextView
import SwiftTreeSitter
import CodeEditLanguages
import OSLog

/// The `Highlighter` class handles efficiently highlighting the `TextView` it's provided with.
/// It will listen for text and visibility changes, and highlight syntax as needed.
///
/// One should rarely have to directly modify or call methods on this class. Just keep it alive in
/// memory and it will listen for bounds changes, text changes, etc. However, to completely invalidate all
/// highlights use the ``invalidate()`` method to re-highlight all (visible) text, and the ``setLanguage``
/// method to update the highlighter with a new language if needed.
@MainActor
class Highlighter: NSObject {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "Highlighter")

    // MARK: - Index Sets

    struct IndexState {
        /// Any indexes that highlights have been requested for, but haven't been applied.
        /// Indexes/ranges are added to this when highlights are requested and removed
        /// after they are applied
        var pendingSet: IndexSet = .init()
        /// The set of valid indexes
        var validSet: IndexSet = .init()
    }

    /// The set of visible indexes in the text view
    lazy var visibleSet: IndexSet = {
        return IndexSet(integersIn: textView?.visibleTextRange ?? NSRange())
    }()

    // MARK: - UI

    /// The text view to highlight
    weak var textView: TextView?

    /// The editor theme
    private var theme: EditorTheme

    /// The object providing attributes for captures.
    private weak var attributeProvider: ThemeAttributesProviding?

    /// The current language of the editor.
    private var language: CodeLanguage

    /// Calculates invalidated ranges given an edit.
    var highlightProviders: [HighlightProviding]

    /// The highlighting state of all highlight providers
    var indexStates: [IndexState]

    /// The length to chunk ranges into when passing to the highlighter.
    private let rangeChunkLimit = 1024

    // MARK: - Init

    /// Initializes the `Highlighter`
    /// - Parameters:
    ///   - textView: The text view to highlight.
    ///   - treeSitterClient: The tree-sitter client to handle tree updates and highlight queries.
    ///   - theme: The theme to use for highlights.
    init(
        textView: TextView,
        highlightProviders: [HighlightProviding],
        theme: EditorTheme,
        attributeProvider: ThemeAttributesProviding,
        language: CodeLanguage
    ) {
        self.textView = textView
        self.highlightProviders = highlightProviders
        self.indexStates = highlightProviders.map { _ in IndexState() }
        self.theme = theme
        self.attributeProvider = attributeProvider
        self.language = language

        super.init()

        highlightProviders.forEach {
            $0.setUp(textView: textView, codeLanguage: language)
        }

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
        }
    }

    // MARK: - Public

    /// Invalidates all text in the textview. Useful for updating themes.
    public func invalidate() {
        guard let textView else { return }
        updateVisibleSet(textView: textView)
        for idx in 0..<indexStates.count {
            invalidate(range: textView.documentRange, for: idx)
        }
    }

    /// Sets the language and causes a re-highlight of the entire text.
    /// - Parameter language: The language to update to.
    public func setLanguage(language: CodeLanguage) {
        guard let textView = self.textView else { return }
        // Remove all current highlights. Makes the language setting feel snappier and tells the user we're doing
        // something immediately.
        textView.textStorage.setAttributes(
            attributeProvider?.attributesFor(nil) ?? [:],
            range: NSRange(location: 0, length: textView.textStorage.length)
        )
        textView.layoutManager.invalidateLayoutForRect(textView.visibleRect)
        indexStates.removeAll()
        highlightProviders.forEach {
            indexStates.append(IndexState())
            $0.setUp(textView: textView, codeLanguage: language)
        }
        invalidate()
    }

    /// Sets the highlight provider. Will cause a re-highlight of the entire text.
    /// - Parameter provider: The provider to use for future syntax highlights.
    public func setHighlightProviders(_ providers: [HighlightProviding]) {
        self.highlightProviders = providers
        guard let textView = self.textView else { return }
        indexStates.removeAll()
        highlightProviders.forEach {
            $0.setUp(textView: textView, codeLanguage: language)
            indexStates.append(IndexState())
        }
        invalidate()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.attributeProvider = nil
        self.textView = nil
        self.highlightProviders = []
    }
}

// MARK: - Highlighting

extension Highlighter {

    /// Invalidates a given range and adds it to the queue to be highlighted.
    /// - Parameter range: The range to invalidate.
    func invalidate(range: NSRange, for idx: Int) {
        let set = IndexSet(integersIn: range)

        if set.isEmpty {
            return
        }

        indexStates[idx].validSet.subtract(set)

        highlightInvalidRanges(for: idx)
    }

    /// Begins highlighting any invalid ranges
    func highlightInvalidRanges(for idx: Int) {
        // If there aren't any more ranges to highlight, don't do anything, otherwise continue highlighting
        // any available ranges.
        var rangesToQuery: [NSRange] = []
        while let range = getNextRange(indexStates[idx]) {
            rangesToQuery.append(range)
            indexStates[idx].pendingSet.insert(range: range)
        }

        queryHighlights(for: rangesToQuery, using: highlightProviders[idx], at: idx)
    }

    /// Gets the next `NSRange` to highlight based on the invalid set, visible set, and pending set.
    /// - Returns: An `NSRange` to highlight if it could be fetched.
    func getNextRange(_ state: borrowing IndexState) -> NSRange? {
        let set: IndexSet = IndexSet(integersIn: textView?.documentRange ?? .zero) // All text
            .subtracting(state.validSet) // Subtract valid = Invalid set
            .intersection(visibleSet) // Only visible indexes
            .subtracting(state.pendingSet) // Don't include pending indexes

        guard let range = set.rangeView.first else {
            return nil
        }

        // Chunk the ranges in sets of rangeChunkLimit characters.
        return NSRange(
            location: range.lowerBound,
            length: min(rangeChunkLimit, range.upperBound - range.lowerBound)
        )
    }

    /// Highlights the given ranges
    /// - Parameter ranges: The ranges to request highlights for.
    func queryHighlights(for rangesToHighlight: [NSRange], using provider: HighlightProviding, at providerIdx: Int) {
        guard let textView else { return }

        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                for range in rangesToHighlight {
                    provider.queryHighlightsFor(
                        textView: textView,
                        range: range
                    ) { [weak self] highlights in
                        assert(Thread.isMainThread, "Highlighted ranges called on non-main thread.")
                        self?.applyQueryResult(highlights, rangeToHighlight: range, providerIdx: providerIdx)
                    }
                }
            }
        } else {
            for range in rangesToHighlight {
                provider.queryHighlightsFor(textView: textView, range: range) { [weak self] highlights in
                    assert(Thread.isMainThread, "Highlighted ranges called on non-main thread.")
                    self?.applyQueryResult(highlights, rangeToHighlight: range, providerIdx: providerIdx)
                }
            }
        }
    }

    /// Applies a highlight query result to the text view.
    /// - Parameters:
    ///   - queryResult: The result of a highlight query.
    ///   - rangeToHighlight: The range to apply the highlight to.
    private func applyQueryResult(
        _ queryResult: Result<[HighlightRange], Error>,
        rangeToHighlight: NSRange,
        providerIdx: Int
    ) {
        if indexStates.count > providerIdx {
            indexStates[providerIdx].pendingSet.remove(integersIn: rangeToHighlight)
        }

        switch queryResult {
        case let .failure(error):
            if case HighlightProvidingError.operationCancelled = error {
                invalidate(range: rangeToHighlight, for: providerIdx)
            } else {
                Self.logger.error("Failed to query highlight range: \(error)")
            }
        case let .success(highlights):
            applyHighlightsToStorage(in: rangeToHighlight, highlights: highlights, providerIdx: providerIdx)
        }
    }

    /// Applies given highlights to the storage object.
    /// - Parameters:
    ///   - rangeToHighlight: The range being queried for.
    ///   - highlights: The highlights to apply to the range.
    private func applyHighlightsToStorage(
        in rangeToHighlight: NSRange,
        highlights: [HighlightRange],
        providerIdx: Int
    ) {
        guard self.indexStates.count > providerIdx,
              visibleSet.intersects(integersIn: rangeToHighlight),
              let textView,
              let textStorage = textView.textStorage else {
            return
        }

        indexStates[providerIdx].validSet.formUnion(IndexSet(integersIn: rangeToHighlight))

        // Loop through each highlight and modify the textStorage accordingly.
        textView.layoutManager.beginTransaction()
        textStorage.beginEditing()

        // Create a set of indexes that were not highlighted.
        var ignoredIndexes = IndexSet(integersIn: rangeToHighlight)

        setStorageHighlights(
            highlights: highlights,
            using: textView,
            textStorage: textStorage,
            providerIdx: providerIdx,
            ignoredIndexes: &ignoredIndexes
        )
        removeHighlights(in: ignoredIndexes, using: textView, textStorage: textStorage, providerIdx: providerIdx)

        textStorage.endEditing()
        textView.layoutManager.endTransaction()
        textView.layoutManager.invalidateLayoutForRange(rangeToHighlight)
    }

    /// Sets the storage object to contain all the given highlights, as well as applying highlighting attributes.
    private func setStorageHighlights(
        highlights: [HighlightRange],
        using textView: TextView,
        textStorage: NSTextStorage,
        providerIdx: Int,
        ignoredIndexes: inout IndexSet
    ) {
        // Apply all highlights that need color
        for highlight in highlights
        where textView.documentRange.upperBound ?? 0 > highlight.range.upperBound {
            var syntaxToken: SyntaxTokenAttributeData
            if var existingToken = getExistingTokenData(for: highlight.range, storage: textStorage) {
                existingToken.capture = highlight.capture ?? existingToken.capture
                existingToken.modifiers.formUnion(highlight.modifiers)
                existingToken.sources.insert(providerIdx)
                syntaxToken = existingToken
            } else {
                syntaxToken = SyntaxTokenAttributeData(
                    capture: highlight.capture,
                    modifiers: highlight.modifiers,
                    sources: [providerIdx]
                )
            }
            var attributes = attributeProvider?.attributesFor(syntaxToken) ?? [:]
            attributes[.syntaxToken] = syntaxToken
            textStorage.setAttributes(
                attributes,
                range: highlight.range
            )

            // Remove highlighted indexes from the "ignored" indexes.
            ignoredIndexes.remove(integersIn: highlight.range)
        }
    }

    /// For any indices left over, we need to apply normal attributes to them
    /// This fixes the case where characters are changed to have a non-text color, and then are skipped when
    /// they need to be changed back.
    private func removeHighlights(
        in ignoredIndexes: IndexSet,
        using textView: TextView,
        textStorage: NSTextStorage,
        providerIdx: Int
    ) {
        var blankAttributes = attributeProvider?.attributesFor(nil) ?? [:]
        for ignoredRange in ignoredIndexes.rangeView
        where textView.documentRange.upperBound > ignoredRange.upperBound {
            var syntaxData: [NSRange: SyntaxTokenAttributeData] = [:]
            // remove the .syntaxToken attribute key if the sources set is empty after removing ourselves.
            textStorage.enumerateAttribute(.syntaxToken, in: NSRange(ignoredRange)) { value, range, _ in
                guard var value = value as? SyntaxTokenAttributeData else { return }
                value.sources.remove(providerIdx)
                if !value.sources.isEmpty {
                    syntaxData[range] = value
                }
            }

            // Fix up remaining tokens
            for (range, data) in syntaxData {
                textStorage.addAttributes([.syntaxToken: data], range: range)
            }
        }
    }

    /// Finds an existing syntax token data at the given location.
    /// Returning attribute data only if the found attribute has the same endpoint as the given range.
    private func getExistingTokenData(
        for range: NSRange,
        storage: NSTextStorage
    ) -> SyntaxTokenAttributeData? {
        var entireRange = NSRange.zero
        return withUnsafeMutablePointer(to: &entireRange) { rangePtr in
            if let token = storage.attribute(
                .syntaxToken,
                at: range.location,
                effectiveRange: rangePtr
            ) as? SyntaxTokenAttributeData {
                return rangePtr.pointee.max == range.max ? token : nil
            }
            return nil
        }
    }
}
