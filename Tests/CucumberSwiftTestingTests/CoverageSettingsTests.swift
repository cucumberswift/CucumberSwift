//
//  CoverageSettingsTests.swift
//  CucumberSwiftTestingTests
//
//  Coverage is read as CucumberSwift reads it, and turns parallel scenarios off, because coverage counters
//  can't tell scenarios that run at the same time apart (#502).
//

import Foundation
import Testing
@testable import CucumberSwiftTesting

@Suite(.serialized) struct CoverageSettingsTests {
    @Test func coverageIsReadAsCucumberSwiftReadsAFeatureFlag() {
        defer { Cucumber.coverage = nil }
        let key = "CUCUMBER_COVERAGE"
        #expect(CucumberSettings.isCoverage(environment: [key: "yes"]))
        #expect(!CucumberSettings.isCoverage(environment: [key: "no"]))
        Cucumber.coverage = false
        #expect(!CucumberSettings.isCoverage(environment: [key: "YES"]))
    }

    // The static variable is passed in, because other suites set `Cucumber.parallelTesting` while this one runs.
    @Test func autoCoverageMeasuresABuildWithCoverageUnlessParallelTestingIsOn() {
        #expect(CucumberSettings.coverageSetting(environment: [:]) == nil)
        #expect(CucumberSettings.coverageSetting(environment: ["CUCUMBER_COVERAGE": "AUTO"]) == nil)
        #expect(!CucumberSettings.isCoverage(environment: ["CUCUMBER_PARALLEL_TESTING": "NO"], isInstrumented: false, staticParallelSetting: nil))
        #expect(CucumberSettings.isCoverage(environment: ["CUCUMBER_PARALLEL_TESTING": "NO"], isInstrumented: true, staticParallelSetting: nil))
        var said = [String]()
        #expect(!CucumberSettings.isCoverage(environment: ["CUCUMBER_PARALLEL_TESTING": "YES"], isInstrumented: true, staticParallelSetting: nil) { said.append($0) })
        #expect(!CucumberSettings.isCoverage(environment: ["CUCUMBER_PARALLEL_TESTING": "YES"], isInstrumented: true, staticParallelSetting: nil) { said.append($0) })
        // One line a run, which an earlier test may have printed already.
        #expect(said.count <= 1)
        // With auto coverage, parallel testing wins.
        let environment = ["CUCUMBER_PARALLEL_TESTING": "YES"]
        #expect(CucumberSettings.isParallelTestingRequested(compiled: false, environment: environment, staticSetting: nil))
    }

    @Test func aDSLFeaturesBackgroundStepsAreCountedAsTheScenariosBackground() {
        let file = "\(#filePath)"
        let gherkin = GherkinScenario(featureTitle: "F", featureTags: [], title: "S", tags: [], file: file, line: 3, column: 1, steps: [])
        let scenario = Scenario(gherkin)
        let step = DSLStep(keyword: .given, text: "a calculator", line: 2, column: 1, file: file) {}
        scenario.prependDSLSteps([step, step])
        #expect(scenario.backgroundStepCount == 2)
        #expect(scenario.steps.count == 2)
    }

    @Test func theCoveragePathComesFromTheStaticVariableThenTheEnvironmentVariable() {
        defer { Cucumber.coveragePath = nil }
        let key = "CUCUMBER_COVERAGE_PATH"
        let fromEnvironment = FileManager.default.temporaryDirectory.appendingPathComponent("env").path
        let fromCode = FileManager.default.temporaryDirectory.appendingPathComponent("code").path
        #expect(CucumberSettings.coveragePath(environment: [:]) == nil)
        #expect(CucumberSettings.coveragePath(environment: [key: " \(fromEnvironment) "]) == fromEnvironment)
        Cucumber.coveragePath = fromCode
        #expect(CucumberSettings.coveragePath(environment: [key: fromEnvironment]) == fromCode)
        Cucumber.coveragePath = " "
        #expect(CucumberSettings.coveragePath(environment: [key: fromEnvironment]) == nil)
    }

    // The static variable is passed in, because other suites set `Cucumber.parallelTesting` while this one runs.
    @Test func coverageRunsScenariosOneAtATimeEvenWithParallelTesting() {
        let environment = ["CUCUMBER_COVERAGE": "YES", "CUCUMBER_PARALLEL_TESTING": "YES"]
        #expect(!CucumberSettings.runsInParallel(compiled: true, environment: environment))
        #expect(CucumberSettings.runsInParallel(compiled: true, environment: ["CUCUMBER_PARALLEL_TESTING": "YES"]))
    }

    @Test func theScoresSettingsComeFromTheStaticVariablesThenTheEnvironmentVariables() {
        defer {
            Cucumber.coverageWarningLevel = nil
            Cucumber.coverageErrorLevel = nil
            Cucumber.redundancy = nil
            Cucumber.redundancyWarningLevel = nil
            Cucumber.redundancyErrorLevel = nil
            Cucumber.redundantStepWarningLevel = nil
            Cucumber.coverageSources = nil
        }
        let environment = [
            "CUCUMBER_COVERAGE_WARNING_LEVEL": "70",
            "CUCUMBER_COVERAGE_ERROR_LEVEL": "NO",
            "CUCUMBER_REDUNDANCY": "NO",
            "CUCUMBER_REDUNDANCY_WARNING_LEVEL": "20",
            "CUCUMBER_REDUNDANCY_ERROR_LEVEL": "60",
            "CUCUMBER_REDUNDANT_STEP_WARNING_LEVEL": "40",
            "CUCUMBER_COVERAGE_SOURCES": "Sources/App,Sources/Model"
        ]
        #expect(CoverageSettings.read(environment: [:]) == CoverageSettings())
        let fromEnvironment = CoverageSettings.read(environment: environment)
        #expect(fromEnvironment.warningLevel == 70)
        #expect(fromEnvironment.errorLevel == .off)
        #expect(!fromEnvironment.isRedundancy)
        #expect(fromEnvironment.redundancyWarningLevel == 20)
        #expect(fromEnvironment.redundancyErrorLevel == 60)
        #expect(fromEnvironment.redundantStepWarningLevel == 40)
        #expect(CoverageSettings().redundantStepWarningLevel == 50)
        #expect(fromEnvironment.sources == ["Sources/App", "Sources/Model"])
        Cucumber.coverageWarningLevel = .off
        Cucumber.coverageErrorLevel = 40
        Cucumber.redundancy = true
        Cucumber.redundancyWarningLevel = 10
        Cucumber.redundancyErrorLevel = .off
        Cucumber.redundantStepWarningLevel = .off
        Cucumber.coverageSources = ["Sources/Core"]
        let fromCode = CoverageSettings.read(environment: environment)
        #expect(fromCode.warningLevel == .off)
        #expect(fromCode.errorLevel == 40)
        #expect(fromCode.isRedundancy)
        #expect(fromCode.redundancyWarningLevel == 10)
        #expect(fromCode.redundancyErrorLevel == .off)
        #expect(fromCode.redundantStepWarningLevel == .off)
        #expect(fromCode.sources == ["Sources/Core"])
    }
}
