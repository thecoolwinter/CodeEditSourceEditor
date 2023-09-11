//
//  TextViewDelegate.swift
//  
//
//  Created by Khan Winter on 9/3/23.
//

import Foundation

public protocol TextViewDelegate: AnyObject {
    func textView(_ textView: TextView, willReplaceContentsIn range: NSRange, with: String)
    func textView(_ textView: TextView, didReplaceContentsIn range: NSRange, with: String)
    func textView(_ textView: TextView, shouldReplaceContentsIn range: NSRange, with: String) -> Bool
}

public extension TextViewDelegate {
    func textView(_ textView: TextView, willReplaceContentsIn range: NSRange, with: String) { }
    func textView(_ textView: TextView, didReplaceContentsIn range: NSRange, with: String) { }
    func textView(_ textView: TextView, shouldReplaceContentsIn range: NSRange, with: String) -> Bool { true }
}
