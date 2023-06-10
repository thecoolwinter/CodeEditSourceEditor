//
//  RangeTreeNode.m
//  
//
//  Created by Khan Winter on 6/5/23.
//

#import "RangeTreeNode.h"

@implementation RangeTreeNode

- (nonnull instancetype)init:(nonnull id<NSObject>)value
                            :(NSRange)key
                            :(RangeTreeNode *)parent
                            :(RangeTreeNodeColor)color {
    if (self = [super init]) {
        _key = key;
        _value = value;
        _color = color;
        _parent = parent;
        _left = nil;
        _right = nil;
    }
    return self;
}

// MARK: - Property Setters

- (void)setColor:(RangeTreeNodeColor)color {
    _color = color;
}

- (void)setParent:(RangeTreeNode *)parent {
    _parent = parent;
}

- (void)setLeft:(RangeTreeNode* _Nullable)left {
    _left = left;
}

- (void)setRight:(RangeTreeNode* _Nullable)right {
    _right = right;
}

// MARK: - Sibling Traversal

- (nullable RangeTreeNode*)getSuccessor {
    if (_right != nil) {
        return [_right minimum];
    }

    RangeTreeNode* node = self;
    RangeTreeNode* parent = _parent;
    while (parent != nil && parent.right != nil && NSEqualRanges(parent.right.key, node.key)) {
        node = parent;
        parent = node.parent;
    }
    return parent;
}

- (nullable RangeTreeNode*)getPredecessor {
    if (_left != nil) {
        return [_left minimum];
    }

    RangeTreeNode* node = self;
    RangeTreeNode* parent = _parent;
    while (parent != nil && parent.left != nil && NSEqualRanges(parent.left.key, node.key)) {
        node = parent;
        parent = node.parent;
    }
    return parent;
}

- (nullable RangeTreeNode*)minimum {
    if (_left != nil) {
        return [_left minimum];
    } else {
        return self;
    }
}

- (nullable RangeTreeNode*)maximum {
    if (_right != nil) {
        return [_right maximum];
    } else {
        return self;
    }
}

- (bool)isLeftChild {
    if (_parent == nil) {
        return false;
    } else {
        return NSEqualRanges(_parent.left.key, _key);
    }
}

- (bool)isRightChild {
    if (_parent == nil) {
        return false;
    } else {
        return NSEqualRanges(_parent.right.key, _key);
    }
}

- (nullable RangeTreeNode*)getSibling {
    if (_parent == nil) {
        return nil;
    } else {
        if ([self isLeftChild]) {
            return _parent.right;
        } else {
            return _parent.left;
        }
    }
}

@end
