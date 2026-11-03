//
//  CoverageFlagsTests.swift
//  CucumberSwiftTests
//
//  The coverage scores' levels and settings are read as CucumberSwift reads a feature flag: the
//  static variable, then the environment variable, then the default (#502).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageFlagsTests: XCTestCase {
    override func tearDown() {
        Cucumber.coverageWarningLevel = nil
        Cucumber.coverageErrorLevel = nil
        Cucumber.redundancy = nil
        Cucumber.redundancyWarningLevel = nil
        Cucumber.redundancyErrorLevel = nil
        Cucumber.redundantStepWarningLevel = nil
        Cucumber.coverageSources = nil
        super.tearDown()
    }

    func testTheDefaults() {
        let settings = CoverageSettings.read(environment: [:])
        XCTAssertEqual(settings, CoverageSettings())
        XCTAssertEqual(settings.warningLevel, 80)
        // Off, so that coverage only warns until a project sets a level (#507).
        XCTAssertEqual(settings.errorLevel, .off)
        XCTAssertTrue(settings.isRedundancy)
        XCTAssertEqual(settings.redundancyWarningLevel, 30)
        XCTAssertEqual(settings.redundancyErrorLevel, .off)
        XCTAssertEqual(settings.redundantStepWarningLevel, 50)
        XCTAssertEqual(settings.sources, [])
    }

    func testTheEnvironmentVariables() {
        let settings = CoverageSettings.read(environment: [
            "CUCUMBER_COVERAGE_WARNING_LEVEL": "70",
            "CUCUMBER_COVERAGE_ERROR_LEVEL": "NO",
            "CUCUMBER_REDUNDANCY": "NO",
            "CUCUMBER_REDUNDANCY_WARNING_LEVEL": "20",
            "CUCUMBER_REDUNDANCY_ERROR_LEVEL": "60",
            "CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL": "40",
            "CUCUMBER_COVERAGE_SOURCES": "Sources/App, Sources/Model ,"
        ])
        XCTAssertEqual(settings.warningLevel, 70)
        XCTAssertEqual(settings.errorLevel, .off)
        XCTAssertFalse(settings.isRedundancy)
        XCTAssertEqual(settings.redundancyWarningLevel, 20)
        XCTAssertEqual(settings.redundancyErrorLevel, 60)
        XCTAssertEqual(settings.redundantStepWarningLevel, 40)
        XCTAssertEqual(settings.sources, ["Sources/App", "Sources/Model"])
    }

    func testTheStaticVariablesWinOverTheEnvironmentVariables() {
        Cucumber.coverageWarningLevel = .off
        Cucumber.coverageErrorLevel = 40
        Cucumber.redundancy = false
        Cucumber.redundancyWarningLevel = 10
        Cucumber.redundancyErrorLevel = .off
        Cucumber.redundantStepWarningLevel = .off
        Cucumber.coverageSources = ["Sources/Core"]
        let settings = CoverageSettings.read(environment: [
            "CUCUMBER_COVERAGE_WARNING_LEVEL": "70",
            "CUCUMBER_COVERAGE_ERROR_LEVEL": "60",
            "CUCUMBER_REDUNDANCY": "YES",
            "CUCUMBER_REDUNDANCY_WARNING_LEVEL": "20",
            "CUCUMBER_REDUNDANCY_ERROR_LEVEL": "60",
            "CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL": "40",
            "CUCUMBER_COVERAGE_SOURCES": "Sources/App"
        ])
        XCTAssertEqual(Cucumber.coverageWarningLevel, .off)
        XCTAssertEqual(Cucumber.coverageErrorLevel, 40)
        XCTAssertEqual(Cucumber.redundancy, false)
        XCTAssertEqual(Cucumber.redundancyWarningLevel, 10)
        XCTAssertEqual(Cucumber.redundancyErrorLevel, .off)
        XCTAssertEqual(Cucumber.redundantStepWarningLevel, .off)
        XCTAssertEqual(Cucumber.coverageSources, ["Sources/Core"])
        XCTAssertEqual(settings.warningLevel, .off)
        XCTAssertEqual(settings.errorLevel, 40)
        XCTAssertFalse(settings.isRedundancy)
        XCTAssertEqual(settings.redundancyWarningLevel, 10)
        XCTAssertEqual(settings.redundancyErrorLevel, .off)
        XCTAssertEqual(settings.redundantStepWarningLevel, .off)
        XCTAssertEqual(settings.sources, ["Sources/Core"])
    }

    // The Swift Testing runner reads this setting; the shared settings read it in both modules (#509).
    func testRecordingIssuesInSuitesIsOffUnlessAVariableTurnsItOn() {
        let variable = "CUCUMBER_COVERAGE_RECORDS_ISSUES_IN_SUITES"
        defer { CoverageSettings.storage.recordsIssuesInSuites = nil }
        XCTAssertFalse(CoverageSettings.read(environment: [:]).recordsIssuesInSuites)
        XCTAssertTrue(CoverageSettings.read(environment: [variable: "YES"]).recordsIssuesInSuites)
        CoverageSettings.storage.recordsIssuesInSuites = false
        XCTAssertFalse(CoverageSettings.read(environment: [variable: "YES"]).recordsIssuesInSuites)
        CoverageSettings.storage.recordsIssuesInSuites = true
        XCTAssertTrue(CoverageSettings.read(environment: [:]).recordsIssuesInSuites)
    }
}
