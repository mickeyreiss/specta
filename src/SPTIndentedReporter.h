#import "SPTReporter.h"

@interface SPTIndentedReporter : SPTReporter

@property (readonly, copy, nonatomic) NSString *indentation;
@property (readwrite, assign, nonatomic) NSInteger nestingLevel;
@property (readwrite, assign, nonatomic) BOOL indentationEnabled;

- (void)printIndentation;
- (void)withIndentationEnabled:(void(^)(void))block;

@end
