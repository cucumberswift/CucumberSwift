//
//  CoverageReporter.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink: both runners
//  have `CucumberTestObserver`, `Scenario` and `Feature` with the same members.
//

import Foundation

/// Writes each scenario's code coverage when ``Cucumber/coverage`` is on, through ``CoverageRecorder``, and
/// reports each feature's scores when it finishes: it prints them, and records a warning or an error on the
/// feature file for a score past its level.
///
/// The runner always installs it, because it builds its observers before `setupSteps()` can turn coverage
/// on. It reads whether coverage is on, and the settings, when the first scenario starts.
final class CoverageReporter: CucumberTestObserver {
    private let isEnabled: () -> Bool
    private let coveragePath: () -> String?
    private let settings: () -> CoverageSettings
    private let record: (CoverageIssue) -> Void
    private let counters: () -> ProfileCounters
    private let output: (String) -> Void
    private(set) var recorder: CoverageRecorder?
    private var readSettings = CoverageSettings()
    private var hasAsked = false

    /// The lines of the scenario's steps, which the examples of a Scenario Outline share, and no two other
    /// scenarios do.
    static func group(of scenario: Scenario) -> String {
        guard !scenario.steps.isEmpty else { return "line \(scenario.location.line)" }
        return scenario.steps.map { "\($0.location.line)" }.joined(separator: ",")
    }

    init(isEnabled: @escaping () -> Bool,
         coveragePath: @escaping () -> String?,
         settings: @escaping () -> CoverageSettings = { CoverageSettings() },
         record: @escaping (CoverageIssue) -> Void = { _ in
             // Without a way to record issues, the scores are only printed.
         },
         counters: @escaping () -> ProfileCounters = { .loaded() },
         output: @escaping (String) -> Void = { print($0) }) {
        self.isEnabled = isEnabled
        self.coveragePath = coveragePath
        self.settings = settings
        self.record = record
        self.counters = counters
        self.output = output
    }

    func testSuiteStarted(at _: Date) {
        // Coverage starts with the first scenario, once `setupSteps()` has set the settings.
    }

    func testSuiteFinished(at _: Date) {
        guard let recorder, let manifest = recorder.writeManifest() else { return }
        if let problem = recorder.manifest.problem ?? recorder.manifest.scoresProblem.map({ "No scores: \($0)." }) {
            output("CucumberSwift coverage: \(problem)")
        }
        output("CucumberSwift coverage: \(recorder.manifest.scenarios.count) scenarios in \(manifest.deletingLastPathComponent().path)")
    }

    func didStart(feature _: Feature, at _: Date) {
        // A feature's scores come from its scenarios, which each start their own measurement.
    }

    func didStart(scenario _: Scenario, at _: Date) {
        if !hasAsked {
            hasAsked = true
            if isEnabled(), let folder = CoverageRecorder.coverageFolder(path: coveragePath()) {
                readSettings = settings()
                recorder = CoverageRecorder(coverageFolder: folder, counters: counters(), settings: readSettings)
            }
        }
        recorder?.scenarioStarted()
    }

    func didStart(step _: Step, at _: Date) {
        // Coverage is measured for each scenario, not each step.
    }

    func didFinish(feature: Feature, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        let parts = recorder?.featureFinished(feature: feature.uri, featureName: feature.title, line: Int(feature.location.line)) ?? []
        for part in parts {
            let report = CoverageReport(scores: part.scores, settings: readSettings)
            if let rule = part.rule {
                output(report.summary(name: "\(feature.title) › \(rule.title)"))
                report.issues(file: feature.coverageIssueFile, line: rule.line, subject: "Rule").forEach(record)
            } else {
                output(report.summary(name: feature.title))
                report.issues(file: feature.coverageIssueFile, line: Int(feature.location.line), subject: "Feature").forEach(record)
            }
        }
    }

    func didFinish(scenario: Scenario, result _: Reporter.Result, duration: Measurement<UnitDuration>) {
        recorder?.scenarioFinished(CoverageRecorder.FinishedScenario(feature: scenario.feature?.uri ?? "",
                                                                     featureName: scenario.feature?.title ?? "",
                                                                     line: Int(scenario.location.line),
                                                                     name: scenario.title,
                                                                     tags: scenario.tags,
                                                                     duration: duration.converted(to: .seconds).value,
                                                                     group: Self.group(of: scenario),
                                                                     rule: scenario.rule))
    }

    func didFinish(step _: Step, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        // Coverage is measured for each scenario, not each step.
    }
}
