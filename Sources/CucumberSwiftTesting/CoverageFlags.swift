//
//  CoverageFlags.swift
//  CucumberSwiftTesting
//
// The coverage scores' settings, over the storage that both runners share.

import Foundation

extension Cucumber {
    /// The coverage at or below which a feature gets a warning, in percent: 80 by default. A feature's
    /// coverage is the code its scenarios ran, of the code in the functions they entered. Set this to a
    /// number, or to ``CoverageLevel/off`` for no warning, or the environment variable
    /// `CUCUMBER_COVERAGE_WARNING_LEVEL` to a number or `NO`. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`. See
    /// <doc:Measuring-Code-Coverage>.
    nonisolated public static var coverageWarningLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("warning") }
        set { CoverageSettings.storage.setLevel("warning", newValue) }
    }

    /// The coverage at or below which a feature gets an error, which fails its suite, in percent: 50
    /// by default. Set this to a number, or to ``CoverageLevel/off`` for no error, or the environment
    /// variable `CUCUMBER_COVERAGE_ERROR_LEVEL` to a number or `NO`. This variable, when set, wins over the
    /// environment variable. Set it in your `StepImplementation`'s `setupSteps()`.
    nonisolated public static var coverageErrorLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("error") }
        set { CoverageSettings.storage.setLevel("error", newValue) }
    }

    /// Whether each feature also gets a redundancy score, with ``coverage`` on: how much of the code its
    /// scenarios ran more than one of them ran. Off by default. Set this to `true`, or the environment
    /// variable `CUCUMBER_REDUNDANCY` to `YES`, to turn it on. This variable, when set, wins over the
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

    /// The redundancy at or above which a feature gets an error, which fails its suite, in percent:
    /// off by default. Set this to a number, or the environment variable `CUCUMBER_REDUNDANCY_ERROR_LEVEL`
    /// to a number or `NO`. This variable, when set, wins over the environment variable. Set it in your
    /// `StepImplementation`'s `setupSteps()`.
    nonisolated public static var redundancyErrorLevel: CoverageLevel? {
        get { CoverageSettings.storage.level("redundancyError") }
        set { CoverageSettings.storage.setLevel("redundancyError", newValue) }
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
}
