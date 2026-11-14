//
//  CoverageFlags.swift
//  CucumberSwiftTesting
//
// The coverage scores' settings, over the storage that both runners share.

import Foundation

extension Cucumber {
    /// The coverage at or below which a feature gets a warning, in percent: 80 by default. A feature's
    /// coverage is measured by how much of the code under test that its scenarios executed, as a
    /// percentage of the code in the covered functions. Set this to a number, or to ``CoverageLevel/off``
    /// for no warning, or the environment variable `CUCUMBER_COVERAGE_WARNING_LEVEL` to a number or `NO`.
    /// This variable, when set, wins over the environment variable. Set it in your `StepImplementation`'s
    /// `setupSteps()`. See <doc:Measuring-Code-Coverage>.
    nonisolated public static var coverageWarningLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("warning") }
        set { CoverageSettings.storage.setLevel("warning", newValue) }
    }

    /// The coverage at or below which a feature gets an error, which is printed as an error and fails no test unless ``coverageRecordsIssuesInSuites`` is on, in percent: off
    /// by default, so that coverage only warns. Set this to a number, such as 50, or the environment
    /// variable `CUCUMBER_COVERAGE_ERROR_LEVEL` to a number or `NO`. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`.
    nonisolated public static var coverageErrorLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("error") }
        set { CoverageSettings.storage.setLevel("error", newValue) }
    }

    /// Whether each feature also gets a redundancy score, with ``coverage`` on: how much of the code its
    /// scenarios ran more than one of them ran. On by default, and with coverage off it has no effect. Set
    /// this to `false`, or the environment variable `CUCUMBER_REDUNDANCY` to `NO`, to score coverage only.
    /// This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`. See
    /// <doc:Measuring-Code-Coverage>.
    nonisolated public static var redundancy: Bool? {
        get { CoverageSettings.storage.redundancy }
        set { CoverageSettings.storage.redundancy = newValue }
    }

    /// The redundancy at or above which a feature gets a warning, in percent: 30 by default. A scenario
    /// that adds no coverage of its own gets a warning too, unless this is ``CoverageLevel/off``. Set this
    /// to a number, or to ``CoverageLevel/off``, or the environment variable
    /// `CUCUMBER_REDUNDANCY_WARNING_LEVEL` to a number or `NO`. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`.
    nonisolated public static var redundancyWarningLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("redundancyWarning") }
        set { CoverageSettings.storage.setLevel("redundancyWarning", newValue) }
    }

    /// The redundancy at or above which a feature gets an error, which is printed as an error and fails no test unless ``coverageRecordsIssuesInSuites`` is on, in percent:
    /// off by default. Set this to a number, or the environment variable `CUCUMBER_REDUNDANCY_ERROR_LEVEL`
    /// to a number or `NO`. This variable, when set, wins over the environment variable. Set it in your
    /// `StepImplementation`'s `setupSteps()`.
    nonisolated public static var redundancyErrorLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("redundancyError") }
        set { CoverageSettings.storage.setLevel("redundancyError", newValue) }
    }

    /// The share of the code a step outside the Background runs, at or above which the step gets a warning, in
    /// percent: 50 by default. A step is redundant when other scenarios run the same code in exactly the same
    /// way, such as a step that belongs in the Background. Set this to a number, or to ``CoverageLevel/off``,
    /// or the environment variable `CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL` to a number or `NO`. This
    /// variable, when set, wins over the environment variable. Set it in your `StepImplementation`'s
    /// `setupSteps()`. See <doc:Measuring-Code-Coverage>.
    nonisolated public static var redundantStepWarningLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("redundantStepWarning") }
        set { CoverageSettings.storage.setLevel("redundantStepWarning", newValue) }
    }

    /// The source files the scores measure, as parts of their paths, such as `["Sources/MyApp"]`. Without
    /// it they measure every file built with code coverage except your dependencies' and your tests'. Set
    /// this, or the environment variable `CUCUMBER_COVERAGE_SOURCES` to the parts separated by commas. This
    /// variable, when set, wins over the environment variable. Set it in your `StepImplementation`'s
    /// `setupSteps()`.
    nonisolated public static var coverageSources: [String]? {
        get { CoverageSettings.storage.sources }
        set { CoverageSettings.storage.sources = newValue }
    }

    /// Whether each feature gets a Mutation test: off by default. It needs coverage on, because it matches
    /// each mutant of the last `cucumberswift mutation-test` run to the scenarios that run its code. The
    /// test fails when any mutant in that code survived: a scenario passes with the code changed, so it
    /// doesn't check that code. Set this to `true`, or the environment variable `CUCUMBER_MUTATION_TESTING`
    /// to `YES`, and set ``mutationReport``. This variable, when set, wins over the environment variable.
    /// Set it in your `StepImplementation`'s `setupSteps()`.
    nonisolated public static var mutationTesting: Bool? {
        get { CoverageSettings.storage.mutationTesting }
        set { CoverageSettings.storage.mutationTesting = newValue }
    }

    /// The report of the `cucumberswift mutation-test` run that ``mutationTesting`` checks,
    /// `mutation-report.json`, as a full path. Set this, or the environment variable `CUCUMBER_MUTATION_REPORT`.
    /// This variable, when set, wins over the environment variable. Set it in your `StepImplementation`'s
    /// `setupSteps()`.
    nonisolated public static var mutationReport: String? {
        get { CoverageSettings.storage.mutationReport }
        set { CoverageSettings.storage.mutationReport = newValue }
    }

    /// Whether the Swift Testing runner records each feature's coverage and redundancy issues on the
    /// feature's suite, where an error fails the suite, instead of printing them: off by default. Set this
    /// to `true`, or the environment variable `CUCUMBER_COVERAGE_RECORDS_ISSUES_IN_SUITES` to `YES`. This
    /// variable, when set, wins over the environment variable. Set it in your `StepImplementation`'s
    /// `setupSteps()`. Xcode stops the test process when a suite records an issue, so use it with
    /// `swift test`, not in an Xcode project with Code Coverage on.
    nonisolated public static var coverageRecordsIssuesInSuites: Bool? {
        get { CoverageSettings.storage.recordsIssuesInSuites }
        set { CoverageSettings.storage.recordsIssuesInSuites = newValue }
    }
}
