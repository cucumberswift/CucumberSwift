//
//  CucumberScenarioTest.m
//  CucumberSwift
//

#import "include/CucumberScenarioTest.h"

/// Implemented in Swift by CucumberSwift's `CucumberTestSupport`. This target can't import the Swift
/// module, which depends on it, so it finds the class by name.
@protocol CucumberTestSupport
+ (BOOL)resolveScenarioTestNamed:(NSString *)name;
+ (XCTIssue *)locateIssue:(XCTIssue *)issue;
@end

static Class<CucumberTestSupport> _Nullable CucumberTestSupport(void) {
    return NSClassFromString(@"CucumberTestSupport");
}

@implementation CucumberScenarioTest

/// Xcode's test navigator runs one scenario by asking XCTest for `CucumberScenarioTest/<its name>`.
/// Nothing has added that test yet, so the Objective-C runtime asks here, and CucumberSwift adds it.
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if ([CucumberTestSupport() resolveScenarioTestNamed:NSStringFromSelector(sel)]) {
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

/// A failure while a step runs is recorded at the step's line in its feature file.
- (void)recordIssue:(XCTIssue *)issue {
    Class<CucumberTestSupport> support = CucumberTestSupport();
    [super recordIssue:support ? [support locateIssue:issue] : issue];
}

@end
