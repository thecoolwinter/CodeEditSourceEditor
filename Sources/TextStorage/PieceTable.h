//
//  PieceTable.h
//  
//
//  Created by Khan Winter on 6/6/23.
//

#import <Foundation/Foundation.h>
#import "RangeTree.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(BOOL, PieceSource) {
    kOriginal,
    kContent
};

@interface Piece : NSObject

- (instancetype)init:(PieceSource)isOriginal
                    :(NSRange)documentRange
                    :(NSUInteger)startIndex
                    :(NSUInteger)endIndex;
@property(readonly) PieceSource source;
@property(readwrite) NSRange documentRange;
@property(readwrite) NSUInteger startIndex;
@property(readwrite) NSUInteger endIndex;

@end

@interface PieceTable : NSMutableString

@property(readonly, nullable) unichar* originalContent;
@property(readonly) NSUInteger originalContentLength;
@property(readonly) BOOL freeOriginalContentWhenDone;

@property(readonly, nullable) unichar* content;
/// How many items are stored in the `content` array.
@property(readonly) NSUInteger contentLength;
/// The size of the `content` array.
@property(readonly) NSUInteger contentSize;

@property(readonly, nonnull) RangeTree* pieceTree;

- (void)commonInit;
- (void)updateLength;

/// Appends the characters in the given buffer to the content array.
/// - Parameters:
///   - chars: The buffer of characters to append.
///   - length: The length of the `chars` buffer.
- (void)appendToContent:(unichar*)chars
                       :(NSUInteger)length;
/// Grow the content array and copy the data into the new array.
/// Uses an exponential growth method for array size.
- (void)growContentArray;

- (void)_raiseRangeException:(NSUInteger)index;
- (void)_raisePieceNotFoundException:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
