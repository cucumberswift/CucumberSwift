//
//  CoverageReporter.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink: both runners
//  have `CucumberTestObserver`, `Scenario` and `Feature` with the same members.
//

import Foundation

/// Writes each scenario's code coverage when ``Cucumber/coverage`` is on, through ``CoverageRecorder``.
///
/// The runner always installs it, because it builds its observers before `setupSteps()` can turn coverage
/// on. It reads whether coverage is on when the first scenario starts.
final class CoverageReporter: CucumberTestObserver {
    private let isEnabled: () -> Bool
    private let coveragePath: () -> String?
    private let counters: () -> ProfileCounters
    private(set) var recorder: CoverageRecorder?
    private var hasAsked = false

    init(isEnabled: @escaping () -> Bool, coveragePath: @escaping () -> String?, counters: @escaping () -> ProfileCounters = { .loaded() }) {
        self.isEnabled = isEnabled
        self.coveragePath = coveragePath
        self.counters = counters
    }

    func testSuiteStarted(at: Date) {}

    func testSuiteFinished(at: Date) {
        guard let recorder, let manifest = recorder.writeManifest() else { return }
        if let problem = recorder.manifest.problem {
            print("CucumberSwift coverage: \(problem)")
        }
        print("CucumberSwift coverage: \(recorder.manifest.scenarios.count) scenarios in \(manifest.deletingLastPathComponent().path)")
    }

    func didStart(feature: Feature, at date: Date) {}

    func didStart(scenario: Scenario, at date: Date) {
        if !hasAsked {
            hasAsked = true
            if isEnabled(), let folder = CoverageRecorder.coverageFolder(path: coveragePath()) {
                recorder = CoverageRecorder(coverageFolder: folder, counters: counters())
            }
        }
        recorder?.scenarioStarted()
    }

    func didStart(step: Step, at date: Date) {}

    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {}

    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        recorder?.scenarioFinished(feature: scenario.feature?.uri ?? "",
                                   featureName: scenario.feature?.title ?? "",
                                   line: Int(scenario.location.line),
                                   name: scenario.title,
                                   tags: scenario.tags)
    }

    func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
}
