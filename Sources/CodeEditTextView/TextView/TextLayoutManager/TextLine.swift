//
//  TextLine.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

/// Represents a displayable line of text.
final class TextLine: Identifiable {
    let id: UUID = UUID()
    unowned var stringRef: NSTextStorage
    var maxWidth: CGFloat?
    let typesetter: Typesetter = Typesetter()

    init(stringRef: NSTextStorage) {
        self.stringRef = stringRef
    }

    func prepareForDisplay(maxWidth: CGFloat, lineHeightMultiplier: CGFloat, range: NSRange) {
        self.maxWidth = maxWidth
        typesetter.prepareToTypeset(
            stringRef.attributedSubstring(from: range),
            maxWidth: maxWidth,
            lineHeightMultiplier: lineHeightMultiplier
        )
    }
}
