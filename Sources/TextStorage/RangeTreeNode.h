//
//  RangeTreeNode.h
//  
//
//  Created by Khan Winter on 6/5/23.
//

#import <Foundation/Foundation.h>
#import "RangeTreeNodeColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface RangeTreeNode : NSObject

@property NSRange key;
@property NSObject* value;
@property(readonly) RangeTreeNodeColor color;
@property(readonly, nullable) RangeTreeNode* parent;
@property(readonly, nullable) RangeTreeNode* left;
@property(readonly, nullable) RangeTreeNode* right;

- (instancetype)init:(NSObject*)value
                    :(NSRange) key
                    :(nullable RangeTreeNode *)parent
                    :(RangeTreeNodeColor)color;

- (void)setColor:(RangeTreeNodeColor)color;
- (void)setParent:(RangeTreeNode* _Nullable)parent;
- (void)setLeft:(RangeTreeNode* _Nullable)left;
- (void)setRight:(RangeTreeNode* _Nullable)right;

- (nullable RangeTreeNode*)getSuccessor;
- (nullable RangeTreeNode*)getPredecessor;
- (nullable RangeTreeNode*)minimum;
- (nullable RangeTreeNode*)maximum;

- (bool)isLeftChild;
- (bool)isRightChild;
- (nullable RangeTreeNode*)getSibling;

@end

NS_ASSUME_NONNULL_END
