//
//  CucumberStepTest.m
//  CucumberSwift
//

#import "include/CucumberStepTest.h"

/// Implemented in Swift by CucumberSwift's `CucumberTestSupport`. This target can't import the Swift
/// module, which depends on it, so it finds the class by name.
@protocol CucumberStepTestSupport
+ (nullable NSError *)skipErrorForStepTest:(XCTestCase *)test;
+ (XCTIssue *)locateIssue:(XCTIssue *)issue inStepTest:(XCTestCase *)test;
@end

static Class<CucumberStepTestSupport> _Nullable CucumberStepTestSupport(void) {
    return NSClassFromString(@"CucumberTestSupport");
}

@implementation CucumberStepTest

/// Skips the step when an earlier step in its scenario failed or threw `XCTSkip`, so Xcode shows it as
/// skipped rather than passed.
- (BOOL)setUpWithError:(NSError * _Nullable __autoreleasing *)error {
    if (![super setUpWithError:error]) {
        return NO;
    }
    NSError *skip = [CucumberStepTestSupport() skipErrorForStepTest:self];
    if (skip) {
        if (error) {
            *error = skip;
        }
        return NO;
    }
    return YES;
}

/// A failure while the step runs is recorded at the step's line in its feature file.
- (void)recordIssue:(XCTIssue *)issue {
    Class<CucumberStepTestSupport> support = CucumberStepTestSupport();
    [super recordIssue:support ? [support locateIssue:issue inStepTest:self] : issue];
}

@end
