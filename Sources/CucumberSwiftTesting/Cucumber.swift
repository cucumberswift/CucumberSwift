//
//  Cucumber.swift
//  CucumberSwiftTesting
//

import Foundation
import Testing
#if canImport(XCTest)
// For `XCTSkip`, which skips the rest of a scenario as in CucumberSwift.
import XCTest
#endif

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

    /// How a step ended: its result, whether the scenario's later steps run, whether the step itself
    /// failed, rather than only one of its hooks, and why it skipped its scenario, if it did.
    private struct StepOutcome {
        let result: Reporter.Result
        let canContinue: Bool
        let isStepFailed: Bool
        var skipReason: String?
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

    /// A scenario that has started and not finished: between its cases, when each of its steps is a test.
    private final class ScenarioProgress {
        let gherkin: GherkinScenario
        let scenario: Scenario
        let featureRun: FeatureRun
        let startDate = Date()
        let record = IssueRecord()
        var nextStep = 0
        var isFailed = false
        /// Whether a step or a hook failed, or a step skipped the scenario, so that the later steps don't run.
        var isStopped = false
        /// Why a step skipped the scenario, by throwing `XCTSkip` or calling `Test.cancel`.
        var skipReason: String?
        init(_ gherkin: GherkinScenario, scenario: Scenario, featureRun: FeatureRun) {
            self.gherkin = gherkin
            self.scenario = scenario
            self.featureRun = featureRun
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
    /// The test bundles of the scenarios seen, by URL, and the last one, whose report `endSuite()` copies.
    /// `nil` for scenarios that don't say, as the generated tests do.
    var testBundles = [URL: TestBundle]()
    var testBundle: TestBundle?
    /// Where `endSuite()` copies the report: the documents folder unless set. Tests set it.
    var resultsFolder: URL?
    var hasReportedParallelTestingTooLate = false
    /// The scenarios `shouldRun` has let through, so that `run` doesn't ask `shouldRunWith` a second time.
    var approvedScenarios = Set<String>()
    private var startedScenarios = [String: ScenarioProgress]()
    /// The features written in the Swift DSL.
    var dsl = DSLFeatures()

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

    /// The scenario that a hook's argument belongs to: the scenario itself, or a step's. A feature hook has none.
    private static func scenario(of argument: Any) -> Scenario? {
        (argument as? Scenario) ?? (argument as? Step)?.scenario
    }

    private init() {}

    func makeReporters() -> [CucumberTestObserver] {
        // The verbose reporter is always installed, because the reporters are built before `setupSteps()`
        // can set `Cucumber.verboseOutput`: it asks on every line whether it should print.
        // swiftlint:disable trailing_closure
        var observers: [CucumberTestObserver?] = [
            CucumberJSONReporter(),
            VerboseReporter(isEnabled: { [weak self] in self?.isVerbose ?? false }),
            CoverageReporter(isEnabled: { CucumberSettings.isCoverage() },
                             coveragePath: { CucumberSettings.coveragePath() },
                             settings: {
                                 var settings = CoverageSettings.read(environment: ProcessInfo.processInfo.environment)
                                 settings.isWritingFiles = CucumberSettings.coverageSetting() == true || CucumberSettings.coveragePath() != nil
                                 return settings
                             },
                             record: { $0.record() })
        ]
        // swiftlint:enable trailing_closure
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
        _ = await runWhole(gherkinScenario)
    }

    /// Runs the whole scenario, and returns why a step skipped it, when one did and the scenario didn't fail.
    private func runWhole(_ gherkinScenario: GherkinScenario) async -> String? {
        loadStepDefinitions()
        reportParallelTestingSetTooLate(at: Self.sourceLocation(gherkinScenario.file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        guard approvedScenarios.contains(Self.key(of: gherkinScenario)) || shouldRun(gherkinScenario) else { return nil }
        return await inFeatureOrder(gherkinScenario) { await ScenarioContext.$gherkinScenario.withValue(gherkinScenario) { await self.perform(gherkinScenario) } }
    }

    private func perform(_ gherkinScenario: GherkinScenario) async -> String? {
        let progress = await begin(gherkinScenario)
        while !progress.isStopped, progress.nextStep < progress.scenario.steps.count {
            await runNextStep(of: progress)
        }
        let isFailed = await end(progress)
        await endDSLFeatureIfLast(progress)
        return isFailed ? nil : progress.skipReason
    }

    /// Runs one case of a scenario's test: the whole scenario, or one step. The cases of a scenario run in
    /// order, so the first runs `BeforeScenario` hooks and the last the `AfterScenario` hooks, and a case
    /// run alone first runs the steps before it. Once a step has failed, or skipped its scenario by throwing
    /// `XCTSkip` or calling `Test.cancel`, the cases after it don't run their steps; Swift 6.3 reports them as
    /// skipped, as it does the step that skipped, and a scenario that is one case. Before it they pass.
    public func run(_ testCase: ScenarioCase) async throws {
        guard let index = testCase.stepIndex else {
            if let reason = await runWhole(testCase.scenario) { try cancelCase(reason) }
            return
        }
        let gherkinScenario = testCase.scenario
        loadStepDefinitions()
        reportParallelTestingSetTooLate(at: Self.sourceLocation(gherkinScenario.file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        guard approvedScenarios.contains(Self.key(of: gherkinScenario)) || shouldRun(gherkinScenario) else { return }
        let key = Self.key(of: gherkinScenario)
        var skipComment: String?
        await ScenarioContext.$gherkinScenario.withValue(gherkinScenario) {
            var started = startedScenarios[key]
            if let previous = started, previous.nextStep > index {
                await end(previous)
                started = nil
            }
            let progress: ScenarioProgress
            if let started {
                progress = started
            } else {
                progress = await begin(gherkinScenario)
            }
            startedScenarios[key] = progress
            while !progress.isStopped, progress.nextStep < index {
                await runNextStep(of: progress)
            }
            if progress.isStopped {
                // As CucumberSwift says why it skipped a step's test.
                skipComment = progress.skipReason.map { "Skipped: \($0)" } ?? "Skipped: an earlier step in this scenario failed."
            } else {
                await runNextStep(of: progress)
                // The step that skipped its scenario is skipped too, with its reason, unless it failed.
                if let reason = progress.skipReason, !progress.isFailed { skipComment = reason }
            }
            if index == gherkinScenario.steps.count - 1 {
                await end(progress)
                await endDSLFeatureIfLast(progress)
            }
        }
        if let skipComment { try cancelCase(skipComment) }
    }

    /// Starts a scenario: its feature if it is the first, the observers, and the `BeforeScenario` hooks. A hook
    /// that fails fails the scenario's first step, as in XCTest, and the later steps don't run.
    private func begin(_ gherkinScenario: GherkinScenario) async -> ScenarioProgress {
        let file = gherkinScenario.file
        reportMissingImplementationIfNeeded(at: Self.sourceLocation(file, Location(line: gherkinScenario.line, column: gherkinScenario.column)))
        let featureRun = startFeature(of: gherkinScenario)
        await featureRun.starting?.value
        let scenario = Scenario(gherkinScenario, feature: featureRun.feature)
        let progress = ScenarioProgress(gherkinScenario, scenario: scenario, featureRun: featureRun)
        reporters.forEach { $0.didStart(scenario: scenario, at: progress.startDate) }
        // BeforeFeature and BeforeScenario hooks fail the scenario's first step in XCTest, which is the current
        // step while they run, and the later steps are skipped.
        let featureHookFailure = featureRun.takeStartFailure()
        let scenarioHookFailure = await runHooks(beforeScenarioHooks, with: scenario, at: scenario.location, in: file, record: progress.record)
        if let beforeFailure = featureHookFailure ?? scenarioHookFailure {
            progress.isFailed = true
            progress.isStopped = true
            if let first = scenario.steps.first { reportFailed(first, beforeFailure) }
        }
        return progress
    }

    private func runNextStep(of progress: ScenarioProgress) async {
        let step = progress.scenario.steps[progress.nextStep]
        progress.nextStep += 1
        let dslStep = progress.gherkin.dslID.flatMap { dsl.steps[$0] }?[progress.nextStep - 1]
        let outcome = await run(step, in: progress.gherkin.file, dslStep: dslStep)
        // As with CucumberSwift, a scenario and its feature fail when a step or a hook does: XCTest fails the
        // step that is current when the hook fails.
        if outcome.isStepFailed { progress.isFailed = true }
        if !outcome.canContinue { progress.isStopped = true }
        if let reason = outcome.skipReason { progress.skipReason = reason }
    }

    /// Finishes a scenario: the `AfterScenario` hooks and the observers. Returns whether the scenario failed.
    @discardableResult
    private func end(_ progress: ScenarioProgress) async -> Bool {
        startedScenarios[Self.key(of: progress.gherkin)] = nil
        let (scenario, file) = (progress.scenario, progress.gherkin.file)
        var isFailed = progress.isFailed
        if await runHooks(afterScenarioHooks, with: scenario, at: scenario.location, in: file, record: progress.record, reversed: reversesAfterHooks) != nil {
            isFailed = true
        }
        scenario.internalState.removeAll()
        // A failed `#expect` in a hook, which Swift Testing 6.2's issue handling reports to the record.
        isFailed = isFailed || !progress.record.messages.isEmpty
        if isFailed { progress.featureRun.isFailed = true }
        let duration = Measurement(value: Date().timeIntervalSince(progress.startDate), unit: UnitDuration.seconds)
        reporters.forEach { $0.didFinish(scenario: scenario, result: isFailed ? .failed : .passed, duration: duration) }
        return isFailed
    }

    // MARK: Suite and feature events

    /// Forgets the features and the suite the observers were told about, for the runner's own tests.
    func resetObservation() {
        featureRuns.removeAll()
        openFeature = nil
        isSuiteStarted = false
        testBundles.removeAll()
        testBundle = nil
        resultsFolder = nil
        approvedScenarios.removeAll()
        startedScenarios.removeAll()
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

    /// Finishes the features that are still open, and the test suite, and then copies the report to
    /// `CucumberTestResultsFor<test bundle>.json` in the documents folder, as CucumberSwift does when the test
    /// bundle finishes. `CucumberSuiteTrait` calls it after the last test.
    func endSuite() async {
        guard isSuiteStarted else { return }
        isSuiteStarted = false
        // A scenario whose last case didn't run, such as one left out, ends with the suite.
        for progress in Array(startedScenarios.values) {
            await end(progress)
        }
        let open = featureRuns.values
            .filter { $0.startDate != nil && !$0.isFinished }
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
        for run in open {
            await finish(run)
        }
        reportDSLFeaturesNotRun()
        reporters.forEach { $0.testSuiteFinished(at: Date()) }
        testBundle?.copyReport(into: resultsFolder)
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
        let run = featureRuns[key] ?? FeatureRun(feature(of: scenario))
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
            run.startFailure = await runHooks(beforeFeatureHooks, with: run.feature, at: run.feature.location, in: run.feature.sourcePath, record: record)
            if run.startFailure != nil || !record.messages.isEmpty {
                run.isFailed = true
            }
            reporters.forEach { $0.didStart(feature: run.feature, at: Date()) }
        }
        return run
    }

    private func finish(_ run: FeatureRun) async {
        guard !run.isFinished, let startDate = run.startDate else { return }
        // A scenario whose last case didn't run ends before its feature's after hooks and completion.
        for progress in Array(startedScenarios.values) where progress.featureRun === run {
            await end(progress)
        }
        run.isFinished = true
        if openFeature === run { openFeature = nil }
        // The after hooks run even when a before hook threw, once the before hooks are over.
        _ = await run.starting?.value
        let record = IssueRecord()
        if await runHooks(afterFeatureHooks, with: run.feature, at: run.feature.location, in: run.feature.sourcePath, record: record, reversed: reversesAfterHooks) != nil
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

    /// Without step definitions, fails at the first scenario in its feature file.
    private func reportMissingImplementationIfNeeded(at location: SourceLocation) {
        guard !hasReportedMissingImplementation, !(self is any StepImplementation) else { return }
        hasReportedMissingImplementation = true
        Issue.record("No step definitions: add `extension Cucumber: StepImplementation` with a `setupSteps()` to the test target.",
                     sourceLocation: location)
    }

    /// Runs one step, and tells the observers. Returns how it ended, and whether the scenario's later steps
    /// run: not after a step that is undefined, ambiguous, threw or recorded an issue, such as a failed `#expect`.
    private func run(_ step: Step, in featureFile: String, dslStep: DSLStep?) async -> StepOutcome {
        // A step of the Swift DSL is where it is written, which can be another file than its feature's.
        let file = dslStep?.file ?? featureFile
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
        // A step of the Swift DSL runs what it was written with, unless a step definition matches its text,
        // which then runs instead, as in CucumberSwift: `attachClosureToSteps` replaces the step's own closure.
        let dslBody: (@MainActor (Step) async throws -> Void)? = matches.isEmpty ? dslStep.map { dsl in { _ in try await dsl.body() } } : nil
        guard let body = dslBody ?? matches.first?.body else {
            let message = Self.missingStepDefinitionMessage(suggestion: suggestion(for: step))
            Issue.record(Comment(rawValue: message), sourceLocation: location)
            return finish(.failed(message))
        }
        guard matches.count <= 1 else {
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
        var skipReason: String?
        if failure == nil {
            do {
                try await RunningLocation.$current.withValue(.init(location: location, step: ran, record: record, scenario: step.scenario)) {
                    try await runWithTimeout(record: record, continuesAfterFailure: dslStep?.continuesAfterFailure) { try await body(step) }
                }
            } catch let error where Self.skipReason(of: error) != nil {
                // A step that throws `XCTSkip` or calls `Test.cancel` skips the rest of its scenario, as
                // `XCTSkip` does in CucumberSwift, and doesn't fail.
                skipReason = Self.skipReason(of: error)
            } catch {
                Issue.record(error, Comment(rawValue: ran), sourceLocation: location)
                failure = Self.describe(error)
            }
        }
        // The step's result goes to the observers before its AfterStep hooks run, as in XCTest: a failure in
        // those fails the scenario and its feature, and skips the later steps, but the step was reported.
        // A failed `#expect` doesn't throw: Swift Testing 6.2's issue handling tells the records. A step that
        // failed an `#expect` and then skipped stays failed, as in CucumberSwift.
        let messages = beforeRecord.messages + record.messages
        let unfailed: Reporter.Result = skipReason == nil ? .passed : .skipped
        let reported: Reporter.Result = failure.map { .failed($0) } ?? (messages.isEmpty ? unfailed : .failed(messages.joined(separator: "\n")))
        let duration = Measurement(value: Date().timeIntervalSince(startDate), unit: UnitDuration.seconds)
        reporters.forEach { $0.didFinish(step: step, result: reported, duration: duration) }
        let afterFailure = await runHooks(afterStepHooks, with: step, at: step.location, in: file, step: ran, record: afterRecord, reversed: reversesAfterHooks)
        let recordedIssue = !messages.isEmpty || !afterRecord.messages.isEmpty
        let isStepFailed = failure != nil || afterFailure != nil || recordedIssue
        // The later steps are skipped after a thrown error, and after an issue, as in CucumberSwift: see `skipsLaterStepsAfterRecordedIssue`.
        let canContinue = failure == nil && skipReason == nil && afterFailure == nil && !(skipsLaterStepsAfterRecordedIssue && recordedIssue)
        return StepOutcome(result: reported, canContinue: canContinue, isStepFailed: isStepFailed, skipReason: skipReason)
    }
}

// MARK: Skips and hooks

extension Cucumber {
    /// Why a step skipped its scenario, when the error is a skip: an `XCTSkip`, as in CucumberSwift, or what
    /// `Test.cancel` throws. That type isn't public, so it is known by its name, and its comment is the reason.
    static func skipReason(of error: any Error) -> String? {
        #if canImport(XCTest)
        if let skip = error as? XCTSkip { return skip.message ?? "Skipped" }
        #endif
        guard String(reflecting: type(of: error)) == "Testing.SkipInfo" else { return nil }
        let comment = Mirror(reflecting: error).children.first { $0.label == "comment" }?.value as? Comment
        return comment?.rawValue ?? "Skipped"
    }

    /// Reports the running test case as skipped, with the reason. A step's `Test.cancel` has already
    /// cancelled it, but the runner caught what it threw, so this says it again once the case is over.
    private func cancelCase(_ comment: String) throws {
        #if compiler(>=6.3)
        try Test.cancel(Comment(rawValue: comment))
        #endif
    }

    /// Runs each hook in order, as CucumberSwift does: one that throws doesn't stop the ones after it.
    /// Returns why the first that threw did, or `nil` when none did.
    ///
    /// A step's `Test.cancel` cancels its test case's task, in which the hooks would see the cancellation:
    /// their timeout would end at once, and whatever they await would throw. So they then run in a task of
    /// their own, as they would after an `XCTSkip` in CucumberSwift.
    private func runHooks<Argument>(
        _ hooks: [Hook<Argument>],
        with argument: Argument,
        at location: Location,
        in file: String,
        step: String? = nil,
        record: IssueRecord,
        reversed: Bool = false
    ) async -> String? {
        guard !Task.isCancelled || hooks.isEmpty else {
            let task = Task { @MainActor [self] in
                await runHooks(hooks, with: argument, at: location, in: file, step: step, record: record, reversed: reversed)
            }
            return await task.value
        }
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

// In this file, for the runner's private types; outside the class, which is long enough.
extension Cucumber {
    /// `Cucumber.parallelTesting` set in `setupSteps()` is read when Swift Testing discovers the tests, if
    /// that happens on the main thread, which is where `setupSteps()` can run then. If it can't be read
    /// in time, the scenarios run one at a time and this says so once, without failing the run.
    /// With coverage on, scenarios run one at a time because of coverage, whenever parallel testing was
    /// set, so there is nothing to say.
    func reportParallelTestingSetTooLate(at location: SourceLocation, isCoverage: Bool = CucumberSettings.isCoverage()) {
        guard !hasReportedParallelTestingTooLate, CucumberSettings.staticParallelTesting == true,
              CucumberSettings.isSuiteSerialized, !isCoverage else { return }
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

    /// Finishes a feature of the Swift DSL after its last scenario that runs, as CucumberSwift does. They are all
    /// one test, so no feature's suite says where it ends.
    private func endDSLFeatureIfLast(_ progress: ScenarioProgress) async {
        guard progress.gherkin.dslID != nil else { return }
        let key = DSLFeatures.featureKey(of: progress.gherkin)
        guard let unfinished = dsl.unfinished[key] else { return }
        dsl.unfinished[key] = unfinished - 1
        if unfinished <= 1 { await finish(progress.featureRun) }
    }
}
