//
//  Cucumber.swift
//  CucumberSwiftTesting
//

import Foundation
import Testing

/// Holds the step definitions and hooks, and runs the scenarios the generated tests pass it.
@MainActor
public final class Cucumber {
    struct Definition {
        let keyword: Step.Keyword
        let file: String
        let line: Int
        /// The step definition's body for a step with this text, or `nil` if it doesn't match.
        let body: @MainActor (String) -> (@MainActor (Step) async throws -> Void)?
    }

    /// How a step ended: its result, whether the scenario's later steps run, and whether the step itself
    /// failed, rather than only one of its hooks.
    private struct StepOutcome {
        let result: Reporter.Result
        let canContinue: Bool
        let isStepFailed: Bool
    }

    /// A feature the runner has seen a scenario of, and where it is.
    private final class FeatureRun {
        let feature: Feature
        var startDate: Date?
        var isFailed = false
        var isFinished = false
        /// Starts the feature: runs `BeforeFeature`, then tells the observers. Every scenario of the feature
        /// waits for it, so the hooks run once.
        var starting: Task<Void, Never>?
        /// Why a `BeforeFeature` hook threw, until the feature's first scenario reports it on its first step.
        var startFailure: String?
        init(_ feature: Feature) { self.feature = feature }

        func takeStartFailure() -> String? {
            defer { startFailure = nil }
            return startFailure
        }
    }

    public static let shared = Cucumber()

    var definitions = [Definition]()
    var beforeScenarioHooks = [Hook<Scenario>]()
    var afterScenarioHooks = [Hook<Scenario>]()
    var beforeStepHooks = [Hook<Step>]()
    var afterStepHooks = [Hook<Step>]()
    var beforeFeatureHooks = [Hook<Feature>]()
    var afterFeatureHooks = [Hook<Feature>]()
    var isSetUp = false
    private var hasReportedMissingImplementation = false
    /// The process's environment, for the settings that have an environment variable. Tests replace it.
    var environment = ProcessInfo.processInfo.environment

    private var featureRuns = [String: FeatureRun]()
    /// The feature that started last and hasn't finished, for runs that don't say where a feature ends.
    private var openFeature: FeatureRun?
    private var isSuiteStarted = false
    var hasReportedParallelTestingTooLate = false
    /// The scenarios `shouldRun` has let through, so that `run` doesn't ask `shouldRunWith` a second time.
    var approvedScenarios = Set<String>()

    /// Whether the scenario's later steps are skipped once a step has recorded an issue, such as a failed
    /// `#expect`, as CucumberSwift skips them once a step has failed. Tests turn it off to see the other.
    var skipsLaterStepsAfterRecordedIssue = true

    /// The runner's own observers, then the ones from ``CucumberTestObservable``. Built on first use.
    lazy var reporters: [CucumberTestObserver] = makeReporters()

    /// Whether to print each feature, scenario and step as it runs.
    var isVerbose: Bool {
        Cucumber.verboseOutput || VerboseOutput.isEnabled(in: environment) || ((self as Any as? StepImplementation)?.verbose ?? false)
    }

    private static func sourceLocation(_ file: String, _ location: Location) -> SourceLocation {
        let name = URL(fileURLWithPath: file).lastPathComponent
        return SourceLocation(fileID: "Features/\(name)", filePath: file, line: max(location.line, 1), column: max(location.column, 1))
    }

    private static func key(file: String, title: String, line: Int) -> String {
        "\(file):\(line):\(title)"
    }

    private static func describe(_ error: any Error) -> String {
        (error as? any LocalizedError)?.errorDescription ?? String(describing: error)
    }

    private init() {}

    func makeReporters() -> [CucumberTestObserver] {
        // The verbose reporter is always installed, because the reporters are built before `setupSteps()`
        // can set `Cucumber.verboseOutput`: it asks on every line whether it should print.
        // swiftlint:disable:next trailing_closure
        var observers: [CucumberTestObserver?] = [CucumberJSONReporter(), VerboseReporter(isEnabled: { [weak self] in self?.isVerbose ?? false })]
        observers += (self as Any as? CucumberTestObservable)?.observers ?? []
        return observers.compactMap { $0 }
    }

    func register(
        keyword: Step.Keyword,
        file: StaticString,
        line: Int,
        body: @escaping @MainActor (String) -> (@MainActor (Step) async throws -> Void)?
    ) {
        definitions.append(Definition(keyword: keyword, file: "\(file)", line: line, body: body))
    }

    /// Runs a scenario's steps in order, between its hooks. A step that no step definition matches, that
    /// more than one matches, or whose step definition throws, fails at its line in the feature file, and
    /// the scenario's later steps don't run. A failed `#expect` fails where it is written, and the
    /// scenario's later steps don't run either, as after a failed XCTest assertion with CucumberSwift: the
    /// runner learns of it from Swift Testing 6.2's issue handling, and before it, a step that only
    /// fails an `#expect` is reported as passed.
    ///
    /// Tells the observers what happens: the feature when its first scenario starts, then the scenario
    /// and each of its steps as they start and finish.
    public func run(_ gherkinScenario: GherkinScenario) async {
        loadStepDefinitions()
        reportParallelTestingSetTooLate(at: Self.sourceLocation(gherkinScenario.file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        guard approvedScenarios.contains(Self.key(of: gherkinScenario)) || shouldRun(gherkinScenario) else { return }
        await ScenarioContext.$gherkinScenario.withValue(gherkinScenario) { await perform(gherkinScenario) }
    }

    private func perform(_ gherkinScenario: GherkinScenario) async {
        let file = gherkinScenario.file
        reportMissingImplementationIfNeeded(at: Self.sourceLocation(file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        let featureRun = startFeature(of: gherkinScenario)
        await featureRun.starting?.value
        let scenario = Scenario(gherkinScenario, feature: featureRun.feature)
        let startDate = Date()
        reporters.forEach { $0.didStart(scenario: scenario, at: startDate) }
        let record = IssueRecord()
        // As with CucumberSwift, a scenario and its feature fail when a step or a hook does: XCTest fails the
        // step that is current when the hook fails.
        var isFailed = false
        // BeforeFeature and BeforeScenario hooks fail the scenario's first step in XCTest, which is the current
        // step while they run, and the later steps are skipped.
        let featureHookFailure = featureRun.takeStartFailure()
        let scenarioHookFailure = await runHooks(beforeScenarioHooks, with: scenario, at: scenario.location, in: file, record: record)
        if let beforeFailure = featureHookFailure ?? scenarioHookFailure {
            isFailed = true
            if let first = scenario.steps.first { reportFailed(first, beforeFailure) }
        } else {
            for step in scenario.steps {
                let outcome = await run(step, in: file)
                if outcome.isStepFailed { isFailed = true }
                if !outcome.canContinue { break }
            }
        }
        if await runHooks(afterScenarioHooks, with: scenario, at: scenario.location, in: file, record: record, reversed: reversesAfterHooks) != nil {
            isFailed = true
        }
        scenario.scenarioState.removeAll()
        // A failed `#expect` in a hook, which Swift Testing 6.2's issue handling reports to the record.
        isFailed = isFailed || !record.messages.isEmpty
        if isFailed { featureRun.isFailed = true }
        let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
        reporters.forEach { $0.didFinish(scenario: scenario, result: isFailed ? .failed : .passed, duration: duration) }
    }

    // MARK: Suite and feature events

    /// Forgets the features and the suite the observers were told about, for the runner's own tests.
    func resetObservation() {
        featureRuns.removeAll()
        openFeature = nil
        isSuiteStarted = false
        approvedScenarios.removeAll()
    }

    /// Starts the test suite for the observers, once. `CucumberSuiteTrait` calls it before the first test.
    func beginSuite() {
        guard !isSuiteStarted else { return }
        isSuiteStarted = true
        featureRuns.removeAll()
        openFeature = nil
        // The step definitions can set `Cucumber.reportPath`, which the report is written to.
        loadStepDefinitions()
        reporters.forEach { $0.testSuiteStarted(at: Date()) }
    }

    /// Finishes the features that are still open, and the test suite. `CucumberSuiteTrait` calls it after
    /// the last test.
    func endSuite() async {
        guard isSuiteStarted else { return }
        isSuiteStarted = false
        let open = featureRuns.values
            .filter { $0.startDate != nil && !$0.isFinished }
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
        for run in open {
            await finish(run)
        }
        reporters.forEach { $0.testSuiteFinished(at: Date()) }
    }

    /// Finishes a feature, once all of its scenarios have run. `CucumberFeatureTrait` calls it after the
    /// feature's last test.
    func endFeature(file: String, title: String, line: Int) async {
        guard let run = featureRuns[Self.key(file: file, title: title, line: line)], run.startDate != nil else { return }
        await finish(run)
    }

    /// The feature a scenario belongs to, started on its first scenario.
    private func startFeature(of scenario: GherkinScenario) -> FeatureRun {
        let key = Self.key(file: scenario.file, title: scenario.featureTitle, line: scenario.featureLine)
        let run = featureRuns[key] ?? FeatureRun(Feature(scenario))
        featureRuns[key] = run
        guard run.startDate == nil else { return run }
        // Scenarios run without the generated tests' traits have nothing to say where a feature ends: it
        // ends where the next one starts. With them, the suite has started and each feature ends after its
        // last scenario, and ending a feature when another starts would cut short one whose scenarios are
        // still running, since features run at the same time.
        let open = isSuiteStarted ? nil : openFeature
        openFeature = run
        let startDate = Date()
        run.startDate = startDate
        // The hooks get the feature, not the first scenario, and set the running location themselves.
        run.starting = Task { @MainActor [self] in
            if let open, open !== run { await finish(open) }
            // As with CucumberSwift, the hooks run before the observers hear the feature started.
            let record = IssueRecord()
            run.startFailure = await runHooks(beforeFeatureHooks, with: run.feature, at: run.feature.location, in: run.feature.uri, record: record)
            if run.startFailure != nil || !record.messages.isEmpty {
                run.isFailed = true
            }
            reporters.forEach { $0.didStart(feature: run.feature, at: Date()) }
        }
        return run
    }

    /// The scenario that a hook's argument belongs to: the scenario itself, or a step's. A feature hook has none.
    private static func scenario(of argument: Any) -> Scenario? {
        (argument as? Scenario) ?? (argument as? Step)?.scenario
    }

    private func finish(_ run: FeatureRun) async {
        guard !run.isFinished, let startDate = run.startDate else { return }
        run.isFinished = true
        if openFeature === run { openFeature = nil }
        // The after hooks run even when a before hook threw, once the before hooks are over.
        _ = await run.starting?.value
        let record = IssueRecord()
        if await runHooks(afterFeatureHooks, with: run.feature, at: run.feature.location, in: run.feature.uri, record: record, reversed: reversesAfterHooks) != nil
            || !record.messages.isEmpty {
            run.isFailed = true
        }
        let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
        reporters.forEach { $0.didFinish(feature: run.feature, result: run.isFailed ? .failed : .passed, duration: duration) }
    }

    /// Calls `setupSteps()` once, before the first scenario or the suite starts.
    func loadStepDefinitions() {
        guard !isSetUp else { return }
        isSetUp = true
        (self as Any as? StepImplementation)?.setupSteps()
    }

    /// `Cucumber.parallelTesting` set in `setupSteps()` is read when Swift Testing discovers the tests, if
    /// that happens on the main thread, which is where `setupSteps()` can run then. If it can't be read
    /// in time, the scenarios run one at a time and this says so once, without failing the run.
    private func reportParallelTestingSetTooLate(at location: SourceLocation) {
        guard !hasReportedParallelTestingTooLate, CucumberSettings.staticParallelTesting == true,
              CucumberSettings.isSuiteSerialized else { return }
        hasReportedParallelTestingTooLate = true
        let message = """
            Cucumber.parallelTesting was set to true, but scenarios run one at a time: Swift Testing decided that before \
            setupSteps() ran. Set the environment variable CUCUMBER_PARALLEL_TESTING to YES in your scheme, or on the \
            command line, or define CUCUMBER_PARALLEL_TESTING as a compilation condition in the test target.
            """
        #if compiler(>=6.3)
        Issue.record(Comment(rawValue: message), severity: .warning, sourceLocation: location)
        #else
        FileHandle.standardError.write(Data((message + "\n").utf8))
        #endif
    }

    /// Without step definitions, fails at the first scenario in its feature file.
    private func reportMissingImplementationIfNeeded(at location: SourceLocation) {
        guard !hasReportedMissingImplementation, !(self is any StepImplementation) else { return }
        hasReportedMissingImplementation = true
        Issue.record("No step definitions: add `extension Cucumber: StepImplementation` with a `setupSteps()` to the test target.",
                     sourceLocation: location)
    }

    /// Runs one step, and tells the observers. Returns how it ended, and whether the scenario's later steps
    /// run: not after a step that is undefined, ambiguous, threw or recorded an issue, such as a failed `#expect`.
    private func run(_ step: Step, in file: String) async -> StepOutcome {
        let location = Self.sourceLocation(file, step.location)
        let startDate = Date()
        reporters.forEach { $0.didStart(step: step, at: startDate) }
        // `isStepFailed` is whether the step or one of its hooks failed, as XCTest fails the current step for either.
        func finish(_ result: Reporter.Result, canContinue: Bool = false, isStepFailed: Bool = true) -> StepOutcome {
            let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
            reporters.forEach { $0.didFinish(step: step, result: result, duration: duration) }
            return StepOutcome(result: result, canContinue: canContinue, isStepFailed: isStepFailed)
        }
        let matches = definitions.compactMap { definition -> (definition: Definition, body: @MainActor (Step) async throws -> Void)? in
            guard step.keyword.isSuperset(of: definition.keyword), let body = definition.body(step.match) else { return nil }
            return (definition, body)
        }
        guard let match = matches.first else {
            let message = Self.missingStepDefinitionMessage(suggestion: suggestion(for: step))
            Issue.record(Comment(rawValue: message), sourceLocation: location)
            return finish(.failed(message))
        }
        guard matches.count == 1 else {
            let message = Self.ambiguousStepMessage(step: "\(step.keywordName) \(step.match)", definitions: matches.map(\.definition))
            Issue.record(Comment(rawValue: message), sourceLocation: location)
            return finish(.ambiguous)
        }
        let ran = "\(step.keywordName) \(step.match)"
        let record = IssueRecord()
        let beforeRecord = IssueRecord()
        let afterRecord = IssueRecord()
        // As with CucumberSwift, a step's AfterStep hooks run even when a BeforeStep hook failed, which
        // skips the step itself.
        var failure = await runHooks(beforeStepHooks, with: step, at: step.location, in: file, step: ran, record: beforeRecord)
        if failure == nil {
            do {
                try await RunningLocation.$current.withValue(.init(location: location, step: ran, record: record, scenario: step.scenario)) {
                    try await runWithTimeout(record: record) { try await match.body(step) }
                }
            } catch {
                Issue.record(error, Comment(rawValue: ran), sourceLocation: location)
                failure = Self.describe(error)
            }
        }
        // The step's result goes to the observers before its AfterStep hooks run, as in XCTest: a failure in
        // those fails the scenario and its feature, and skips the later steps, but the step was reported.
        // A failed `#expect` doesn't throw: Swift Testing 6.2's issue handling tells the records.
        let messages = beforeRecord.messages + record.messages
        let reported: Reporter.Result = failure.map { .failed($0) } ?? (messages.isEmpty ? .passed : .failed(messages.joined(separator: "\n")))
        let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
        reporters.forEach { $0.didFinish(step: step, result: reported, duration: duration) }
        let afterFailure = await runHooks(afterStepHooks, with: step, at: step.location, in: file, step: ran, record: afterRecord, reversed: reversesAfterHooks)
        let recordedIssue = !messages.isEmpty || !afterRecord.messages.isEmpty
        let isStepFailed = failure != nil || afterFailure != nil || recordedIssue
        // The later steps are skipped after a thrown error, and after an issue, as in CucumberSwift: see `skipsLaterStepsAfterRecordedIssue`.
        let canContinue = failure == nil && afterFailure == nil && !(skipsLaterStepsAfterRecordedIssue && recordedIssue)
        return StepOutcome(result: reported, canContinue: canContinue, isStepFailed: isStepFailed)
    }

    /// Runs each hook in order, as CucumberSwift does: one that throws doesn't stop the ones after it.
    /// Returns why the first that threw did, or `nil` when none did.
    private func runHooks<Argument>(
        _ hooks: [Hook<Argument>],
        with argument: Argument,
        at location: Location,
        in file: String,
        step: String? = nil,
        record: IssueRecord,
        reversed: Bool = false
    ) async -> String? {
        var failure: String?
        for hook in hooks.inPriorityOrder(reversed: reversed) {
            do {
                try await RunningLocation.$current.withValue(.init(location: Self.sourceLocation(file, location), step: step, record: record, scenario: Self.scenario(of: argument))) {
                    try await runWithTimeout(record: record) { try await hook.body(argument) }
                }
            } catch {
                Issue.record(error, sourceLocation: hook.sourceLocation)
                failure = failure ?? Self.describe(error)
            }
        }
        return failure
    }
}
