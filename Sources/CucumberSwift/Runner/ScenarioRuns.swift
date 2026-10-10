//
//  ScenarioRuns.swift
//  CucumberSwift
//
//  CucumberSwift checks for itself that no scenario runs twice, so a user doesn't have to compare the
//  number of tests that ran with a serial run (#386). Each time a scenario starts, in a test per step
//  or a test per scenario, it is counted. The second start of a scenario in the same process fails the
//  test that runs it, at the scenario's line in its feature file.
//
//  This sees one process. In a parallel run every worker is one, and a scenario only runs twice when a
//  worker runs it through `CucumberTest`'s suite as well as its own class, which is what
//  `ParallelTesting.scenarioClassesMade` is for: `CucumberTest.defaultTestSuite` fails the run when the
//  classes are made too late, so that one is reported too.
//
//  It does not report a scenario that did not run. A scenario left out on purpose, by a test plan's
//  skipped tests, `-skip-testing` or Xcode's rerun of failed tests, looks the same from inside a process
//  as one that was dropped by mistake, so such a check would fail runs that are correct.
//

import Foundation
import XCTest

enum ScenarioRuns {
    /// How many times each scenario has started in this process. Locked, because a step's test and the
    /// observer that resets the counts can be on different threads.
    private static let starts = Locked([ObjectIdentifier: Int]())

    /// Counts a start of the scenario and returns how many times it has started, this one included.
    @discardableResult
    static func recordStart(of scenario: Scenario) -> Int {
        starts.withLock { starts in
            let count = (starts[ObjectIdentifier(scenario)] ?? 0) + 1
            starts[ObjectIdentifier(scenario)] = count
            return count
        }
    }

    /// Forgets the starts. A new test run in the same process, such as one of Xcode's test iterations,
    /// starts again from none.
    static func reset() {
        starts.withLock { $0.removeAll() }
    }

    /// Counts a start of the scenario, and fails the running test when it is not the first.
    static func recordStartAndCheck(of scenario: Scenario) {
        let count = recordStart(of: scenario)
        guard count > 1 else { return }
        let issue = repeatedScenarioIssue(for: scenario, count: count)
        guard let runningTestCase = Cucumber.shared.runningTestCase else {
            XCTFail(repeatedScenarioMessage(for: scenario, count: count))
            return
        }
        runningTestCase.record(issue)
    }

    static func repeatedScenarioMessage(for scenario: Scenario, count: Int) -> String {
        "The scenario '\(scenario.title)' has started \(count) times in this test process, and should run once. "
            + "Something ran it again: with parallel testing on, a scenario runs again when its class was made after XCTest "
            + "built CucumberTest's suite, which holds every scenario. Compare the run with a serial one, and "
            + "report the Xcode version and the kind of test target to CucumberSwift."
    }

    static func repeatedScenarioIssue(for scenario: Scenario, count: Int) -> XCTIssue {
        let location = scenario.location.uri.map { XCTSourceCodeLocation(fileURL: $0, lineNumber: Int(scenario.location.line)) }
        return XCTIssue(type: .assertionFailure,
                        compactDescription: repeatedScenarioMessage(for: scenario, count: count),
                        detailedDescription: nil,
                        sourceCodeContext: location.map { XCTSourceCodeContext(location: $0) } ?? XCTSourceCodeContext(),
                        associatedError: nil,
                        attachments: [])
    }
}
