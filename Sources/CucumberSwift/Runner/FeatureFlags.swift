//
//  FeatureFlags.swift
//  CucumberSwift
//

import Foundation

/// Reads CucumberSwift's feature flags. Each flag is a static variable on `Cucumber` and an environment
/// variable: the static variable wins, then the environment variable, then the flag's default.
enum FeatureFlags {
    /// The static variables' values. A computed static variable over locked storage is safe to read and
    /// set from any isolation, and doesn't warn in a consumer's Swift 6 target, as a stored one would.
    final class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var values = [String: Bool]()

        subscript(_ name: String) -> Bool? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return values[name]
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                values[name] = newValue
            }
        }
    }

    /// Whether generated tests are named with the Gherkin text as written. On by default.
    static var isReadableTestNames: Bool {
        value(Cucumber.readableTestNames, environmentVariable: "CUCUMBER_READABLE_TEST_NAMES", default: true)
    }

    /// Whether each scenario is one test rather than a test class with a test for each step. Off by default.
    static var isOneTestPerScenario: Bool {
        value(Cucumber.oneTestPerScenario, environmentVariable: "CUCUMBER_ONE_TEST_PER_SCENARIO", default: false)
    }

    /// Whether the step definitions generated for undefined steps use regex literals rather than
    /// Cucumber Expressions. Off by default.
    static var isGenerateRegexLiterals: Bool {
        value(Cucumber.generateRegexLiterals, environmentVariable: "CUCUMBER_GENERATE_REGEX_LITERALS", default: false)
    }

    /// Whether Xcode's parallel testing may run each scenario in a worker of its own. Off by default.
    static var isParallelTesting: Bool {
        value(Cucumber.parallelTesting, environmentVariable: "CUCUMBER_PARALLEL_TESTING", default: false)
    }

    static let storage = Storage()

    static func value(_ staticValue: Bool?, environmentVariable name: String, default defaultValue: Bool) -> Bool {
        staticValue ?? bool(Cucumber.shared.environment[name]) ?? defaultValue
    }

    /// `YES`, `TRUE` or `1`, and `NO`, `FALSE` or `0`, in any case. Any other value is not a setting.
    static func bool(_ value: String?) -> Bool? {
        switch value?.trimmingCharacters(in: .whitespaces).uppercased() {
            case "YES", "TRUE", "1": return true
            case "NO", "FALSE", "0": return false
            default: return nil
        }
    }
}

extension Cucumber {
    /// Whether generated tests are named with the feature, scenario and step text as written, such as
    /// `Checkout › Pay with a gift card` and `3 › Then the total is 99`, rather than in camel case,
    /// such as `Checkout|PayWithAGiftCard` and `Step002_ThenTheTotalIs99`. Readable names are the
    /// default; set this to `false`, or the environment variable `CUCUMBER_READABLE_TEST_NAMES` to `NO`,
    /// if a tool that parses `xcodebuild`'s output expects test names without spaces. This variable,
    /// when set, wins over the environment variable. Set it in your `StepImplementation`'s
    /// `setupSteps()`, before CucumberSwift creates the tests.
    public static var readableTestNames: Bool? {
        get { FeatureFlags.storage["readableTestNames"] }
        set { FeatureFlags.storage["readableTestNames"] = newValue }
    }

    /// Whether each scenario is one test, named after its feature and scenario, whose steps run in order
    /// within it, rather than a test class with a test for each step. Xcode's test navigator can then
    /// run a single scenario. A test for each step is the default; set this to `true`, or the environment
    /// variable `CUCUMBER_ONE_TEST_PER_SCENARIO` to `YES`, for one test per scenario. This variable, when
    /// set, wins over the environment variable. Set it in your `StepImplementation`'s `setupSteps()`,
    /// before CucumberSwift creates the tests.
    public static var oneTestPerScenario: Bool? {
        get { FeatureFlags.storage["oneTestPerScenario"] }
        set { FeatureFlags.storage["oneTestPerScenario"] = newValue }
    }

    /// Whether the step definitions CucumberSwift generates for undefined steps use regex literals, such
    /// as `Then(#/^I see (\d+) messages$/#)`, rather than Cucumber Expressions with typed parameters, such
    /// as `Then("I see {int} messages")`. Cucumber Expressions are the default, and work on every
    /// deployment target; regex literals need iOS 16, macOS 13 or tvOS 16. Set this to `true`, or the
    /// environment variable `CUCUMBER_GENERATE_REGEX_LITERALS` to `YES`, for regex literals, written as
    /// ``StepImplementation/regexLiteralStyle`` says. This variable, when set, wins over the environment
    /// variable. Set it in your `StepImplementation`'s `setupSteps()`, before CucumberSwift runs the tests.
    public static var generateRegexLiterals: Bool? {
        get { FeatureFlags.storage["generateRegexLiterals"] }
        set { FeatureFlags.storage["generateRegexLiterals"] = newValue }
    }

    /// Experimental: whether Xcode's parallel testing ("Execute in parallel") may spread the scenarios
    /// across its parallel workers, each scenario running whole in one of them. Off by default, and with
    /// it off CucumberSwift's scenarios don't run correctly in parallel. Set this to `true`, or the
    /// environment variable `CUCUMBER_PARALLEL_TESTING` to `YES`, to try it. This variable,
    /// when set, wins over the environment variable. Set it in your `StepImplementation`'s `setupSteps()`.
    ///
    /// It applies to a test per step, the default, not to ``oneTestPerScenario``. Each worker is a process
    /// of its own, so state your step definitions share, a feature's hooks and the JSON report are per
    /// worker: see <doc:Running-Scenarios-In-Parallel> before you turn it on.
    public static var parallelTesting: Bool? {
        get { FeatureFlags.storage["parallelTesting"] }
        set { FeatureFlags.storage["parallelTesting"] = newValue }
    }
}
