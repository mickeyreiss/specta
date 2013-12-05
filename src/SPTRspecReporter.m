#import "SPTRspecReporter.h"

#import "SPTXCTestCase.h"
#import "XCTestRun+Specta.h"

static NSUInteger SPTRspecReporterPrintResultLineWidth = 60;

@interface SPTResult : NSObject
@property (nonatomic, strong) XCTestRun *testRun;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) NSUInteger lineNumber;
@end

@implementation SPTResult
@end

@interface SPTRspecReporter ()

@property (nonatomic, strong) NSMutableOrderedSet *pendingTests;
@property (nonatomic, strong) NSMutableOrderedSet *failedTests;

@property (nonatomic, assign) NSUInteger printResultCounter;
@property (nonatomic, assign, getter = wasATestSkipped) BOOL testWasSkipped;

@end

@implementation SPTRspecReporter

- (void)startObserving {
  [super startObserving];

  self.pendingTests = [NSMutableOrderedSet orderedSet];
  self.failedTests = [NSMutableOrderedSet orderedSet];

  self.printResultCounter = 0;
}

- (void)stopObserving {
  [self printLine];
  [self printLine];

  [self printSummary];

  [self printLine];
  [self printLine];

  [self.pendingTests removeAllObjects];
  self.pendingTests = nil;

  [self.failedTests removeAllObjects];
  self.failedTests = nil;

  [super stopObserving];
}

- (void)testSuiteDidStart:(XCTestRun *)testRun {
}

- (void)testSuiteDidStop:(XCTestRun *)testRun {
}

- (void)testCaseDidStart:(XCTestRun *)testRun {
}

- (void)testCaseDidStop:(XCTestRun *)testRun {
  if (testRun.spt_skippedTestCaseCount > 0) {
    return;
  }

  if (testRun.spt_pendingTestCaseCount > 0) {
    [self printResult:@"*"];

    SPTResult *result = [[SPTResult alloc] init];
    result.testRun = testRun;
    result.description = @"Test is marked as pending";

    [self.pendingTests addObject:result];
  } else {
    [self printResult:@"."];
  }

}

- (void)testCaseDidFail:(XCTestRun *)testRun withDescription:(NSString *)description inFile:(NSString *)filePath atLine:(NSUInteger)lineNumber {
  [self printResult:@"F"];

  SPTResult *result = [[SPTResult alloc] init];
  result.testRun = testRun;
  result.description = description;
  result.filePath = filePath;
  result.lineNumber = lineNumber;

  [self.failedTests addObject:result];
}

- (void)printSummary {
  [self withIndentationEnabled:^{
    if ([SPTXCTestCase spt_focusedExamplesExist]) {
      [self printLine:@"Warning: there are focused tests!"];
    }

    [self printPendingSummary:self.pendingTests];
    [self printFailedSummary:self.failedTests];

    [self printLineWithFormat:@"Finished in %0.4f seconds", 1.2345];
    [self printLineWithFormat:@"%d %@, %d %@, %d pending", 5, @"example", 2, @"failures", 3];

    [self printLine];

    [self printLineWithFormat:@"Failed examples:"];

    [self printLine];

    [self.failedTests enumerateObjectsUsingBlock:^(SPTResult *testResult, NSUInteger idx, BOOL *stop) {
      NSAssert([testResult isKindOfClass:[SPTResult class]], @"expect all members of failedTests to be SPTResult objects");
      [self printLineWithFormat:@"specta %@:%d # %@", testResult.filePath, testResult.lineNumber, testResult.description];
    }];
  }];
}

- (void)printPendingSummary:(NSOrderedSet *)tests {
  [self printLine:@"Pending:"];


  [tests enumerateObjectsUsingBlock:^(SPTResult *testResult, NSUInteger idx, BOOL *stop) {
    NSAssert([testResult isKindOfClass:[SPTResult class]], @"set should only contain SPTResults objects");
    self.nestingLevel ++;
    [self printIndentation];
    [self printLineWithFormat:@"%@", testResult.testRun.test.name];

    self.nestingLevel ++;
    [self printIndentation];
    [self printLineWithFormat:@"# %@", testResult.description];

    [self printIndentation];
    [self printLineWithFormat:@"# %@:%u", testResult.filePath, testResult.lineNumber];

    self.nestingLevel -= 2;
  }];

  [self printLine];
  [self printLine];
}

- (void)printFailedSummary:(NSOrderedSet *)tests {
  [self printLine:@"Failures:"];
  [self printLine];

  [tests enumerateObjectsUsingBlock:^(SPTResult *testResult, NSUInteger idx, BOOL *stop) {
    NSAssert([testResult isKindOfClass:[SPTResult class]], @"set should only contain SPTResult objects");
    self.nestingLevel ++;
    [self printIndentation];
    [self printLineWithFormat:@"%u) %@", idx+1, testResult.description];

       self.nestingLevel ++;
    [self printIndentation];
    [self printLineWithFormat:@"# %@:%u", testResult.filePath, testResult.lineNumber];

    self.nestingLevel -= 2;
  }];

  [self printLine];
}

- (void)printResult:(NSString *)result {
  [self printString:result];

  if (++self.printResultCounter % SPTRspecReporterPrintResultLineWidth == 0) {
    [self printLine];
  }
}

@end
