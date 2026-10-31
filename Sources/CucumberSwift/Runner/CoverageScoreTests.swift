//
//  CoverageScoreTests.swift
//  CucumberSwift
//

import Foundation
import XCTest

/// The tests that record a feature's coverage scores, with ``Cucumber/coverage`` on: a suite named after
/// the feature and "Coverage scores", which runs after the feature's scenarios, with a test for each
/// kind of issue. Each issue is then listed under a test that names it, and a test that fails, fails for
/// its own score, rather than a step of the feature's last scenario failing for the feature.
///
/// A feature's scores are known once its last scenario ends. The coverage reporter hands the issues to
/// ``receive(_:in:)``, which holds them for the feature's suite. A feature without one, as in a parallel
/// run, or whose suite already ran, gets its issues in the test that is running, as before.
enum CoverageScoreTests {
    private struct State {
        /// The features whose score tests haven't run yet, by their feature file's URL.
        var waiting = Set<String>()
        /// The issues the score tests record, by their feature file's URL.
        var held = [String: [CoverageIssue]]()
    }

    private static let state = Locked(State())

    /// The name of the test that records `kind`'s issues.
    static func testName(_ kind: CoverageIssue.Kind) -> String {
        switch kind {
            case .coverage: "Coverage"
            case .redundancy: "Redundancy"
            case .redundantScenario: "Redundant scenarios"
        }
    }

    /// The coverage settings for the XCTest runner. With parallel testing, a feature can end after its
    /// worker's last test, where an error couldn't fail a test: when Xcode hands out its scenarios to
    /// different workers, or runs only some of its tests. The runner then scores nothing.
    static func settings(environment: [String: String] = Cucumber.shared.environment) -> CoverageSettings {
        var settings = CoverageSettings.read(environment: environment)
        settings.isWritingFiles = FeatureFlags.coverageSetting == true || FeatureFlags.coveragePath != nil
        if FeatureFlags.isParallelTesting {
            settings.scoresOffReason = "with parallel testing, a feature can end after its worker's last test, where a score's error "
                + "couldn't fail a test. Turn parallel testing off to score each feature."
        }
        return settings
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    /// The kinds of the issues held for the score tests of the feature at `file`.
    static func heldKinds(for file: URL?) -> [CoverageIssue.Kind] {
        state.snapshot.held[file?.absoluteString ?? ""]?.map(\.kind) ?? []
    }

    /// Whether the score tests of the feature at `file` haven't run yet.
    static func isWaiting(for file: URL?) -> Bool {
        state.snapshot.waiting.contains(file?.absoluteString ?? "")
    }

    /// The feature's score tests, named `className`, or nil with coverage off. Each finishes the feature
    /// with `finish` first, for a feature whose last scenario a tag left out, and so never finished, and
    /// for a test plan that runs only some of the score tests. A feature finishes only once.
    static func suite(for feature: Feature,
                      className: String,
                      finish: @escaping (Feature) -> Void = { Cucumber.shared.finishIfStarted($0) }) -> XCTestSuite? {
        guard FeatureFlags.isCoverage, let key = feature.coverageIssueFile?.absoluteString,
              let testClass = TestCaseGenerator.makeClass(className: className) else { return nil }
        let kinds = CoverageIssue.Kind.allCases
        let selectors = kinds.map { kind in
            TestCaseGenerator.addTestMethod(testCase: testClass,
                                            method: TestCaseMethod(withName: CucumberTest.generatedTestName(testName(kind))) {
                                                finish(feature)
                                                record(kind, of: key, isLast: kind == kinds.last)
                                            })
        }
        objc_registerClassPair(testClass)
        state.withLock { _ = $0.waiting.insert(key) }
        let suite = XCTestSuite(name: className)
        selectors.compactMap { $0 }.forEach { suite.addTest(testClass.init(selector: $0)) }
        return suite
    }

    /// Holds `issue` for its feature's score tests, or records it in `test` when its feature has none, or
    /// they already ran.
    static func receive(_ issue: CoverageIssue, in test: XCTestCase?) {
        let key = issue.file?.absoluteString ?? ""
        let isHeld = state.withLock { state -> Bool in
            guard state.waiting.contains(key) else { return false }
            state.held[key, default: []].append(issue)
            return true
        }
        if !isHeld {
            issue.record(in: test)
        }
    }

    /// Records the feature's issues of `kind` in the running test, and keeps the other kinds for their
    /// tests. The last of the feature's score tests lets later issues of the feature go to the test that is
    /// running.
    private static func record(_ kind: CoverageIssue.Kind, of key: String, isLast: Bool) {
        let issues = state.withLock { state -> [CoverageIssue] in
            let all = state.held[key] ?? []
            state.held[key] = all.filter { $0.kind != kind }
            if isLast {
                state.waiting.remove(key)
            }
            return all.filter { $0.kind == kind }
        }
        issues.forEach { $0.record(in: Cucumber.shared.runningTestCase) }
    }
}
