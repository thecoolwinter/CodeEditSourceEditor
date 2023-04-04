//
//  LineFragment.swift
//  
//
//  Created by Khan Winter on 3/27/23.
//

import Cocoa
import STTextView

extension STTextViewController: NSTextLayoutManagerDelegate {

    public func textLayoutManager(
        _ textLayoutManager: NSTextLayoutManager,
        textLayoutFragmentFor location: NSTextLocation,
        in textElement: NSTextElement
    ) -> NSTextLayoutFragment {
        LineFragment(
            textElement: textElement,
            range: textElement.elementRange,
            paragraphStyle: paragraphStyle,
            attributes: attributesFor(nil)
        )
    }

}

enum InvisibleCharacters {
    static let tab: Character = "\t"
    static let space: Character = " "
    static let nonBreakingSpace: Character = "\u{A0}"
    static let newline: Character = "\n"
    static let carriageReturn: Character = "\r"
    static let lineSeparator: Character = "\u{2028}"

    enum Replacement {
        static let tab: Character = "»"
        static let space: Character = "·"
        static let nonBreakingSpace: Character = "·"
        static let newline: Character = "¬"
        static let carriageReturn: Character = "¤"
        static let lineSeparator: Character = "¬"
    }
}

final class LineFragment: NSTextLayoutFragment {
    private let paragraphStyle: NSParagraphStyle
    private let attributes: [NSAttributedString.Key: Any]

    init(
        textElement: NSTextElement,
        range rangeInElement: NSTextRange?,
        paragraphStyle: NSParagraphStyle,
        attributes: [NSAttributedString.Key: Any]
    ) {
        self.paragraphStyle = paragraphStyle
        self.attributes = attributes
        super.init(textElement: textElement, range: rangeInElement)
    }

    required init?(coder: NSCoder) {
        self.paragraphStyle = .default
        self.attributes = [:]
        super.init(coder: coder)
    }

    override func draw(at point: CGPoint, in context: CGContext) {
        for lineFragment in textLineFragments {
            lineFragment.draw(at: lineFragment.typographicBounds.origin, in: context)

            for (idx, substring) in lineFragment.attributedString.string.enumerated() {
                if let replacement = getInvisibleCharacter(for: substring) {
                    context.saveGState()
                    let pos = lineFragment.locationForCharacter(at: idx)
                    let attributedString = NSAttributedString(
                        string: String(replacement),
                        attributes: attributes
                    )

                    let line = CTLineCreateWithAttributedString(attributedString)

                    context.textMatrix = .init(scaleX: 1, y: -1)
                    context.translateBy(
                        x: pos.x,
                        y: (pos.y)/2
                    )
                    CTLineDraw(line, context)
                    context.restoreGState()
                }
            }
        }
    }

    private func getInvisibleCharacter(for character: Character) -> Character? {
        switch character {
        case InvisibleCharacters.tab: return InvisibleCharacters.Replacement.tab
        case InvisibleCharacters.space: return InvisibleCharacters.Replacement.space
        case InvisibleCharacters.nonBreakingSpace: return InvisibleCharacters.Replacement.nonBreakingSpace
        case InvisibleCharacters.newline: return InvisibleCharacters.Replacement.newline
        case InvisibleCharacters.carriageReturn: return InvisibleCharacters.Replacement.carriageReturn
        case InvisibleCharacters.lineSeparator: return InvisibleCharacters.Replacement.lineSeparator
        default:
            return nil
        }
    }
}
