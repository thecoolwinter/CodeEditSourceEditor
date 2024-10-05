//
//  Array+mutatingForEach.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/1/24.
//

import Foundation

extension Array {
    mutating func mutatingForEach(_ body: (inout Element) throws -> Void) rethrows {
        for idx in 0..<self.count {
            try body(&self[idx])
        }
    }
}
