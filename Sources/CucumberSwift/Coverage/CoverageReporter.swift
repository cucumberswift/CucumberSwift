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
    /// The mutation report, read once, when the first feature with a Mutation score finishes.
    private var mutationReport: Result<MutationReport, MutationReport.ReadError>?
    private var hasAsked = false
    /// The running scenario's steps that finished, and how many of its steps are its Background's.
    private var finishedSteps = 0
    private var backgroundStepCount = 0

    /// The lines of the scenario's steps after its Background, which the examples of a Scenario Outline
    /// share, and no two other scenarios do.
    static func group(of scenario: Scenario) -> String {
        let steps = scenario.steps.dropFirst(scenario.backgroundStepCount)
        guard !steps.isEmpty else { return "line \(scenario.location.line)" }
        return steps.map { "\($0.location.line)" }.joined(separator: ",")
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
        guard let recorder else { return }
        let manifest = recorder.writeManifest()
        if let problem = recorder.manifest.problem ?? recorder.manifest.scoresProblem.map({ "No scores: \($0)." }) {
            output("CucumberSwift coverage: \(problem)")
        }
        if let manifest {
            output("CucumberSwift coverage: \(recorder.manifest.scenarios.count) scenarios in \(manifest.deletingLastPathComponent().path)")
        }
    }

    func didStart(feature _: Feature, at _: Date) {
        // A feature's scores come from its scenarios, which each start their own measurement.
    }

    func didStart(scenario: Scenario, at _: Date) {
        if !hasAsked {
            hasAsked = true
            let path = coveragePath()
            if isEnabled(), let folder = CoverageRecorder.coverageFolder(path: path) {
                readSettings = settings()
                recorder = CoverageRecorder(coverageFolder: folder, counters: counters(), settings: readSettings, removesEarlierRuns: path == nil)
            }
        }
        finishedSteps = 0
        backgroundStepCount = scenario.backgroundStepCount
        recorder?.scenarioStarted()
    }

    func didStart(step _: Step, at _: Date) {
        recorder?.stepStarted()
    }

    func didFinish(feature: Feature, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        reportMutation(of: feature)
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

    /// Prints the feature's Mutation score and records its issues, with a mutation report set. It reads the
    /// feature's scenarios from the recorder, so it runs before the recorder finishes the feature.
    private func reportMutation(of feature: Feature) {
        guard let path = readSettings.mutationReport, let recorder, recorder.code != nil else { return }
        if mutationReport == nil {
            mutationReport = MutationReport.read(path: path)
            if case .failure(let error) = mutationReport { output("CucumberSwift mutation: no Mutation score: \(error.message).") }
        }
        guard case .success(let report) = mutationReport else { return }
        guard let findings = MutationFindings.make(report: report,
                                                   scenarios: recorder.scenarios(of: feature.uri),
                                                   regions: recorder.regions(file:line:column:),
                                                   file: feature.coverageIssueFile,
                                                   featureLine: Int(feature.location.line)) else {
            output("CucumberSwift mutation: \(feature.title): no mutant in the code its scenarios run")
            return
        }
        output("CucumberSwift mutation: \(feature.title): \(CoverageReport.percent(findings.percent)) "
            + "(\(findings.detected) of \(findings.counted) mutants in the code its scenarios run detected)")
        findings.issues.forEach(record)
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

    func didFinish(step: Step, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        // The Background's steps come first, so its last one is the scenario's step at that count.
        recorder?.stepFinished(line: Int(step.location.line), isBackground: finishedSteps < backgroundStepCount)
        finishedSteps += 1
        if finishedSteps == backgroundStepCount {
            recorder?.backgroundFinished()
        }
    }
}
