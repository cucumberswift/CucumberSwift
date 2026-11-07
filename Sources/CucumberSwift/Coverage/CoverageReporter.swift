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
    /// The scenario being measured, so that it starts once although the runner may announce it twice.
    private var startedScenario: ObjectIdentifier?
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

    /// The runner calls this before a scenario's `BeforeScenario` hooks, when they run before the observers hear that
    /// the scenario started, as in the XCTest runner. The scenario's coverage then includes the code its hooks run, as
    /// it does with the Swift Testing runner, where the observers hear it first.
    func willRunBeforeScenarioHooks(for scenario: Scenario) {
        begin(scenario)
    }

    func didStart(scenario: Scenario, at _: Date) {
        begin(scenario)
    }

    /// Starts measuring `scenario`, once, whichever of the two calls comes first.
    private func begin(_ scenario: Scenario) {
        guard startedScenario != ObjectIdentifier(scenario) else { return }
        startedScenario = ObjectIdentifier(scenario)
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
        let detections = reportMutation(of: feature)
        let parts = recorder?.featureFinished(feature: feature.uri,
                                              featureName: feature.title,
                                              line: Int(feature.location.line),
                                              detections: detections) ?? []
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

    /// Prints what the feature's Mutation test finds and records its issues, with mutation testing on. It reads the
    /// feature's scenarios from the recorder, so it runs before the recorder finishes the feature. Without a report,
    /// or with one it can't read, the feature gets an error, so that turning mutation testing on never passes silently.
    ///
    /// Returns the mutants each scenario detected, for the redundancy to judge the scenarios by them too, or nil when
    /// the redundancy judges by code alone: with mutation testing off, or without a report that is up to date.
    private func reportMutation(of feature: Feature) -> CoverageScores.Detections? {
        guard readSettings.isMutationTesting, let recorder else { return nil }
        guard recorder.code != nil else {
            output("CucumberSwift mutation: \(feature.title): no Mutation test, because coverage has no scores.")
            return nil
        }
        let line = Int(feature.location.line)
        guard let path = readSettings.mutationReport else {
            let message = "Mutation testing is on, but no mutation report is set. Run `cucumberswift-mutation-test`, then set "
                + "Cucumber.mutationReport or CUCUMBER_MUTATION_REPORT to the mutation-report.json it writes to .build/mutation-testing."
            record(CoverageIssue(severity: .error, message: message, file: feature.coverageIssueFile, line: line, kind: .mutation))
            return nil
        }
        let read = mutationReport ?? MutationReport.read(path: path)
        mutationReport = read
        switch read {
            case .failure(let error):
                let message = "Mutation testing is on, but \(error.message). Run `cucumberswift-mutation-test` to write it."
                record(CoverageIssue(severity: .error, message: message, file: feature.coverageIssueFile, line: line, kind: .mutation))
                return nil
            case .success(let report):
                let code = MutationFindings.CodeLookup(regions: recorder.regions(file:line:column:)) { file in
                    recorder.sourcePath(endingWith: file).flatMap { try? String(contentsOfFile: $0, encoding: .utf8) }
                }
                let findings = MutationFindings.make(report: report,
                                                     scenarios: recorder.scenarios(of: feature.uri),
                                                     code: code,
                                                     file: feature.coverageIssueFile,
                                                     featureLine: line,
                                                     feature: MutationReport.feature(ofURI: feature.uri))
                record(findings: findings, for: feature)
                guard findings?.isOutOfDate != true else { return nil }
                return CoverageScores.Detections(kills: findings?.kills ?? [:], changes: findings?.changes ?? [:])
        }
    }

    private func record(findings: MutationFindings?, for feature: Feature) {
        guard let findings else {
            output("CucumberSwift mutation: \(feature.title): no mutant in the code its scenarios run")
            return
        }
        guard findings.counted > 0 else {
            output("CucumberSwift mutation: \(feature.title): the mutation report can't score its scenarios, see the error")
            findings.issues.forEach(record)
            return
        }
        let result = findings.survived == 0 ? "detected all" : "missed \(findings.survived) of"
        output("CucumberSwift mutation: \(feature.title): its scenarios \(result) \(findings.counted) mutants in the code they run")
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
        // The next scenario starts afresh even when it has this one's identity: the Swift Testing runner frees a
        // scenario when its test ends, and the next may take the same address. It would otherwise never start, and its
        // coverage would be lost without a message.
        startedScenario = nil
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
