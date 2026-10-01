//
//  CucumberTestSupport.swift
//  CucumberSwift
//

import Foundation
import XCTest

/// What `CucumberStepTest` and `CucumberScenarioTest`, in Objective-C, ask of CucumberSwift. They find
/// this class by name, since the Objective-C target can't import this module, which depends on it.
/// The names must match the protocols in CucumberStepTest.m and CucumberScenarioTest.m.
@objc(CucumberTestSupport)
final class CucumberTestSupport: NSObject {
    // Asked by CucumberStepTest.m, for a test per step.
    @objc(skipErrorForStepTest:)
    static func skipError(forStepTest test: XCTestCase) -> NSError? {
        guard let step = StepTestCase.step(of: test), let reason = StepTestCase.skipReason(for: step) else { return nil }
        return XCTSkip(reason) as NSError
    }

    @objc(locateIssue:inStepTest:)
    static func locateIssue(_ issue: XCTIssue, inStepTest test: XCTestCase) -> XCTIssue {
        StepTestCase.step(of: test).map { StepTestCase.issue(issue, locatedAt: $0) } ?? issue
    }

    // Asked by CucumberScenarioTest.m, for one test per scenario.
    @objc(resolveScenarioTestNamed:)
    static func resolveScenarioTest(named name: String) -> Bool {
        CucumberTest.resolveScenarioTest(named: name)
    }

    @objc(locateIssue:)
    static func locateIssue(_ issue: XCTIssue) -> XCTIssue {
        CucumberTest.locateScenarioIssue(issue)
    }
}
