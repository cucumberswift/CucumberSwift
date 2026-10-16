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
        private var storedParallelTesting: Bool?
        private var storedIsSuiteSerialized = false

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
    }

    private static let storage = Storage()

    static let reportPathEnvironmentKey = "CUCUMBER_REPORT_PATH"
    static let parallelTestingEnvironmentKey = "CUCUMBER_PARALLEL_TESTING"

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

    /// Whether the generated suite was made serialized when Swift Testing discovered the tests, which is
    /// before `setupSteps()` runs. False until then, and for scenarios run without the generated suite.
    static var isSuiteSerialized: Bool {
        get { storage.isSuiteSerialized }
        set { storage.isSuiteSerialized = newValue }
    }

    static var reportPath: String? { reportPath() }

    /// Where the JSON report is written: the static variable, then `CUCUMBER_REPORT_PATH`. Nil when neither
    /// is set, or is empty, so the report goes to its default place.
    static func reportPath(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let path = staticReportPath ?? environment[reportPathEnvironmentKey]
        let trimmed = path?.trimmingCharacters(in: .whitespaces)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    /// `YES`, `TRUE` or `1`, and `NO`, `FALSE` or `0`, in any case, as CucumberSwift's feature flags read
    /// an environment variable. Any other value is not a setting.
    static func bool(_ value: String?) -> Bool? {
        switch value?.trimmingCharacters(in: .whitespaces).uppercased() {
            case "YES", "TRUE", "1": return true
            case "NO", "FALSE", "0": return false
            default: return nil
        }
    }

    /// Whether scenarios run at the same time. Swift Testing decides when it discovers the tests, before
    /// `setupSteps()` runs, so only what exists by then counts: the environment variable
    /// `CUCUMBER_PARALLEL_TESTING`, then the compilation condition of the same name, which the generated
    /// code passes as `compiled`. Off by default.
    static func runsInParallel(compiled: Bool, environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        bool(environment[parallelTestingEnvironmentKey]) ?? compiled
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
    /// feature files. Set the environment variable `CUCUMBER_PARALLEL_TESTING` to `YES` (`TRUE` or `1`
    /// work too, in any case), in your scheme or on the command line, or define the compilation condition
    /// `CUCUMBER_PARALLEL_TESTING` in the test target. Swift Testing decides this when it discovers the
    /// tests, before `setupSteps()` runs, so setting this variable there is too late: the runner then
    /// fails the first scenario with a message that says so, and the run stays serial.
    nonisolated public static var parallelTesting: Bool? {
        get { CucumberSettings.staticParallelTesting }
        set { CucumberSettings.staticParallelTesting = newValue }
    }

    /// Whether the runner prints each feature, scenario and step, with its result and duration, as it
    /// runs. Off by default. The `CUCUMBER_VERBOSE` environment variable (`1` or `true`) and
    /// ``StepImplementation/verbose`` turn it on too.
    nonisolated public static var verboseOutput: Bool {
        get { CucumberSettings.staticVerboseOutput }
        set { CucumberSettings.staticVerboseOutput = newValue }
    }
}
