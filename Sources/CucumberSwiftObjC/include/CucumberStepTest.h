//
//  CucumberStepTest.h
//  CucumberSwift
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

/// The superclass of the test class CucumberSwift makes for each scenario, with a test for each step.
/// It is written in Objective-C so that Xcode names those tests as written, without the "()" it adds
/// to a Swift test's name. CucumberSwift's Swift code, which it asks by class name at runtime, skips a
/// step once an earlier one failed or threw `XCTSkip`, and moves a step's failure to its line in the feature file.
@interface CucumberStepTest : XCTestCase
@end

NS_ASSUME_NONNULL_END
