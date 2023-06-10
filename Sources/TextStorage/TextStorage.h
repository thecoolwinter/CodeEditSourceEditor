//
//  TextStorageBridge.h
//  
//
//  Created by Khan Winter on 6/3/23.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSTextStorage.h>
#import "RangeTree.h"
#import "PieceTable.h"

NS_ASSUME_NONNULL_BEGIN

@interface TextStorage : NSTextStorage

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
