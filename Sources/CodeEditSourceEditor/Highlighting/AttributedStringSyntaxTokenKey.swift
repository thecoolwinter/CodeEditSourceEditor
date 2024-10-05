//
//  AttributedStringSyntaxTokenKey.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 9/30/24.
//

import Foundation

extension NSAttributedString.Key {
    public static let syntaxToken: NSAttributedString.Key = .init("syntaxtoken")
}

public struct SyntaxTokenAttributeData {
    public var capture: CaptureName?
    public var modifiers: Set<SemanticTokenModifiers>
    public var sources: Set<Int>

    public init(capture: CaptureName?, modifiers: Set<SemanticTokenModifiers>, sources: Set<Int>) {
        self.capture = capture
        self.modifiers = modifiers
        self.sources = sources
    }
}
