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
+ (nullable XCTestSuite *)scenarioTestSuite;
@end

static Class<CucumberTestSupport> _Nullable CucumberTestSupport(void) {
    return NSClassFromString(@"CucumberTestSupport");
}

@implementation CucumberScenarioTest

/// Xcode's test navigator runs one scenario by asking XCTest for `CucumberScenarioTest/<its name>`.
/// Nothing has added that test yet, so the Objective-C runtime asks here, and CucumberSwift adds it.
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    // Not for the class made for each scenario with parallel testing: its test exists from the start.
    if (self == [CucumberScenarioTest class] && [CucumberTestSupport() resolveScenarioTestNamed:NSStringFromSelector(sel)]) {
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

/// With `swift test`, SwiftPM lists a test under the suite that holds it, and runs it by asking XCTest for
/// `<suite>/<test>`, which finds a test of the class of that name only. So under `swift test --parallel`,
/// this class's own suite holds the scenarios, and the list names them right (#567).
+ (XCTestSuite *)defaultTestSuite {
    if (self == [CucumberScenarioTest class]) {
        XCTestSuite *suite = [CucumberTestSupport() scenarioTestSuite];
        if (suite) {
            return suite;
        }
    }
    return [super defaultTestSuite];
}

/// A failure while a step runs is recorded at the step's line in its feature file.
- (void)recordIssue:(XCTIssue *)issue {
    Class<CucumberTestSupport> support = CucumberTestSupport();
    [super recordIssue:support ? [support locateIssue:issue] : issue];
}

@end
