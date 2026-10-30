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
        Cucumber.coverageSources = nil
        super.tearDown()
    }

    func testTheDefaults() {
        let settings = CoverageSettings.read(environment: [:])
        XCTAssertEqual(settings, CoverageSettings())
        XCTAssertEqual(settings.warningLevel, 80)
        XCTAssertEqual(settings.errorLevel, 50)
        XCTAssertFalse(settings.isRedundancy)
        XCTAssertEqual(settings.redundancyWarningLevel, 30)
        XCTAssertEqual(settings.redundancyErrorLevel, .off)
        XCTAssertEqual(settings.sources, [])
    }

    func testTheEnvironmentVariables() {
        let settings = CoverageSettings.read(environment: [
            "CUCUMBER_COVERAGE_WARNING_LEVEL": "70",
            "CUCUMBER_COVERAGE_ERROR_LEVEL": "NO",
            "CUCUMBER_REDUNDANCY": "YES",
            "CUCUMBER_REDUNDANCY_WARNING_LEVEL": "20",
            "CUCUMBER_REDUNDANCY_ERROR_LEVEL": "60",
            "CUCUMBER_COVERAGE_SOURCES": "Sources/App, Sources/Model ,"
        ])
        XCTAssertEqual(settings.warningLevel, 70)
        XCTAssertEqual(settings.errorLevel, .off)
        XCTAssertTrue(settings.isRedundancy)
        XCTAssertEqual(settings.redundancyWarningLevel, 20)
        XCTAssertEqual(settings.redundancyErrorLevel, 60)
        XCTAssertEqual(settings.sources, ["Sources/App", "Sources/Model"])
    }

    func testTheStaticVariablesWinOverTheEnvironmentVariables() {
        Cucumber.coverageWarningLevel = .off
        Cucumber.coverageErrorLevel = 40
        Cucumber.redundancy = false
        Cucumber.redundancyWarningLevel = 10
        Cucumber.redundancyErrorLevel = .off
        Cucumber.coverageSources = ["Sources/Core"]
        let settings = CoverageSettings.read(environment: [
            "CUCUMBER_COVERAGE_WARNING_LEVEL": "70",
            "CUCUMBER_COVERAGE_ERROR_LEVEL": "60",
            "CUCUMBER_REDUNDANCY": "YES",
            "CUCUMBER_REDUNDANCY_WARNING_LEVEL": "20",
            "CUCUMBER_REDUNDANCY_ERROR_LEVEL": "60",
            "CUCUMBER_COVERAGE_SOURCES": "Sources/App"
        ])
        XCTAssertEqual(settings.warningLevel, .off)
        XCTAssertEqual(settings.errorLevel, 40)
        XCTAssertFalse(settings.isRedundancy)
        XCTAssertEqual(settings.redundancyWarningLevel, 10)
        XCTAssertEqual(settings.redundancyErrorLevel, .off)
        XCTAssertEqual(settings.sources, ["Sources/Core"])
    }
}
