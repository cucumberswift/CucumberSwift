//
//  CucumberScenarioTest.h
//  CucumberSwift
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

/// The class of the tests CucumberSwift makes when each scenario is one test. It is written in
/// Objective-C so that Xcode names its tests as written, without the "()" it adds to a Swift test's
/// name, and it is compiled into the bundle, so XCTest can find one of its tests by name. Its tests
/// are added, and run, by CucumberSwift's Swift code, which it asks by class name at runtime.
@interface CucumberScenarioTest : XCTestCase
@end

NS_ASSUME_NONNULL_END
