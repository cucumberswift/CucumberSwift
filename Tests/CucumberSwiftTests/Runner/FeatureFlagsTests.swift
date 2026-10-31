//
//  FeatureFlagsTests.swift
//  CucumberSwiftTests
//
//  Each feature flag is a static variable on Cucumber and an environment variable. The static
//  variable wins, then the environment variable, then the flag's default (#59).
//

import Foundation
import XCTest
@testable import CucumberSwift

class FeatureFlagsTests: XCTestCase {
    private static let variables = [
        "CUCUMBER_READABLE_TEST_NAMES",
        "CUCUMBER_ONE_TEST_PER_SCENARIO",
        "CUCUMBER_GENERATE_REGEX_LITERALS",
        "CUCUMBER_GENERATE_MACROS",
        "CUCUMBER_PARALLEL_TESTING",
        "CUCUMBER_PARALLEL_TESTING_UNIT",
        "CUCUMBER_REPORT_PATH",
        "CUCUMBER_COVERAGE",
        "CUCUMBER_COVERAGE_PATH"
    ]

    private static func resetFlags() {
        Cucumber.readableTestNames = nil
        Cucumber.oneTestPerScenario = nil
        Cucumber.generateRegexLiterals = nil
        Cucumber.generateMacros = nil
        Cucumber.parallelTesting = nil
        Cucumber.parallelTestingUnit = nil
        Cucumber.reportPath = nil
        Cucumber.coverage = nil
        Cucumber.coveragePath = nil
        variables.forEach { Cucumber.shared.environment[$0] = nil }
    }

    override func setUpWithError() throws {
        Self.resetFlags()
        addTeardownBlock { Self.resetFlags() }
    }

    func testReadableTestNamesAreOnByDefault() {
        XCTAssertTrue(FeatureFlags.isReadableTestNames)
    }

    func testOneTestPerScenarioIsOffByDefault() {
        XCTAssertFalse(FeatureFlags.isOneTestPerScenario)
    }

    func testRegexLiteralStepDefinitionsAreOffByDefault() {
        XCTAssertFalse(FeatureFlags.isGenerateRegexLiterals)
    }

    // This bundle doesn't link CucumberSwiftMacros. The StepDefinitionMacrosPackage fixture, which does,
    // checks that macros are then the default.
    func testMacroStepDefinitionsAreOffByDefaultWithoutTheMacrosLinked() {
        XCTAssertFalse(FeatureFlags.linksMacros)
        XCTAssertFalse(FeatureFlags.isGenerateMacros)
    }

    func testReportPathIsUnsetByDefault() {
        XCTAssertNil(FeatureFlags.reportPath)
    }

    func testReportPathComesFromTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_REPORT_PATH"] = "reports/from-environment.json"
        XCTAssertEqual(FeatureFlags.reportPath, "reports/from-environment.json")
    }

    func testReportPathStaticVariableWinsOverTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_REPORT_PATH"] = "reports/from-environment.json"
        Cucumber.reportPath = "reports/from-code.json"
        XCTAssertEqual(FeatureFlags.reportPath, "reports/from-code.json")
        Cucumber.reportPath = nil
        XCTAssertEqual(FeatureFlags.reportPath, "reports/from-environment.json")
    }

    func testEmptyReportPathIsIgnored() {
        Cucumber.shared.environment["CUCUMBER_REPORT_PATH"] = "  "
        XCTAssertNil(FeatureFlags.reportPath)
    }

    func testCoverageIsAutoByDefaultOnWhenTheTestsAreBuiltWithCoverage() {
        XCTAssertNil(FeatureFlags.coverageSetting)
        XCTAssertEqual(FeatureFlags.isCoverage, ProfileCounters.isInstrumented)
    }

    func testCoverageComesFromTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_COVERAGE"] = "yes"
        XCTAssertTrue(FeatureFlags.isCoverage)
        Cucumber.shared.environment["CUCUMBER_COVERAGE"] = "no"
        XCTAssertFalse(FeatureFlags.isCoverage)
        // Anything else, such as AUTO, is auto.
        Cucumber.shared.environment["CUCUMBER_COVERAGE"] = "AUTO"
        XCTAssertNil(FeatureFlags.coverageSetting)
    }

    func testCoverageStaticVariableWinsOverTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_COVERAGE"] = "YES"
        Cucumber.coverage = false
        XCTAssertFalse(FeatureFlags.isCoverage)
    }

    func testCoveragePathComesFromTheStaticVariableThenTheEnvironmentVariable() {
        let fromEnvironment = FileManager.default.temporaryDirectory.appendingPathComponent("from-environment").path
        let fromCode = FileManager.default.temporaryDirectory.appendingPathComponent("from-code").path
        XCTAssertNil(FeatureFlags.coveragePath)
        Cucumber.shared.environment["CUCUMBER_COVERAGE_PATH"] = " \(fromEnvironment) "
        XCTAssertEqual(FeatureFlags.coveragePath, fromEnvironment)
        Cucumber.coveragePath = fromCode
        XCTAssertEqual(FeatureFlags.coveragePath, fromCode)
        Cucumber.coveragePath = " "
        XCTAssertNil(FeatureFlags.coveragePath)
    }

    func testParallelTestingIsOffByDefault() {
        XCTAssertFalse(FeatureFlags.isParallelTesting)
    }

    func testTheEnvironmentVariableOverridesTheDefault() {
        Cucumber.shared.environment["CUCUMBER_READABLE_TEST_NAMES"] = "NO"
        Cucumber.shared.environment["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "YES"
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "YES"
        Cucumber.shared.environment["CUCUMBER_GENERATE_MACROS"] = "YES"
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING"] = "YES"

        XCTAssertFalse(FeatureFlags.isReadableTestNames)
        XCTAssertTrue(FeatureFlags.isOneTestPerScenario)
        XCTAssertTrue(FeatureFlags.isGenerateRegexLiterals)
        XCTAssertTrue(FeatureFlags.isGenerateMacros)
        XCTAssertTrue(FeatureFlags.isParallelTesting)
    }

    func testTheStaticVariableOverridesTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_READABLE_TEST_NAMES"] = "NO"
        Cucumber.shared.environment["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "YES"
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "YES"
        Cucumber.readableTestNames = true
        Cucumber.oneTestPerScenario = false
        Cucumber.generateRegexLiterals = false
        Cucumber.shared.environment["CUCUMBER_GENERATE_MACROS"] = "YES"
        Cucumber.generateMacros = false
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING"] = "YES"
        Cucumber.parallelTesting = false

        XCTAssertTrue(FeatureFlags.isReadableTestNames)
        XCTAssertFalse(FeatureFlags.isOneTestPerScenario)
        XCTAssertFalse(FeatureFlags.isGenerateRegexLiterals)
        XCTAssertFalse(FeatureFlags.isGenerateMacros)
        XCTAssertFalse(FeatureFlags.isParallelTesting)
    }

    func testAnUnknownEnvironmentValueLeavesTheDefault() {
        Cucumber.shared.environment["CUCUMBER_READABLE_TEST_NAMES"] = "maybe"
        Cucumber.shared.environment["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "maybe"
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "maybe"
        Cucumber.shared.environment["CUCUMBER_GENERATE_MACROS"] = "maybe"

        XCTAssertTrue(FeatureFlags.isReadableTestNames)
        XCTAssertFalse(FeatureFlags.isOneTestPerScenario)
        XCTAssertFalse(FeatureFlags.isGenerateRegexLiterals)
        XCTAssertFalse(FeatureFlags.isGenerateMacros)
    }

    func testBooleanValuesInAnyCase() {
        ["YES", "yes", "True", "1", " 1 "].forEach { XCTAssertEqual(FeatureFlags.bool($0), true, $0) }
        ["NO", "no", "False", "0"].forEach { XCTAssertEqual(FeatureFlags.bool($0), false, $0) }
        ["", "maybe", "2"].forEach { XCTAssertNil(FeatureFlags.bool($0), $0) }
        XCTAssertNil(FeatureFlags.bool(nil))
    }

    func testTheParallelTestingUnitIsAScenarioByDefault() {
        XCTAssertEqual(FeatureFlags.parallelTestingUnit, .scenario)
    }

    func testTheParallelTestingUnitEnvironmentVariableOverridesTheDefault() {
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING_UNIT"] = "feature"

        XCTAssertEqual(FeatureFlags.parallelTestingUnit, .feature)
    }

    func testTheParallelTestingUnitStaticVariableOverridesTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING_UNIT"] = "feature"
        Cucumber.parallelTestingUnit = .scenario

        XCTAssertEqual(FeatureFlags.parallelTestingUnit, .scenario)
    }

    func testAnUnknownParallelTestingUnitLeavesTheDefault() {
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING_UNIT"] = "step"

        XCTAssertEqual(FeatureFlags.parallelTestingUnit, .scenario)
    }

    func testParallelTestingUnitsInAnyCase() {
        ["feature", "FEATURE", "Feature", " feature\t"].forEach { XCTAssertEqual(FeatureFlags.parallelTestingUnit($0), .feature, $0) }
        ["scenario", "Scenario", " SCENARIO "].forEach { XCTAssertEqual(FeatureFlags.parallelTestingUnit($0), .scenario, $0) }
        ["", "features", "step", "YES"].forEach { XCTAssertNil(FeatureFlags.parallelTestingUnit($0), $0) }
        XCTAssertNil(FeatureFlags.parallelTestingUnit(nil))
    }
}
