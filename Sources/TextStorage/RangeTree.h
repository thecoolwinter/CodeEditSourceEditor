//
//  RangeTree.h
//  
//
//  Created by Khan Winter on 6/5/23.
//

#import <Foundation/Foundation.h>
#import "RangeTreeNodeColor.h"
#import "RangeTreeNode.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - Tree

/// A data structure for storing and retrieving objects associated with ranges.
/// Internally uses a red-black tree to effciently query large amounts of ranges.
@interface RangeTree : NSObject

@property NSInteger count;
@property(nullable) RangeTreeNode* root;
/// A circular cache for previously found nodes.
@property(nonnull) NSMutableArray<RangeTreeNode*>* cachedNodes;
@property NSUInteger cachedNodesFront;

- (instancetype)init;

- (nullable id<NSObject>)get:(NSUInteger) key;

/// Inserts the given object into the tree at the given key.
/// If the key overlaps with existing keys in the tree an `NSRangeException` will be thrown.
/// If the key matches an existing key exactly, the value for that will be replaced.
/// - Parameters:
///   - object: The object to insert.
///   - key: The key to insert it with.
- (void)insert:(nonnull id<NSObject>)object
              :(NSRange)key;
- (void)del:(NSRange)key;

- (nullable RangeTreeNode*)_searchTree:(NSUInteger)key;
- (void)_insertFix:(RangeTreeNode*)node;
- (void)_delFix:(RangeTreeNode*)node;
- (void)_rotateLeft:(RangeTreeNode *)node;
- (void)_rotateRight:(RangeTreeNode *)node;
- (void)_rotate:(RangeTreeNode *)node
           left:(bool)isLeft;

- (void)_raiseRangeException:(NSRange)key
                            :(NSRange)existingRange;

@end

NS_ASSUME_NONNULL_END

/*
 * Nearly identical delete operation as in a binary search tree
 * Differences: All nil pointers are replaced by the nullLeaf,
 * after deleting we call insertFixup to maintain the red-black properties if the delted node was
 * black (as if it was red -> no violation of red-black properties)
private func delete(node z: RBNode) {
    var nodeY = RBNode()
    var nodeX = RBNode()
    if let leftChild = z.leftChild, let rightChild = z.rightChild {
        if leftChild.isNullLeaf || rightChild.isNullLeaf {
            nodeY = z
        } else {
            if let successor = z.getSuccessor() {
                nodeY = successor
            }
                }
    }
    if let leftChild = nodeY.leftChild {
        if !leftChild.isNullLeaf {
            nodeX = leftChild
        } else if let rightChild = nodeY.rightChild {
            nodeX = rightChild
        }
            }
    nodeX.parent = nodeY.parent
    if let parentY = nodeY.parent {
        // Should never be the case, as parent of root = nil
        if parentY.isNullLeaf {
            root = nodeX
        } else {
            if nodeY.isLeftChild {
                parentY.leftChild = nodeX
            } else {
                parentY.rightChild = nodeX
            }
        }
    } else {
        root = nodeX
    }
    if nodeY != z {
        z.key = nodeY.key
    }
    // If sliced out node was red -> nothing to do as red-black-property holds
    // If it was black -> fix red-black-property
    if nodeY.color == .black {
        deleteFixup(node: nodeX)
    }
}

 * Fixes possible violations of the red-black property after deletion
 * We have w distinct cases: only case 2 may repeat, but only h many steps, where h is the height
 * of the tree
 * - case 1 -> case 2 -> red-black tree
 *   case 1 -> case 3 -> case 4 -> red-black tree
 *   case 1 -> case 4 -> red-black tree
 * - case 3 -> case 4 -> red-black tree
 * - case 4 -> red-black tree

private func deleteFixup(node x: RBNode) {
    var xTmp = x
    if !x.isRoot && x.color == .black {
        guard var sibling = x.sibling else {
            return
        }
        // Case 1: Sibling of x is red
        if sibling.color == .red {
            // Recolor
            sibling.color = .black
            if let parentX = x.parent {
                parentX.color = .red
                // Rotation
                if x.isLeftChild {
                    leftRotate(node: parentX)
                } else {
                    rightRotate(node: parentX)
                }
                // Update sibling
                if let sibl = x.sibling {
                    sibling = sibl
                }
            }
        }
        // Case 2: Sibling is black with two black children
        if sibling.leftChild?.color == .black && sibling.rightChild?.color == .black {
            // Recolor
            sibling.color = .red
            // Move fake black unit upwards
            if let parentX = x.parent {
                deleteFixup(node: parentX)
            }
            // We have a valid red-black-tree
        } else {
            // Case 3: a. Sibling black with one black child to the right
            if x.isLeftChild && sibling.rightChild?.color == .black {
                // Recolor
                sibling.leftChild?.color = .black
                sibling.color = .red
                // Rotate
                rightRotate(node: sibling)
                // Update sibling of x
                if let sibl = x.sibling {
                    sibling = sibl
                }
            }
                // Still case 3: b. One black child to the left
                else if x.isRightChild && sibling.leftChild?.color == .black {
                    // Recolor
                    sibling.rightChild?.color = .black
                    sibling.color = .red
                    // Rotate
                    leftRotate(node: sibling)
                    // Update sibling of x
                    if let sibl = x.sibling {
                        sibling = sibl
                    }
                }
                // Case 4: Sibling is black with red right child
                // Recolor
                if let parentX = x.parent {
                    sibling.color = parentX.color
                    parentX.color = .black
                    // a. x left and sibling with red right child
                    if x.isLeftChild {
                        sibling.rightChild?.color = .black
                        // Rotate
                        leftRotate(node: parentX)
                    }
                    // b. x right and sibling with red left child
                    else {
                        sibling.leftChild?.color = .black
                        //Rotate
                        rightRotate(node: parentX)
                    }
                    // We have a valid red-black-tree
                    xTmp = root
                }
                }
    }
    xTmp.color = .black
}
 */
