//
//  RangeTree.m
//  
//
//  Created by Khan Winter on 6/5/23.
//

#import "RangeTree.h"


// MARK: - Tree

@implementation RangeTree

- (nonnull instancetype)init {
    if (self = [super init]) {
        _root = nil;
    }
    return self;
}

- (nullable id<NSObject>)get:(NSUInteger)key {
    RangeTreeNode* foundNode = nil;
    // Do a cache lookup first.
    for (RangeTreeNode* node in _cachedNodes) {
        if (NSLocationInRange(key, node.key)) {
            return node;
        }
    }

    if (foundNode == nil) {
        foundNode = [self _searchTree:key];
        // Update the cache with the new object.
        if (foundNode != nil) {
            [_cachedNodes replaceObjectAtIndex:_cachedNodesFront withObject:foundNode];
            // Circular buffer w/ 3 elements.
            _cachedNodesFront = (_cachedNodesFront + 1) % 3;
        }
    }

    return foundNode == nil ? nil : foundNode.value;
}

- (void)insert:(nonnull id<NSObject>)object
              :(NSRange)key; {
    _count += 1;
    if (_root == nil) {
        _root = [[RangeTreeNode alloc] init:object :key :nil :kBlack];
        return;
    } else {
        RangeTreeNode* node = _root;
        while (true) {
            if (NSEqualRanges(key, node.key)) {
                node.value = object;
                return;
            } else if (NSIntersectionRange(key, node.key).length > 0) {
                // Key overlaps with existing key
                [self _raiseRangeException:key :node.key];
            } if (key.location < node.key.location) {
                // No intersection, so we can assume entire node range is < inserted key
                if (node.left == nil) {
                    node.left = [[RangeTreeNode alloc] init:object :key :node :kRed];
                    node = node.left;
                    break;
                } else {
                    node = node.left;
                }
            } else {
                if (node.right == nil) {
                    node.right = [[RangeTreeNode alloc] init:object :key :node :kRed];
                    node = node.right;
                    break;
                } else {
                    node = node.right;
                }
            }
        }
        [self _insertFix:node];
    }
}

- (void)del:(NSRange)key {
    if (NSEqualRanges(_root.key, key) && _root.left == nil && _root.right == nil) {
        _root = nil;
        return;
    }

    RangeTreeNode* node = [self _searchTree:key.location];
    if (node == nil || !NSEqualRanges(node.key, key)) {
        return;
    }

    // TODO :(

    if (node.color == kBlack) {
        [self _delFix:node];
    }
}

// MARK: - Tree Work

/// Search the tree for a given key.
/// - Parameter key: The key to search for.
/// - Returns: A tree node, if found.
- (nullable RangeTreeNode*)_searchTree:(NSUInteger)key {
    RangeTreeNode* node = _root;
    while (node != nil) {
        if (NSLocationInRange(key, node.key)) {
            // found
            return node;
        } else if (key < node.key.location) {
            // left
            node = node.left;
        } else {
            // right
            node = node.right;
        }
    }
    return nil;
}

- (void)_insertFix:(RangeTreeNode *)node {
    if (node == nil) {
        return;
    }

    while (node.parent != nil && node.parent.color == kRed) {
        RangeTreeNode* uncle = [node.parent getSibling];
        if (uncle != nil && uncle.color == kRed) {
            // Case 1: Parent & Sibling are red
            [node.parent setColor:kBlack];
            [uncle setColor:kBlack];
            if (node.parent.parent != nil) {
                [node.parent.parent setColor:kRed];
                node = node.parent.parent;
            }
        } else {
            // Case 2: 
            if (![node isLeftChild] && [node.parent isLeftChild]) {
                node = node.parent;
                [self _rotateLeft:node];
            } else if ([node isLeftChild] && ![node.parent isLeftChild]) {
                node = node.parent;
                [self _rotateRight:node];
            }

            // Case 3
            [node.parent setColor:kBlack];
            if (node.parent.parent != nil) {
                [node.parent.parent setColor:kRed];
                if ([node.parent isLeftChild]) {
                    [self _rotateRight:node.parent.parent];
                } else {
                    [self _rotateLeft:node.parent.parent];
                }
            }
        }
    }

    [_root setColor:kBlack];
}

- (void)_delFix:(RangeTreeNode *)node {
    return;
    while (NSEqualRanges(node.key, _root.key) && node.color == kBlack) {
        RangeTreeNode* sibling = [node getSibling];
        if (sibling == nil) {
            break;
        }

        // Case 1: Sibling is red
        if (sibling.color == kRed) {
            [sibling setColor:kBlack];
            if (node.parent != nil) {
                // Rotate & Recolor
                [node.parent setColor:kRed];
                if ([node isLeftChild]) {
                    [self _rotateLeft:node.parent];
                } else {
                    [self _rotateRight:node.parent];
                }
                // Update sibling after rotate
                RangeTreeNode* tmpNewSibling = [node getSibling];
                if (tmpNewSibling != nil) {
                    sibling = tmpNewSibling;
                }
            }
        }

        // Case 2: Sibling is black with two black children
        if (sibling.left != nil && sibling.left.color == kBlack
            && sibling.right != nil && sibling.right.color == kBlack) {
            [sibling setColor:kRed];
            if (node.parent != nil) {
                node = node.parent;
                continue;
            }
        } else {
            // Case 3: Sibling black w/ one black child on right
            if ([node isLeftChild] && sibling.right != nil && sibling.right.color == kBlack) {
                sibling.left;
            }

            // TODO: Case 3a, Case 3b, Case 4
        }
    }
    [_root setColor:kBlack];
}

- (void)_rotateLeft:(RangeTreeNode *)node {
    [self _rotate:node left:true];
}

- (void)_rotateRight:(RangeTreeNode *)node {
    [self _rotate:node left:false];
}

- (void)_rotate:(RangeTreeNode *)node
           left:(bool)isLeft {
    RangeTreeNode* nodeY;
    if (isLeft) {
        nodeY = node.right;
        node.right = nodeY.left;
        [node.right setParent:node];
    } else {
        nodeY = node.left;
        node.left = nodeY.right;
        [node.left setParent:node];
    }

    [nodeY setParent:node.parent];

    if (node.parent == nil) {
        if (nodeY != nil) {
            _root = nodeY;
        }
    } else {
        if ([node isLeftChild]) {
            [node.parent setLeft:nodeY];
        } else if ([node isRightChild]) {
            [node.parent setRight:nodeY];
        }
    }

    if (isLeft) {
        [nodeY setLeft:node];
    } else {
        [nodeY setRight:node];
    }
    [node setParent:nodeY];
}

- (void)_raiseRangeException:(NSRange)key
                            :(NSRange)existingRange {
    [[NSException
      exceptionWithName:NSRangeException
      reason:[NSString
              stringWithFormat:@"Invalid insert range, %lu..<%lu overlaps with existing key: %lu..<%lu.",
              key.location,
              NSMaxRange(key),
              existingRange.location,
              NSMaxRange(existingRange)]
      userInfo:nil]
     raise];
}

@end
