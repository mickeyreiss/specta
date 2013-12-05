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

// Accumulators
@property (nonatomic, strong) NSMutableOrderedSet *pendingTests;
@property (nonatomic, strong) NSMutableOrderedSet *failedTests;

// Aggregate stats
@property (nonatomic, assign) NSUInteger numberOfTests;
@property (nonatomic, assign) NSUInteger numberOfFailures;
@property (nonatomic, assign) NSUInteger numberOfExceptions;
@property (nonatomic, assign) NSUInteger numberOfSkippedTests;
@property (nonatomic, assign) NSUInteger numberOfPendingTests;
@property (nonatomic, assign) NSTimeInterval totalDuration;

@property (nonatomic, assign) NSUInteger printResultCounter;
@property (nonatomic, assign, getter = wasATestSkipped) BOOL testWasSkipped;

@end

@implementation SPTRspecReporter

- (void)startObserving {
  [super startObserving];

  self.pendingTests = [NSMutableOrderedSet orderedSet];
  self.failedTests = [NSMutableOrderedSet orderedSet];

  self.printResultCounter = 0;

  XCTestRun * rootRun = self.runStack.firstObject;
  NSUInteger numberOfSkippedTests = rootRun.spt_skippedTestCaseCount;
  if (numberOfSkippedTests > 0) {
    if ([SPTXCTestCase spt_focusedExamplesExist]) {
      [self printLineWithFormat:@"There are focused tests! %u examples are being skipped.", numberOfSkippedTests];
    } else {
      [self printLineWithFormat:@"%u examples were skipped.", numberOfSkippedTests];
    }
  }
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

  SPTResult *result = [[SPTResult alloc] init];
  result.testRun = testRun;
  result.description = @"Test is marked as pending";

  if (testRun.spt_pendingTestCaseCount > 0) {
    [self printResult:@"*"];
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
  XCTestRun * rootRun = self.runStack.firstObject;
  NSUInteger numberOfTests = rootRun.testCaseCount;
  NSUInteger numberOfFailures = rootRun.totalFailureCount;
  NSUInteger numberOfExceptions = rootRun.unexpectedExceptionCount;
  NSUInteger numberOfPendingTests = rootRun.spt_pendingTestCaseCount;
  NSTimeInterval totalDuration = rootRun.totalDuration;

  [self withIndentationEnabled:^{

    [self printPendingSummary];
    [self printFailedSummary];

    [self printLineWithFormat:@"Finished in %0.4f seconds", totalDuration];

    [self printLineWithFormat:@"%d %@, %d %@, %d pending", numberOfTests, (numberOfTests == 1 ? @"example" : @"examples"), numberOfFailures, (numberOfFailures == 1 ? @"failure" : @"failures"), numberOfPendingTests];

    [self printLine];

    [self printLineWithFormat:@"Failed examples:"];

    [self printLine];

    [self.failedTests enumerateObjectsUsingBlock:^(SPTResult *testResult, NSUInteger idx, BOOL *stop) {
      NSAssert([testResult isKindOfClass:[SPTResult class]], @"expect all members of failedTests to be SPTResult objects");
      [self printLineWithFormat:@"specta %@:%d # %@", testResult.filePath, testResult.lineNumber, testResult.description];
    }];
  }];
}

- (void)printPendingSummary {
  [self printLine:@"Pending:"];

  NSOrderedSet *pendingTests = self.pendingTests;

  [pendingTests enumerateObjectsUsingBlock:^(SPTResult *testResult, NSUInteger idx, BOOL *stop) {
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

- (void)printFailedSummary {
  NSOrderedSet *failedTests = self.failedTests;
  [self printLine:@"Failures:"];
  [self printLine];

  [failedTests enumerateObjectsUsingBlock:^(SPTResult *testResult, NSUInteger idx, BOOL *stop) {
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
