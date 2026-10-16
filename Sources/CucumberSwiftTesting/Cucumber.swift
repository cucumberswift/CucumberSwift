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

    /// A feature the runner has seen a scenario of, and where it is.
    private final class FeatureRun {
        let feature: Feature
        var startDate: Date?
        var isFailed = false
        var isFinished = false
        /// Starts the feature: tells the observers and runs `BeforeFeature`. Every scenario of the feature waits
        /// for it, so the hooks run once. Its value is why a hook threw, or `nil`.
        var starting: Task<String?, Never>?
        init(_ feature: Feature) { self.feature = feature }
    }

    public static let shared = Cucumber()

    var definitions = [Definition]()
    var beforeScenarioHooks = [Hook<Scenario>]()
    var afterScenarioHooks = [Hook<Scenario>]()
    var beforeStepHooks = [Hook<Step>]()
    var afterStepHooks = [Hook<Step>]()
    var beforeFeatureHooks = [Hook<Feature>]()
    var afterFeatureHooks = [Hook<Feature>]()
    private var isSetUp = false
    private var hasReportedMissingImplementation = false
    /// The process's environment, for the settings that have an environment variable. Tests replace it.
    var environment = ProcessInfo.processInfo.environment

    private var featureRuns = [String: FeatureRun]()
    /// The feature that started last and hasn't finished, for runs that don't say where a feature ends.
    private var openFeature: FeatureRun?
    private var isSuiteStarted = false

    /// The runner's own observers, then the ones from ``CucumberTestObservable``. Built on first use.
    lazy var reporters: [CucumberTestObserver] = makeReporters()

    /// Whether to print each feature, scenario and step as it runs.
    var isVerbose: Bool {
        Cucumber.verboseOutput || VerboseOutput.isEnabled(in: environment) || ((self as Any as? StepImplementation)?.verbose ?? false)
    }

    /// CucumberSwift's message for a step that no step definition matches.
    static func missingStepDefinitionMessage(suggestion: String) -> String {
        "No CucumberSwift expression found that matches this step. Try adding the following Swift code to your step implementation file: \n\(suggestion)"
    }

    /// CucumberSwift's message for a step that more than one step definition matches.
    static func ambiguousStepMessage(step: String, definitions: [Definition]) -> String {
        let locations = definitions.map { "\(URL(fileURLWithPath: $0.file).lastPathComponent):\($0.line)" }
        let list = locations.count < 2 ? locations.joined() : locations.dropLast().joined(separator: ", ") + " and " + (locations.last ?? "")
        return "Ambiguous step '\(step)': it matches \(locations.count) step definitions, at \(list). Remove all but one of them, or make their patterns more specific." // swiftlint:disable:this line_length
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
    /// scenario goes on, as Swift Testing does; `try #require` stops it.
    ///
    /// Tells the observers what happens: the feature when its first scenario starts, then the scenario
    /// and each of its steps as they start and finish.
    public func run(_ gherkinScenario: GherkinScenario) async {
        let file = gherkinScenario.file
        loadStepDefinitions()
        reportMissingImplementationIfNeeded(at: Self.sourceLocation(file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        let featureRun = startFeature(of: gherkinScenario)
        let featureFailure = await featureRun.starting?.value
        let scenario = Scenario(gherkinScenario, feature: featureRun.feature)
        let startDate = Date()
        reporters.forEach { $0.didStart(scenario: scenario, at: startDate) }
        if let featureFailure {
            // The feature's `BeforeFeature` hook threw, which it reported once: the scenario fails without running.
            Issue.record(Comment(rawValue: "BeforeFeature hook failed: \(featureFailure)"),
                         sourceLocation: Self.sourceLocation(file, scenario.location))
            featureRun.isFailed = true
            let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
            reporters.forEach { $0.didFinish(scenario: scenario, result: .failed, duration: duration) }
            return
        }
        let record = IssueRecord()
        var isFailed = false
        if await runHooks(beforeScenarioHooks, with: scenario, at: scenario.location, in: file, record: record) == nil {
            for step in scenario.steps {
                let outcome = await run(step, in: file)
                if case .passed = outcome.result {
                    // Nothing to record.
                } else {
                    isFailed = true
                }
                if !outcome.canContinue { break }
            }
        } else {
            isFailed = true
        }
        if await runHooks(afterScenarioHooks, with: scenario, at: scenario.location, in: file, record: record) != nil {
            isFailed = true
        }
        RunningLocation.shared.current = nil
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
        // ends where the next one starts.
        let open = openFeature
        openFeature = run
        let startDate = Date()
        run.startDate = startDate
        // The hooks get the feature, not the first scenario, and set the running location themselves.
        run.starting = Task { @MainActor [self] in
            if let open, open !== run { await finish(open) }
            reporters.forEach { $0.didStart(feature: run.feature, at: startDate) }
            return await runHooks(beforeFeatureHooks, with: run.feature, at: run.feature.location, in: run.feature.uri, record: IssueRecord())
        }
        return run
    }

    private func finish(_ run: FeatureRun) async {
        guard !run.isFinished, let startDate = run.startDate else { return }
        run.isFinished = true
        if openFeature === run { openFeature = nil }
        // The after hooks run even when a before hook threw, once the before hooks are over.
        _ = await run.starting?.value
        let record = IssueRecord()
        let afterFailure = await runHooks(afterFeatureHooks, with: run.feature, at: run.feature.location, in: run.feature.uri, record: record)
        RunningLocation.shared.current = nil
        if afterFailure != nil || !record.messages.isEmpty { run.isFailed = true }
        let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
        reporters.forEach { $0.didFinish(feature: run.feature, result: run.isFailed ? .failed : .passed, duration: duration) }
    }

    /// Calls `setupSteps()` once, before the first scenario or the suite starts.
    private func loadStepDefinitions() {
        guard !isSetUp else { return }
        isSetUp = true
        (self as Any as? StepImplementation)?.setupSteps()
    }

    /// Without step definitions, fails at the first scenario in its feature file.
    private func reportMissingImplementationIfNeeded(at location: SourceLocation) {
        guard !hasReportedMissingImplementation, !(self is any StepImplementation) else { return }
        hasReportedMissingImplementation = true
        Issue.record("No step definitions: add `extension Cucumber: StepImplementation` with a `setupSteps()` to the test target.",
                     sourceLocation: location)
    }

    /// Runs one step, and tells the observers. Returns how it ended, and whether the scenario's later steps
    /// run: not after a step that is undefined, ambiguous or threw. A failed `#expect` lets them run.
    private func run(_ step: Step, in file: String) async -> (result: Reporter.Result, canContinue: Bool) {
        let location = Self.sourceLocation(file, step.location)
        let startDate = Date()
        reporters.forEach { $0.didStart(step: step, at: startDate) }
        func finish(_ result: Reporter.Result, canContinue: Bool = false) -> (result: Reporter.Result, canContinue: Bool) {
            let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
            reporters.forEach { $0.didFinish(step: step, result: result, duration: duration) }
            return (result, canContinue)
        }
        let matches = definitions.compactMap { definition -> (definition: Definition, body: @MainActor (Step) async throws -> Void)? in
            guard step.keyword.isSuperset(of: definition.keyword), let body = definition.body(step.match) else { return nil }
            return (definition, body)
        }
        guard let match = matches.first else {
            let message = Self.missingStepDefinitionMessage(suggestion: step.suggestion)
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
        // As with CucumberSwift, a step's AfterStep hooks run even when a BeforeStep hook failed, which
        // skips the step itself.
        var failure = await runHooks(beforeStepHooks, with: step, at: step.location, in: file, step: ran, record: record)
        if failure == nil {
            RunningLocation.shared.current = .init(location: location, step: ran, record: record)
            do {
                try await match.body(step)
            } catch {
                Issue.record(error, Comment(rawValue: ran), sourceLocation: location)
                failure = Self.describe(error)
            }
        }
        let afterFailure = await runHooks(afterStepHooks, with: step, at: step.location, in: file, step: ran, record: record)
        failure = failure ?? afterFailure
        // A failed `#expect` doesn't throw: Swift Testing 6.2's issue handling tells the record.
        if failure == nil, !record.messages.isEmpty {
            return finish(.failed(record.messages.joined(separator: "\n")), canContinue: afterFailure == nil)
        }
        return finish(failure.map { .failed($0) } ?? .passed, canContinue: failure == nil)
    }

    /// Runs each hook in order. Returns why one threw, or `nil` when none did.
    private func runHooks<Argument>(
        _ hooks: [Hook<Argument>],
        with argument: Argument,
        at location: Location,
        in file: String,
        step: String? = nil,
        record: IssueRecord
    ) async -> String? {
        for hook in hooks.inPriorityOrder() {
            RunningLocation.shared.current = .init(location: Self.sourceLocation(file, location), step: step, record: record)
            do {
                try await hook.body(argument)
            } catch {
                Issue.record(error, sourceLocation: Self.sourceLocation(file, location))
                return Self.describe(error)
            }
        }
        return nil
    }
}
