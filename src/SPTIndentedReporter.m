#import "SPTIndentedReporter.h"

@implementation SPTIndentedReporter

- (void)startObserving {
    self.nestingLevel = 0;

    [super startObserving];
}

- (NSString *)indentation {
  // XCode does not strip whitespace from the beginning of lines that report an error. Indentation should only enabled for non-error text.

  if (self.indentationEnabled) {
    return [@"" stringByPaddingToLength:(self.nestingLevel * 2)
                             withString:@" "
                        startingAtIndex:0];
  } else {
    return @"";
  }
}

- (void)withIndentationEnabled:(void(^)(void))block {
  [self withIndentationEnabled:YES block:block];
}

- (void)withIndentationEnabled:(BOOL)indentationEnabled block:(void(^)(void))block {
  BOOL originalValue = self.indentationEnabled;

  self.indentationEnabled = indentationEnabled;
  @try {
    block();
  } @finally {
    self.indentationEnabled = originalValue;
  }
}

- (void)printIndentation {
  [self printString:self.indentation];
}

@end

