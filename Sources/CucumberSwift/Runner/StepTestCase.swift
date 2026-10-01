//
//  StepTestCase.swift
//  CucumberSwift
//

import Foundation
import XCTest

/// What the tests CucumberSwift generates for each step do beyond running it. A step after one that
/// failed or threw `XCTSkip` does not run, and Xcode reports it as skipped, not as a pass. Their
/// class's superclass is `CucumberStepTest`, in Objective-C, so that Xcode names them without "()";
/// it asks `StepTestSupport` for this. A failure recorded while a step runs moves to the step's line in its
/// feature file, so the failure opens the Gherkin, and Xcode marks the step there. The failure's call
/// stack is kept, so the step definition's line is still one click away.
enum StepTestCase {
    private static var stepKey: UInt8 = 0

    /// The superclass of the class made for each scenario.
    static var superclass: XCTestCase.Type {
        NSClassFromString("CucumberStepTest") as? XCTestCase.Type ?? XCTestCase.self
    }

    /// The step a generated test runs.
    static func step(of test: XCTestCase) -> Step? {
        objc_getAssociatedObject(test, &stepKey) as? Step
    }

    static func setStep(_ step: Step, of test: XCTestCase) {
        objc_setAssociatedObject(test, &stepKey, step, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static let skippedAfterFailureMessage = "Skipped: an earlier step in this scenario failed."

    /// Why the step must not run, or `nil` when it should: an earlier step in its scenario threw
    /// `XCTSkip`, or failed.
    static func skipReason(for step: Step) -> String? {
        guard let scenario = step.scenario else { return nil }
        if let skipped = Cucumber.shared.skippedScenarios.first(where: { $0.scenario === scenario }) {
            return "Skipped: \(skipped.reason)"
        }
        return Cucumber.shared.failedScenarios.contains { $0 === scenario } ? skippedAfterFailureMessage : nil
    }

    /// The issue at the step's line in its feature file. An issue already in that file, such as an
    /// ambiguous step's, and a step with no feature file, such as one from the DSL, stay as they are.
    static func issue(_ issue: XCTIssue, locatedAt step: Step) -> XCTIssue {
        guard let featureFile = step.location.uri,
              issue.sourceCodeContext.location?.fileURL != featureFile else { return issue }
        var located = issue
        located.sourceCodeContext = XCTSourceCodeContext(callStack: issue.sourceCodeContext.callStack,
                                                         location: XCTSourceCodeLocation(fileURL: featureFile,
                                                                                         lineNumber: Int(step.location.line)))
        return located
    }
}

/// What `CucumberStepTest`, in Objective-C, asks of CucumberSwift. It finds this class by name, since
/// the Objective-C target can't import this module, which depends on it.
@objc(CucumberStepTestSupport)
final class StepTestSupport: NSObject {
    // The names must match the protocol in CucumberStepTest.m.
    @objc(skipErrorForStepTest:)
    static func skipError(forStepTest test: XCTestCase) -> NSError? {
        guard let step = StepTestCase.step(of: test), let reason = StepTestCase.skipReason(for: step) else { return nil }
        return XCTSkip(reason) as NSError
    }

    @objc(locateIssue:inStepTest:)
    static func locateIssue(_ issue: XCTIssue, inStepTest test: XCTestCase) -> XCTIssue {
        StepTestCase.step(of: test).map { StepTestCase.issue(issue, locatedAt: $0) } ?? issue
    }
}
