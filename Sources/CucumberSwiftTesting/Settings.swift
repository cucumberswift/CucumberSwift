//
//  Settings.swift
//  CucumberSwiftTesting
//
// The settings the runner reads besides CUCUMBER_TAGS, named as in CucumberSwift.

import Foundation

/// What runs together when scenarios run at the same time. See ``Cucumber/parallelTestingUnit``.
public enum ParallelTestingUnit: String, Sendable {
    /// Any scenario may run at the same time as any other. The default.
    case scenario
    /// A feature's scenarios run one at a time, in the order of the feature file, and features run at the
    /// same time.
    case feature
}

/// The static variables' values. Computed static variables over locked storage are safe to read and set
/// from any isolation, and don't warn in a consumer's Swift 6 target, as stored ones on a main-actor
/// class would.
enum CucumberSettings {
    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var storedReportPath: String?
        private var storedVerboseOutput = false
        private var storedParallelTesting: Bool?
        private var storedParallelTestingUnit: ParallelTestingUnit?
        private var storedIsSuiteSerialized = false
        private var storedGenerateRegexLiterals: Bool?
        private var flags = [String: Bool]()
        private var storedCoveragePath: String?

        var coveragePath: String? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedCoveragePath
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedCoveragePath = newValue
            }
        }

        // `lock()` and `unlock()` rather than `withLock`, which needs macOS 13, iOS 16 and tvOS 16.
        var reportPath: String? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedReportPath
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedReportPath = newValue
            }
        }

        var verboseOutput: Bool {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedVerboseOutput
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedVerboseOutput = newValue
            }
        }

        var parallelTesting: Bool? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedParallelTesting
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedParallelTesting = newValue
            }
        }

        var parallelTestingUnit: ParallelTestingUnit? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedParallelTestingUnit
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedParallelTestingUnit = newValue
            }
        }

        var isSuiteSerialized: Bool {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedIsSuiteSerialized
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedIsSuiteSerialized = newValue
            }
        }

        var generateRegexLiterals: Bool? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedGenerateRegexLiterals
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedGenerateRegexLiterals = newValue
            }
        }

        func flag(_ name: String) -> Bool? {
            lock.lock()
            defer { lock.unlock() }
            return flags[name]
        }

        func setFlag(_ name: String, _ value: Bool?) {
            lock.lock()
            defer { lock.unlock() }
            flags[name] = value
        }
    }

    private static let storage = Storage()

    static let reportPathEnvironmentKey = "CUCUMBER_REPORT_PATH"
    static let parallelTestingEnvironmentKey = "CUCUMBER_PARALLEL_TESTING"
    static let parallelTestingUnitEnvironmentKey = "CUCUMBER_PARALLEL_TESTING_UNIT"

    /// ``Cucumber/reportPath``.
    static var staticReportPath: String? {
        get { storage.reportPath }
        set { storage.reportPath = newValue }
    }

    static var staticVerboseOutput: Bool {
        get { storage.verboseOutput }
        set { storage.verboseOutput = newValue }
    }

    /// ``Cucumber/parallelTesting``.
    static var staticParallelTesting: Bool? {
        get { storage.parallelTesting }
        set { storage.parallelTesting = newValue }
    }

    /// ``Cucumber/parallelTestingUnit``.
    static var staticParallelTestingUnit: ParallelTestingUnit? {
        get { storage.parallelTestingUnit }
        set { storage.parallelTestingUnit = newValue }
    }

    /// Whether the generated suite was made serialized when Swift Testing discovered the tests, which is
    /// before `setupSteps()` runs. False until then, and for scenarios run without the generated suite.
    static var isSuiteSerialized: Bool {
        get { storage.isSuiteSerialized }
        set { storage.isSuiteSerialized = newValue }
    }

    static var reportPath: String? { reportPath() }

    /// ``Cucumber/readableTestNames``.
    static var staticReadableTestNames: Bool? {
        get { storage.flag("readableTestNames") }
        set { storage.setFlag("readableTestNames", newValue) }
    }

    /// ``Cucumber/oneTestPerScenario``.
    static var staticOneTestPerScenario: Bool? {
        get { storage.flag("oneTestPerScenario") }
        set { storage.setFlag("oneTestPerScenario", newValue) }
    }

    static let generateRegexLiteralsEnvironmentKey = "CUCUMBER_GENERATE_REGEX_LITERALS"

    /// ``Cucumber/generateRegexLiterals``.
    static var staticGenerateRegexLiterals: Bool? {
        get { storage.generateRegexLiterals }
        set { storage.generateRegexLiterals = newValue }
    }

    /// ``Cucumber/generateMacros``.
    static var staticGenerateMacros: Bool? {
        get { storage.flag("generateMacros") }
        set { storage.setFlag("generateMacros", newValue) }
    }

    /// Whether the test target links `CucumberSwiftTestingMacros` built with the `Macros` trait, which
    /// declares this class.
    static var linksMacros: Bool {
        NSClassFromString("CucumberSwiftTestingMacrosMarker") != nil
    }

    /// Whether the step definitions the runner suggests use regex literals: the static variable, then
    /// `CUCUMBER_GENERATE_REGEX_LITERALS`, then no. The value is read as CucumberSwift's `FeatureFlags` read it: see `FeatureFlagValue`.
    static func generatesRegexLiterals(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        staticGenerateRegexLiterals ?? FeatureFlagValue.bool(environment[generateRegexLiteralsEnvironmentKey]) ?? false
    }

    /// Whether the step definitions the runner suggests are step definition macros: the static variable,
    /// then `CUCUMBER_GENERATE_MACROS`, as CucumberSwift's `FeatureFlags` read it, then whether the test
    /// target links the macros.
    static func generatesMacros(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        staticGenerateMacros ?? FeatureFlagValue.bool(environment["CUCUMBER_GENERATE_MACROS"]) ?? linksMacros
    }

    /// Whether generated tests are named with the Gherkin text as written: the static variable, then
    /// `CUCUMBER_READABLE_TEST_NAMES`, then yes, as CucumberSwift's `FeatureFlags` read it.
    static func isReadableTestNames(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        staticReadableTestNames ?? FeatureFlagValue.bool(environment["CUCUMBER_READABLE_TEST_NAMES"]) ?? true
    }

    /// Whether each scenario is one test: the static variable, then `CUCUMBER_ONE_TEST_PER_SCENARIO`, then no.
    static func isOneTestPerScenario(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        staticOneTestPerScenario ?? FeatureFlagValue.bool(environment["CUCUMBER_ONE_TEST_PER_SCENARIO"]) ?? false
    }

    /// Where the JSON report is written: the static variable, then `CUCUMBER_REPORT_PATH`. Nil when neither
    /// is set, or is empty, so the report goes to its default place.
    static func reportPath(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let path = staticReportPath ?? environment[reportPathEnvironmentKey]
        let trimmed = path?.trimmingCharacters(in: .whitespaces)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    /// `scenario` or `feature`, in any case, with spaces and tabs around it ignored, as CucumberSwift reads
    /// it. Any other value is not a setting.
    static func parallelTestingUnit(_ value: String?) -> ParallelTestingUnit? {
        value.flatMap { ParallelTestingUnit(rawValue: $0.trimmingCharacters(in: .whitespaces).lowercased()) }
    }

    /// What runs together when scenarios run at the same time: the static variable, then
    /// `CUCUMBER_PARALLEL_TESTING_UNIT`, then `.scenario`.
    static func parallelTestingUnit(environment: [String: String] = ProcessInfo.processInfo.environment) -> ParallelTestingUnit {
        staticParallelTestingUnit ?? parallelTestingUnit(environment[parallelTestingUnitEnvironmentKey]) ?? .scenario
    }

    /// Whether scenarios run at the same time, read as CucumberSwift reads a feature flag: the static
    /// variable, then the environment variable `CUCUMBER_PARALLEL_TESTING`, then, the one addition, the
    /// compilation condition of the same name, which the generated code passes as `compiled`. Off by default,
    /// and always off with coverage on, because coverage counters can't tell scenarios that run at the
    /// same time apart.
    static func runsInParallel(compiled: Bool, environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard !isCoverage(environment: environment) else { return false }
        return staticParallelTesting ?? FeatureFlagValue.bool(environment[parallelTestingEnvironmentKey]) ?? compiled
    }

    /// ``Cucumber/coverage``.
    static var staticCoverage: Bool? {
        get { storage.flag("coverage") }
        set { storage.setFlag("coverage", newValue) }
    }

    /// ``Cucumber/coveragePath``.
    static var staticCoveragePath: String? {
        get { storage.coveragePath }
        set { storage.coveragePath = newValue }
    }

    /// Whether each scenario's code coverage is written to a file: the static variable, then
    /// `CUCUMBER_COVERAGE`, then no, as CucumberSwift's `FeatureFlags` read it.
    static func isCoverage(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        staticCoverage ?? FeatureFlagValue.bool(environment["CUCUMBER_COVERAGE"]) ?? false
    }

    /// Where the coverage files are written: the static variable, then `CUCUMBER_COVERAGE_PATH`. Nil when
    /// neither is set, or is empty, so they go to their default place.
    static func coveragePath(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let path = staticCoveragePath ?? environment["CUCUMBER_COVERAGE_PATH"]
        let trimmed = path?.trimmingCharacters(in: .whitespaces)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

extension Cucumber {
    /// Where the Cucumber JSON report is written, a full path to a file, such as
    /// `/Users/me/reports/cucumber.json`. Without it the report is `_cucumberReport.json` in the documents
    /// folder. Set this, or the environment variable `CUCUMBER_REPORT_PATH`, to write it somewhere else; the
    /// runner creates the folder. This variable, when set, wins over the environment variable. Set it in
    /// your `StepImplementation`'s `setupSteps()`. A reporter made with
    /// ``CucumberJSONReporter/init(reportPath:)`` keeps the path it was given.
    nonisolated public static var reportPath: String? {
        get { CucumberSettings.staticReportPath }
        set { CucumberSettings.staticReportPath = newValue }
    }

    /// Whether scenarios run at the same time. Off by default: one scenario at a time, in the order of the
    /// feature files. Set this to `true` in your `StepImplementation`'s `setupSteps()`, or set the
    /// environment variable `CUCUMBER_PARALLEL_TESTING` to `YES` (`TRUE` or `1` work too, in any case), or
    /// define a compilation condition of that name in the test target. This variable, when set, wins over
    /// the environment variable, which wins over the compilation condition. Swift Testing decides when it
    /// discovers the tests, so the runner runs `setupSteps()` then; if it can't, a note says that the
    /// scenarios run one at a time.
    nonisolated public static var parallelTesting: Bool? {
        get { CucumberSettings.staticParallelTesting }
        set { CucumberSettings.staticParallelTesting = newValue }
    }

    /// What runs together when ``parallelTesting`` is on: each scenario, the default, or each whole feature,
    /// whose scenarios then run one at a time, in the order of the feature file, while features run at the
    /// same time. Set this to ``ParallelTestingUnit/feature``, or the environment variable
    /// `CUCUMBER_PARALLEL_TESTING_UNIT` to `feature`, to run features at the same time and scenarios in
    /// order. This variable, when set, wins over the environment variable. Set it in your
    /// `StepImplementation`'s `setupSteps()`: Swift Testing reads it when it discovers the tests.
    nonisolated public static var parallelTestingUnit: ParallelTestingUnit? {
        get { CucumberSettings.staticParallelTestingUnit }
        set { CucumberSettings.staticParallelTestingUnit = newValue }
    }

    /// Whether the runner prints each feature, scenario and step, with its result and duration, as it
    /// runs. Off by default. The `CUCUMBER_VERBOSE` environment variable (`1` or `true`) and
    /// ``StepImplementation/verbose`` turn it on too.
    nonisolated public static var verboseOutput: Bool {
        get { CucumberSettings.staticVerboseOutput }
        set { CucumberSettings.staticVerboseOutput = newValue }
    }

    /// Whether the test for a step, and for an example of a Scenario Outline, is named with the Gherkin text as
    /// written, such as `3 › Then the total is 99`, rather than in camel case, such as
    /// `Step002_ThenTheTotalIs99`. On by default; set this to `false`, or the environment variable
    /// `CUCUMBER_READABLE_TEST_NAMES` to `NO`, for camel case. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`. Swift Testing needs the
    /// names of suites and tests as string literals when the tests build, so their display names, the
    /// feature's and the scenario's title, are always the Gherkin text.
    nonisolated public static var readableTestNames: Bool? {
        get { CucumberSettings.staticReadableTestNames }
        set { CucumberSettings.staticReadableTestNames = newValue }
    }

    /// Whether each scenario is one test, rather than a test for each of its steps, which is the default, as
    /// with CucumberSwift. Set this to `true`, or the environment variable `CUCUMBER_ONE_TEST_PER_SCENARIO` to
    /// `YES`, for one test per scenario. This variable, when set, wins over the environment variable. Set it
    /// in your `StepImplementation`'s `setupSteps()`.
    nonisolated public static var oneTestPerScenario: Bool? {
        get { CucumberSettings.staticOneTestPerScenario }
        set { CucumberSettings.staticOneTestPerScenario = newValue }
    }

    /// Whether the step definitions the runner suggests for undefined steps use regex literals, such as
    /// `Then(#/^I see (\d+) messages$/#)`, rather than Cucumber Expressions with typed parameters, such as
    /// `Then("I see {int} messages")`. Cucumber Expressions are the default, and work on every deployment
    /// target; regex literals need iOS 16, macOS 13 or tvOS 16. Set this to `true`, or the environment
    /// variable `CUCUMBER_GENERATE_REGEX_LITERALS` to `YES`, for regex literals, written as
    /// ``StepImplementation/regexLiteralStyle`` says. This variable, when set, wins over the environment
    /// variable. Set it in your `StepImplementation`'s `setupSteps()`.
    nonisolated public static var generateRegexLiterals: Bool? {
        get { CucumberSettings.staticGenerateRegexLiterals }
        set { CucumberSettings.staticGenerateRegexLiterals = newValue }
    }

    /// Whether the step definitions the runner suggests for undefined steps are step definition macros, such
    /// as `#Then("I see {int} messages") { (int: Int) in`, rather than functions, such as
    /// `Then("I see {int} messages") { match, _ in`. By default they are macros when the test target links
    /// the `CucumberSwiftTestingMacros` product with the `Macros` package trait on, and functions otherwise.
    /// Set this to `false`, or the environment variable `CUCUMBER_GENERATE_MACROS` to `NO`, for functions
    /// anyway, or to `true` or `YES` for macros. With ``generateRegexLiterals`` the macros take regex
    /// literals. This variable, when set, wins over the environment variable. Set it in your
    /// `StepImplementation`'s `setupSteps()`.
    nonisolated public static var generateMacros: Bool? {
        get { CucumberSettings.staticGenerateMacros }
        set { CucumberSettings.staticGenerateMacros = newValue }
    }

    /// Whether the runner writes each scenario's code coverage to a file, with a manifest of the scenarios
    /// that ran, for a coverage report. Off by default. Set this to `true`, or the environment variable
    /// `CUCUMBER_COVERAGE` to `YES`, to turn it on, and turn on code coverage for the test target. With
    /// coverage on, scenarios run one at a time even with ``parallelTesting``, because coverage counters
    /// can't tell scenarios that run at the same time apart. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`. See ``coveragePath`` for
    /// where the files go.
    nonisolated public static var coverage: Bool? {
        get { CucumberSettings.staticCoverage }
        set { CucumberSettings.staticCoverage = newValue }
    }

    /// The folder where ``coverage`` writes its files, a full path, such as `/Users/me/coverage`. Each run
    /// writes a folder of its own in it. Without it the files go to `_cucumberCoverage` in the documents
    /// folder. Set this, or the environment variable `CUCUMBER_COVERAGE_PATH`, to write them somewhere
    /// else. This variable, when set, wins over the environment variable. Set it in your
    /// `StepImplementation`'s `setupSteps()`.
    nonisolated public static var coveragePath: String? {
        get { CucumberSettings.staticCoveragePath }
        set { CucumberSettings.staticCoveragePath = newValue }
    }
}
