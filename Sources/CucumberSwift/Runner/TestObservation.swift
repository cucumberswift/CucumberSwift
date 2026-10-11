//
//  TestObservation.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/26/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

extension Cucumber: XCTestObservation {
    public func testBundleDidFinish(_ testBundle: Bundle) {
        reporters.forEach { $0.testSuiteFinished(at: Date()) }
        let name = Cucumber.shared.reportName.appending(String(testBundle.bundleURL.lastPathComponent.prefix { $0 != "." })).appending(".json")
        if  let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
            let reportURL = Reporter.reportURL {
            let fileURL = documentDirectory.appendingPathComponent(name)
            try? FileManager.default.copyItem(at: reportURL, to: fileURL)
        }
    }

    public func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        Cucumber.shared.currentStep?.result = .failed(description)
        Cucumber.shared.currentStep?.errorMessage = description
        Cucumber.shared.currentStep?.endTime = Date()
        guard let step = Cucumber.shared.currentStep,
              let scenario = step.scenario else {
            return
        }
        Cucumber.shared.failedScenarios.append(scenario)
        var foundStep = false
        scenario.steps.forEach { step in
            if step === Cucumber.shared.currentStep {
                foundStep = true
            } else if foundStep && step.result == .pending {
                step.result = .skipped
            }
        }
    }
}

/// Tracks the test XCTest is running. A separate observer, so that `Cucumber` gains no public methods.
final class RunningTestCaseObserver: NSObject, XCTestObservation {
    private(set) weak var testCase: XCTestCase?

    /// A new run in the same process, such as one of Xcode's test iterations, runs each scenario once more.
    func testBundleWillStart(_: Bundle) {
        ScenarioRuns.reset()
    }

    func testCaseWillStart(_ testCase: XCTestCase) {
        self.testCase = testCase
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        if self.testCase === testCase { self.testCase = nil }
    }
}

/// Fails a run that Xcode runs in parallel without `Cucumber.parallelTesting`, where scenarios run in every
/// worker, or not at all, and the run can still pass (#389).
///
/// A process learns that parallel testing is on only from XCTest's private `XCTestConfiguration`, whose
/// `inProcessParallelizationEnabled` and `testsDrivenByIDE` are set once XCTest starts the test bundle: too late to turn the mode
/// on, because each scenario's class has to exist while the bundle loads. So the run fails instead, with a
/// message that names the setting, on the first test of each process, when CucumberTest's suite didn't already fail the run in place of the scenarios. If a new Xcode renames a property,
/// nothing is found and a run behaves as it did before.
final class ParallelWorkerObserver: NSObject, XCTestObservation {
    /// The failure's message.
    static let message = "Xcode is running these tests in parallel, but CucumberSwift's parallel testing is off, so scenarios run "
        + "in every worker, or not at all, and the run can still pass. Set `Cucumber.parallelTesting = true` in `setupSteps()`, "
        + "or the environment variable `CUCUMBER_PARALLEL_TESTING` to `YES`, or turn off parallel testing for this test target. "
        + "See \"Running Scenarios in Parallel\" in CucumberSwift's documentation."

    /// Whether a failure was reported, by the suite CucumberTest builds or by this observer, so that it is once.
    static let reported = Locked(false)

    /// How a process is found to be a parallel worker. Tests replace it: a unit test run is not one.
    static let parallelRunProbe = Locked<() -> Bool> { ParallelWorkerObserver.isParallelRun() }

    private var hasChecked = false
    private let isParallelRun: (() -> Bool)?
    private let report: ((XCTestCase, XCTIssue) -> Void)?

    /// Whether Xcode runs this process as a worker of a parallel test run: both its properties are set. Either
    /// alone is not enough: `inProcessParallelizationEnabled` is also set under `swift test`, which runs
    /// serially, and `testsDrivenByIDE` is `0` in a Mac Catalyst app's worker, which is then not found on
    /// purpose: Xcode runs the tests of a target hosted in an app in one worker there, which runs each scenario
    /// once, as a serial run does, and nothing separates that worker from `swift test`. `false` when XCTest has
    /// no such configuration, or not these properties.
    static func isParallelRun() -> Bool {
        let configurationSelector = NSSelectorFromString("activeTestConfiguration")
        let configuration = (NSClassFromString("XCTestConfiguration") as? NSObject.Type).flatMap {
            $0.responds(to: configurationSelector) ? $0.perform(configurationSelector)?.takeUnretainedValue() as? NSObject : nil
        }
        return ["inProcessParallelizationEnabled", "testsDrivenByIDE"].allSatisfy { name in
            configuration?.responds(to: NSSelectorFromString(name)) == true && (configuration?.value(forKey: name) as? Bool) == true
        }
    }

    /// Whether this parallel run has the setting off, so that its scenarios run wrongly. With one test per
    /// scenario every scenario is a test of one class, which a parallel run is correct for.
    static func isMissingSetting(isParallelRun: (() -> Bool)? = nil) -> Bool {
        guard Cucumber.shared is StepImplementation else { return false }
        // The flag can be set in setupSteps(), which may not have run in a process that was handed no test of
        // CucumberTest's.
        CucumberTest.loadFeaturesIfNeeded()
        guard !FeatureFlags.isParallelTesting, !FeatureFlags.isOneTestPerScenario else { return false }
        return (isParallelRun ?? parallelRunProbe.snapshot)()
    }

    /// The closures are replaceable for tests: a unit test run is not a parallel worker, and an issue
    /// recorded on it would fail it.
    init(isParallelRun: (() -> Bool)? = nil,
         report: ((XCTestCase, XCTIssue) -> Void)? = nil) {
        self.isParallelRun = isParallelRun
        self.report = report
    }

    func testCaseWillStart(_ testCase: XCTestCase) {
        guard !hasChecked, !Self.reported.snapshot else { return }
        hasChecked = true
        guard Self.isMissingSetting(isParallelRun: isParallelRun) else { return }
        Self.reported.withLock { $0 = true }
        FileHandle.standardError.write(Data(("CucumberSwift: " + Self.message + "\n").utf8))
        let issue = XCTIssue(type: .assertionFailure, compactDescription: Self.message)
        if let report = report {
            report(testCase, issue)
        } else {
            // Not recorded here: XCTest has not started the test yet, and xcodebuild rejects an issue for a test
            // that is not running. A teardown block runs inside the test.
            testCase.addTeardownBlock { testCase.record(issue) }
        }
    }
}
