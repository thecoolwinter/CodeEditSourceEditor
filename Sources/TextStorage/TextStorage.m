//
//  TextStorageBridge.m
//  
//
//  Created by Khan Winter on 6/3/23.
//

#import "TextStorage.h"

@implementation TextStorage

- (instancetype)init {
    self = [super init];

    if (self) {
        // TODO: init
    }

    return self;
}

- (NSString *)string {
    // TODO: String Reference
    return @"";
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesAtIndex:(NSUInteger)location
                                                effectiveRange:(NSRangePointer)range {
//    return [self.balls attributesAtIndex:location effectiveRange:range];
    return [NSDictionary<NSAttributedStringKey, id> new];
}

- (void)replaceCharactersInRange:(NSRange)range
                      withString:(NSString *)str {
    [self beginEditing];

//    [self.balls replaceCharactersInRange:range withString:str];

    NSInteger delta = [str length] - range.length;
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:delta];
    [self endEditing];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs
                range:(NSRange)range {
    [self beginEditing];

//    [self.attributeStorage setAttributes:attrs range:range];

    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

@end
