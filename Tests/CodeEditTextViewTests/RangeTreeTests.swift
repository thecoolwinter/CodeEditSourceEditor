import XCTest
@testable import TextStorage

final class RangeTreeTests: XCTestCase {

    func test_treeValidity() {
        let tree = RangeTree()
        tree.insert(NSObject(), NSRange(location: 5, length: 1))
        tree.insert(NSObject(), NSRange(location: 0, length: 1))
        tree.insert(NSObject(), NSRange(location: 2, length: 2))
        tree.insert(NSObject(), NSRange(location: 10, length: 1))
        tree.insert(NSObject(), NSRange(location: 7, length: 2))
        tree.insert(NSObject(), NSRange(location: 11, length: 1))
        tree.insert(NSObject(), NSRange(location: 12, length: 1))
        tree.insert(NSObject(), NSRange(location: 13, length: 1))
        tree.insert(NSObject(), NSRange(location: 14, length: 1))
        tree.insert(NSObject(), NSRange(location: 15, length: 1))
        tree.insert(NSObject(), NSRange(location: 16, length: 1))
        tree.insert(NSObject(), NSRange(location: 17, length: 1))
        tree.insert(NSObject(), NSRange(location: 18, length: 1))

        tree.del(NSRange(location: 10, length: 1))
        tree.del(NSRange(location: 11, length: 1))
        tree.del(NSRange(location: 13, length: 1))
        tree.del(NSRange(location: 17, length: 1))

        XCTAssert(tree.root != nil)
        XCTAssert(tree.root?.color == .black)
        XCTAssert(tree.count ==  13)

        // If a node is red, it's children must be black
        func checkChildrenColorCorrectness(_ node: RangeTreeNode) {
            if node.color == .red {
                if let left = node.left {
                    XCTAssert(left.color == .black)
                }
                if let right = node.right {
                    XCTAssert(right.color == .black)
                }
            }

            if let left = node.left {
                checkChildrenColorCorrectness(left)
            }
            if let right = node.right {
                checkChildrenColorCorrectness(right)
            }
        }

        checkChildrenColorCorrectness(tree.root!)
    }

    func test_pieceTable() {
        let originalString = "Hello World!\nNew Line Stored!"
        let table = PieceTable(string: originalString)
        XCTAssert(table.character(at: 0) == "H".utf16.first!)
        XCTAssert(table.character(at: 1) == "e".utf16.first!)

        let buffer = UnsafeMutablePointer<unichar>.allocate(capacity: table.length)
        table.getCharacters(buffer)
        let string = String(utf16CodeUnits: buffer, count: table.length)
        XCTAssert(originalString == string)
        buffer.deallocate()

        table.replaceCharacters(in: NSRange(location: 0, length: 0), with: "This is inserted\n")
        let buffer2 = UnsafeMutablePointer<unichar>.allocate(capacity: table.length)
        table.getCharacters(buffer)
        let string2 = String(utf16CodeUnits: buffer, count: table.length)
        XCTAssert("This is inserted\n" + originalString == string2, "\"\("This is inserted\n" + originalString)\"\nIs not equal to:\n\"\(string)\"")
        buffer2.deallocate()
    }

}
