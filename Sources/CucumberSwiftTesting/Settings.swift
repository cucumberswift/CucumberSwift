//
//  Settings.swift
//  CucumberSwiftTesting
//
// The settings the runner reads besides CUCUMBER_TAGS, named as in CucumberSwift.

import Foundation

/// The static variables' values. Computed static variables over locked storage are safe to read and set
/// from any isolation, and don't warn in a consumer's Swift 6 target, as stored ones on a main-actor
/// class would.
enum CucumberSettings {
    private final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var storedReportPath: String?
        private var storedVerboseOutput = false
        private var storedGenerateRegexLiterals: Bool?
        private var flags = [String: Bool]()

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

    /// ``Cucumber/reportPath``.
    static var staticReportPath: String? {
        get { storage.reportPath }
        set { storage.reportPath = newValue }
    }

    static var staticVerboseOutput: Bool {
        get { storage.verboseOutput }
        set { storage.verboseOutput = newValue }
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

    /// Whether the step definitions the runner suggests use regex literals: the static variable, then
    /// `CUCUMBER_GENERATE_REGEX_LITERALS`, then no. The value is read as CucumberSwift's `FeatureFlags` read it: see `FeatureFlagValue`.
    static func generatesRegexLiterals(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        staticGenerateRegexLiterals ?? FeatureFlagValue.bool(environment[generateRegexLiteralsEnvironmentKey]) ?? false
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
}
