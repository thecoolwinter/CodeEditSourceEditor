//
//  PieceTable.m
//  
//
//  Created by Khan Winter on 6/6/23.
//

#import "PieceTable.h"

// MARK: - Piece

@implementation Piece

- (instancetype)init:(PieceSource)isOriginal
                    :(NSRange)documentRange
                    :(NSUInteger)startIndex
                    :(NSUInteger)endIndex; {
    if (self = [super init]) {
        _source = isOriginal;
        _documentRange = documentRange;
        _startIndex = startIndex;
        _endIndex = endIndex;
    }
    return self;
}

@end

// MARK: - Piece Table

@implementation PieceTable

@synthesize length;

// MARK: - Init

- (instancetype)init {
    if (self = [super init]) {
        _originalContent = nil;
        _originalContentLength = 0;

        _content = nil;
        _contentLength = 0;

        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    if (self = [super init]) {
        _originalContent = nil;
        _originalContentLength = 0;

        _content = malloc(sizeof(unichar) * capacity);
        _contentLength = 0;
        _contentSize = (uint32)capacity;

        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCharacters:(const unichar *)characters
                            length:(NSUInteger)length {
    if (self = [super init]) {
        _originalContent = malloc(sizeof(unichar) * length);
        for (int i = 0; i < length; i++) {
            _originalContent[i] = characters[i];
        }
        _originalContentLength = (uint32)length;

        _content = nil;
        _contentLength = 0;
        _contentSize = 0;

        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCharactersNoCopy:(unichar *)characters
                                  length:(NSUInteger)length
                            freeWhenDone:(BOOL)freeBuffer {
    if (self = [super init]) {
        _originalContent = characters;
        _originalContentLength = (uint32)length;

        _content = nil;
        _contentLength = 0;
        _contentSize = 0;

        [self commonInit];
        _freeOriginalContentWhenDone = freeBuffer == YES ? true : false;
    }
    return self;
}

- (instancetype)initWithString:(NSString *)aString {
    if (self = [super init]) {
        unichar* chars = malloc(sizeof(unichar) * aString.length);
        [aString getCharacters:chars];
        _originalContent = chars;
        _originalContentLength = aString.length;

        _content = nil;
        _contentLength = 0;
        _contentSize = 0;

        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _pieceTree = [[RangeTree alloc] init];
    NSRange range = NSMakeRange(0, _originalContentLength);
    Piece* piece = [[Piece alloc] init:kOriginal :range :0 :_originalContentLength];
    [_pieceTree insert:piece :range];
    _freeOriginalContentWhenDone = true;
    [self updateLength];
}

- (void)updateLength {
    length = _contentLength + _originalContentLength;
}

// MARK: - dealloc

- (void)dealloc {
    if (_freeOriginalContentWhenDone) {
        free(_originalContent);
    }
    free(_content);
}

// MARK: - NSString

- (unichar)characterAtIndex:(NSUInteger)index {
    if (index >= length) {
        [self _raiseRangeException:index];
    } else {
        Piece* piece = [_pieceTree get:index];
        if (piece == nil) {
            [self _raisePieceNotFoundException:index];
        }
        NSUInteger indexOffset = index - piece.documentRange.location;
        NSUInteger index = piece.startIndex + indexOffset;
        return piece.source == kOriginal ? _originalContent[index] : _content[index];
    }
}

- (void)getCharacters:(unichar *)buffer
                range:(NSRange)range {
    if (NSMaxRange(range) > length) {
        [self _raiseRangeException:NSMaxRange(range)];
    } else {
        NSUInteger remainingLength = range.length;
        NSUInteger location = range.location;
        while (remainingLength > 0) {
            Piece* piece = [_pieceTree get:location];
            if (piece == nil) {
                [self _raisePieceNotFoundException:location];
            }
            NSUInteger charactersToCopy = MIN(NSMaxRange(range), NSMaxRange(piece.documentRange)) - location;
            NSUInteger startContentIndexOffset = location - piece.documentRange.location;
            // The start index in the content array for the piece
            NSUInteger startContentIndex = piece.startIndex + startContentIndexOffset;

            // Loop until either the range or the piece's document range ends.
            for (NSUInteger i = 0; i < charactersToCopy; i++) {
                buffer[location + i] = piece.source == kOriginal
                                            ? _originalContent[startContentIndex + i]
                                            : _content[startContentIndex + i];
            }
            remainingLength -= piece.documentRange.length;
            location = NSMaxRange(piece.documentRange);
        }
    }
}

// MARK: - NSMutableString

- (void)replaceCharactersInRange:(NSRange)range
                      withString:(NSString *)aString {
    NSUInteger oldContentLength = _contentLength;
    if (range.length > 0) {
        unichar* buffer = malloc(sizeof(unichar) * aString.length);
        [aString getCharacters:buffer];
        [self appendToContent:buffer :aString.length];
        free(buffer);
    }

    // Modify piece table to accomodate new characters
//    Piece* newPiece = [[Piece alloc] init:kContent :range :oldContentLength :_contentLength];
    
}

// MARK: - Content Array

- (void)appendToContent:(unichar*)chars
                       :(NSUInteger)length {
    // Grow content array as needed until it can fit the new data.
    while (length + _contentLength > _contentSize) {
        [self growContentArray];
    }
    for (int i = 0; i < length; i++) {
        _content[_contentLength + i] = chars[i];
    }
    _contentLength += length;
    [self updateLength];
}

- (void)growContentArray {
    unichar* newContent = malloc(sizeof(unichar) * 2 * _contentSize);
    _contentSize = 2 * _contentSize;
    for (int i = 0; i < _contentLength; i++) {
        newContent[i] = _content[i];
    }
    _content = newContent;
}

- (void)_raiseRangeException:(NSUInteger)index {
    [[NSException
      exceptionWithName:NSRangeException
      reason:[NSString
              stringWithFormat:@"Invalid index, got %lu. Outside the valid range: 0..<%lu",
              (unsigned long)index,
              (unsigned long)length]
      userInfo:nil]
     raise];
}

- (void)_raisePieceNotFoundException:(NSUInteger)index {
    [[NSException
      exceptionWithName:NSInternalInconsistencyException
      reason:[NSString
              stringWithFormat:@"Piece not found for index: %lu",
              (unsigned long)index]
      userInfo:nil]
     raise];
}

@end
