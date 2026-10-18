//
//  FeatureFlags.swift
//  CucumberSwift
//

import Foundation

/// What Xcode's parallel testing hands to a worker, with ``Cucumber/parallelTesting`` on. See
/// ``Cucumber/parallelTestingUnit``.
public enum ParallelTestingUnit: String, Sendable {
    /// Each scenario is a test class of its own, which Xcode hands to any worker. The default.
    case scenario
    /// Each feature is a test class of its own, and all of its scenarios run in one worker.
    case feature
}

/// Reads CucumberSwift's feature flags. Each flag is a static variable on `Cucumber` and an environment
/// variable: the static variable wins, then the environment variable, then the flag's default.
enum FeatureFlags {
    /// The static variables' values. A computed static variable over locked storage is safe to read and
    /// set from any isolation, and doesn't warn in a consumer's Swift 6 target, as a stored one would.
    final class Storage<Value>: @unchecked Sendable {
        private let lock = NSLock()
        private var values = [String: Value]()

        subscript(_ name: String) -> Value? {
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

    /// Whether the step definitions generated for undefined steps are step definition macros rather than
    /// step definition functions. By default, whether the test target links the macros.
    static var isGenerateMacros: Bool {
        value(Cucumber.generateMacros, environmentVariable: "CUCUMBER_GENERATE_MACROS", default: linksMacros)
    }

    /// Whether the test target links `CucumberSwiftMacros` built with the `Macros` trait, which declares
    /// this class.
    static var linksMacros: Bool {
        NSClassFromString("CucumberSwiftMacrosMarker") != nil
    }

    /// Whether Xcode's parallel testing may run each scenario in a worker of its own. Off by default.
    static var isParallelTesting: Bool {
        value(Cucumber.parallelTesting, environmentVariable: "CUCUMBER_PARALLEL_TESTING", default: false)
    }

    /// What Xcode's parallel testing hands to a worker: a scenario, the default, or a whole feature.
    static var parallelTestingUnit: ParallelTestingUnit {
        Cucumber.parallelTestingUnit
            ?? parallelTestingUnit(Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING_UNIT"])
            ?? .scenario
    }

    /// Where the JSON report is written: the static variable, then `CUCUMBER_REPORT_PATH`. Nil when neither
    /// is set, or is empty, so the report goes to its default place.
    static var reportPath: String? {
        let path = Cucumber.reportPath ?? Cucumber.shared.environment["CUCUMBER_REPORT_PATH"]
        let trimmed = path?.trimmingCharacters(in: .whitespaces)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    static let storage = Storage<Bool>()
    static let stringStorage = Storage<String>()
    static let parallelTestingUnitStorage = Locked<ParallelTestingUnit?>(nil)

    /// `scenario` or `feature`, in any case. Any other value is not a setting.
    static func parallelTestingUnit(_ value: String?) -> ParallelTestingUnit? {
        value.flatMap { ParallelTestingUnit(rawValue: $0.trimmingCharacters(in: .whitespaces).lowercased()) }
    }

    static func value(_ staticValue: Bool?, environmentVariable name: String, default defaultValue: Bool) -> Bool {
        staticValue ?? bool(Cucumber.shared.environment[name]) ?? defaultValue
    }

    /// `YES`, `TRUE` or `1`, and `NO`, `FALSE` or `0`, in any case. Any other value is not a setting.
    static func bool(_ value: String?) -> Bool? {
        FeatureFlagValue.bool(value)
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

    /// Whether the step definitions CucumberSwift generates for undefined steps are step definition macros,
    /// such as `#Then("I see {int} messages") { (int: Int) in`, rather than functions, such as
    /// `Then("I see {int} messages") { match, _ in`. By default they are macros when the test target links
    /// the `CucumberSwiftMacros` product with the `Macros` package trait on (see
    /// <doc:Using-Step-Definition-Macros>), and functions otherwise. Set this to `false`, or the environment
    /// variable `CUCUMBER_GENERATE_MACROS` to `NO`, for functions anyway, or to `true` or `YES` for macros.
    /// With ``generateRegexLiterals`` the macros take regex literals. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`, before CucumberSwift runs
    /// the tests.
    public static var generateMacros: Bool? {
        get { FeatureFlags.storage["generateMacros"] }
        set { FeatureFlags.storage["generateMacros"] = newValue }
    }

    /// Experimental: whether Xcode's parallel testing ("Execute in parallel") may spread the scenarios
    /// across its parallel workers, each scenario running whole in one of them. Off by default, and with
    /// it off CucumberSwift's scenarios don't run correctly in parallel. Set this to `true`, or the
    /// environment variable `CUCUMBER_PARALLEL_TESTING` to `YES`, to try it. This variable,
    /// when set, wins over the environment variable. Set it in your `StepImplementation`'s `setupSteps()`.
    ///
    /// It applies with a test per step, the default, and with ``oneTestPerScenario``: each scenario is a
    /// test class of its own, or each feature is, with ``parallelTestingUnit``. A scenario's or feature's
    /// class name starts with its position in your feature files, such as
    /// `F01 S02 › Checkout › Pay with a gift card`, so that a serial run keeps the order of the files.
    /// Each worker is a process of its own, so state your step definitions share and a feature's hooks are
    /// per worker, and on a Simulator the JSON report needs ``reportPath``: see
    /// <doc:Running-Scenarios-In-Parallel> before you turn it on.
    public static var parallelTesting: Bool? {
        get { FeatureFlags.storage["parallelTesting"] }
        set { FeatureFlags.storage["parallelTesting"] = newValue }
    }

    /// What Xcode's parallel testing hands to a worker when ``parallelTesting`` is on: each scenario, the
    /// default, or each whole feature, whose scenarios then all run in one worker, in the feature file's
    /// order, so that `BeforeFeature` and `AfterFeature` each run once. Set this to
    /// ``ParallelTestingUnit/feature``, or the environment variable `CUCUMBER_PARALLEL_TESTING_UNIT` to
    /// `feature`, to hand out whole features. This variable, when set, wins over the environment variable.
    /// Set it in your `StepImplementation`'s `setupSteps()`. See <doc:Running-Scenarios-In-Parallel>.
    public static var parallelTestingUnit: ParallelTestingUnit? {
        get { FeatureFlags.parallelTestingUnitStorage.snapshot }
        set { FeatureFlags.parallelTestingUnitStorage.withLock { $0 = newValue } }
    }

    /// Where the Cucumber JSON report is written, a full path to a file, such as `/Users/me/reports/cucumber.json`.
    /// Without it the report is `_cucumberReport.json` in the documents
    /// folder, which on a Simulator is inside the Simulator. Set this, or the environment variable
    /// `CUCUMBER_REPORT_PATH`, to a path every worker of a parallel run can reach, such as one under
    /// the Mac's home folder, which a Simulator reads as `SIMULATOR_HOST_HOME`, and the workers write one
    /// report between them. This variable, when set, wins over the environment variable. Set it in your
    /// `StepImplementation`'s `setupSteps()`. A reporter made with ``CucumberJSONReporter/init(reportPath:)``
    /// keeps the path it was given.
    public static var reportPath: String? {
        get { FeatureFlags.stringStorage["reportPath"] }
        set { FeatureFlags.stringStorage["reportPath"] = newValue }
    }
}
