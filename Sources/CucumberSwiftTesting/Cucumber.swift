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
        init(_ feature: Feature) { self.feature = feature }
    }

    public static let shared = Cucumber()

    var definitions = [Definition]()
    var beforeScenarioHooks = [Hook<Scenario>]()
    var afterScenarioHooks = [Hook<Scenario>]()
    var beforeStepHooks = [Hook<Step>]()
    var afterStepHooks = [Hook<Step>]()
    private var isSetUp = false
    private var hasReportedMissingImplementation = false
    /// The process's environment, for the settings that have an environment variable. Tests replace it.
    var environment = ProcessInfo.processInfo.environment

    private var featureRuns = [String: FeatureRun]()
    /// The feature that started last and hasn't finished, for runs that don't say where a feature ends.
    private var openFeature: FeatureRun?
    private var isSuiteStarted = false
    /// The scenarios `shouldRun` has let through, so that `run` doesn't ask `shouldRunWith` a second time.
    private var approvedScenarios = Set<String>()

    /// Whether the scenario's later steps are skipped once a step has recorded an issue, such as a failed
    /// `#expect`, as CucumberSwift skips them once a step has failed. Tests turn it off to see the other.
    var skipsLaterStepsAfterRecordedIssue = true

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

    private static func key(of scenario: GherkinScenario) -> String {
        "\(scenario.file):\(scenario.line):\(scenario.column)"
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
        guard approvedScenarios.contains(Self.key(of: gherkinScenario)) || shouldRun(gherkinScenario) else { return }
        await ScenarioContext.$gherkinScenario.withValue(gherkinScenario) { await perform(gherkinScenario) }
    }

    /// Whether the scenario runs: `CUCUMBER_TAGS` decides when it is set, and otherwise
    /// `shouldRunWith(scenario:tags:)` does, as in CucumberSwift. The tests that CucumberSwiftTestingPlugin
    /// generates for scenarios ask this in an `.enabled` trait, so that a scenario it leaves out is
    /// reported as skipped, and the scenario is not asked again when it runs. It sets up the step
    /// definitions first, because Swift Testing asks before any test has started. A scenario that is left
    /// out starts no feature and tells no observer, as CucumberSwift doesn't generate it.
    public func shouldRun(_ gherkinScenario: GherkinScenario) -> Bool {
        loadStepDefinitions()
        let runs: Bool
        if environment["CUCUMBER_TAGS"] != nil {
            runs = CucumberTags.shouldRun(gherkinScenario.tags, environment: environment)
        } else if let implementation = self as Any as? StepImplementation {
            runs = implementation.shouldRunWith(scenario: Scenario(gherkinScenario, feature: Feature(gherkinScenario)), tags: gherkinScenario.tags)
        } else {
            runs = true
        }
        if runs { approvedScenarios.insert(Self.key(of: gherkinScenario)) }
        return runs
    }

    /// The examples of a Scenario Outline that run, as ``shouldRun(_:)`` decides for each. The test that
    /// CucumberSwiftTestingPlugin generates for an outline takes them as its arguments, so one that is left out
    /// is not a test case at all, as with CucumberSwift, which doesn't generate it.
    public func examplesToRun(_ examples: [GherkinExample]) -> [GherkinExample] {
        examples.filter { shouldRun($0.scenario) }
    }

    private func perform(_ gherkinScenario: GherkinScenario) async {
        let file = gherkinScenario.file
        reportMissingImplementationIfNeeded(at: Self.sourceLocation(file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        let featureRun = startFeature(of: gherkinScenario)
        let scenario = Scenario(gherkinScenario, feature: featureRun.feature)
        let startDate = Date()
        reporters.forEach { $0.didStart(scenario: scenario, at: startDate) }
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
        if await runHooks(afterScenarioHooks, with: scenario, at: scenario.location, in: file, record: record, reversed: reversesAfterHooks) != nil {
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
    func endSuite() {
        guard isSuiteStarted else { return }
        isSuiteStarted = false
        featureRuns.values
            .filter { $0.startDate != nil && !$0.isFinished }
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
            .forEach(finish)
        reporters.forEach { $0.testSuiteFinished(at: Date()) }
    }

    /// Finishes a feature, once all of its scenarios have run. `CucumberFeatureTrait` calls it after the
    /// feature's last test.
    func endFeature(file: String, title: String, line: Int) {
        guard let run = featureRuns[Self.key(file: file, title: title, line: line)], run.startDate != nil else { return }
        finish(run)
    }

    /// The feature a scenario belongs to, started on its first scenario.
    private func startFeature(of scenario: GherkinScenario) -> FeatureRun {
        let key = Self.key(file: scenario.file, title: scenario.featureTitle, line: scenario.featureLine)
        let run = featureRuns[key] ?? FeatureRun(Feature(scenario))
        featureRuns[key] = run
        guard run.startDate == nil else { return run }
        // Scenarios run without the generated tests' traits have nothing to say where a feature ends: it
        // ends where the next one starts.
        if let open = openFeature, open !== run { finish(open) }
        openFeature = run
        let startDate = Date()
        run.startDate = startDate
        reporters.forEach { $0.didStart(feature: run.feature, at: startDate) }
        return run
    }

    private func finish(_ run: FeatureRun) {
        guard !run.isFinished, let startDate = run.startDate else { return }
        run.isFinished = true
        if openFeature === run { openFeature = nil }
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
    /// run: not after a step that is undefined, ambiguous, threw or recorded an issue, such as a failed `#expect`.
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
        // As with CucumberSwift, a step's AfterStep hooks run even when a BeforeStep hook failed, which
        // skips the step itself.
        var failure = await runHooks(beforeStepHooks, with: step, at: step.location, in: file, step: ran, record: record)
        if failure == nil {
            RunningLocation.shared.current = .init(location: location, step: ran, record: record)
            do {
                try await runWithTimeout(record: record) { try await match.body(step) }
            } catch {
                Issue.record(error, Comment(rawValue: ran), sourceLocation: location)
                failure = Self.describe(error)
            }
        }
        let afterFailure = await runHooks(afterStepHooks, with: step, at: step.location, in: file, step: ran, record: record, reversed: reversesAfterHooks)
        failure = failure ?? afterFailure
        // A failed `#expect` doesn't throw: Swift Testing 6.2's issue handling tells the record.
        if failure == nil, !record.messages.isEmpty {
            return finish(.failed(record.messages.joined(separator: "\n")), canContinue: afterFailure == nil && !skipsLaterStepsAfterRecordedIssue)
        }
        return finish(failure.map { .failed($0) } ?? .passed, canContinue: failure == nil)
    }

    /// The step definition to suggest for an undefined step: with a regex literal when
    /// ``Cucumber/generateRegexLiterals`` or `CUCUMBER_GENERATE_REGEX_LITERALS` asks for one, written as
    /// ``StepImplementation/regexLiteralStyle`` says, and otherwise with a Cucumber Expression.
    private func suggestion(for step: Step) -> String {
        guard CucumberSettings.generatesRegexLiterals(environment: environment) else { return step.suggestion }
        let style = (self as Any as? StepImplementation)?.regexLiteralStyle ?? .extendedDelimiter
        return (style == .bareSlash ? step.bareSlashRegexLiteralSuggestion : step.regexLiteralSuggestion) ?? step.suggestion
    }

    /// Runs each hook in order. Returns why one threw, or `nil` when none did.
    private func runHooks<Argument>(
        _ hooks: [Hook<Argument>],
        with argument: Argument,
        at location: Location,
        in file: String,
        step: String? = nil,
        record: IssueRecord,
        reversed: Bool = false
    ) async -> String? {
        for hook in hooks.inPriorityOrder(reversed: reversed) {
            RunningLocation.shared.current = .init(location: Self.sourceLocation(file, location), step: step, record: record)
            do {
                try await runWithTimeout(record: record) { try await hook.body(argument) }
            } catch {
                Issue.record(error, sourceLocation: Self.sourceLocation(file, location))
                return Self.describe(error)
            }
        }
        return nil
    }
}
