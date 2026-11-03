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
    private static let folder = FileManager.default.temporaryDirectory

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

    // 6.8.0 failed a feature at or below 50% by default, which turned a project's tests red on upgrading (#507).
    @Test func byDefaultLowCoverageOnlyWarnsUntilAnErrorLevelIsSet() {
        defer { Cucumber.coverageErrorLevel = nil }
        let code = MeasuredCode(functions: [
            MeasuredCode.Function(name: "Basket.add(Int)", file: Self.folder.appendingPathComponent("Basket.swift").path, line: 1, regions: 0..<10)
        ])
        let scenario = CoverageScores.Scenario(name: "Adding", line: 3, tags: [], duration: 1, regions: [0])
        func severities() -> [CoverageIssue.Severity] {
            var settings = CoverageSettings.read(environment: [:])
            settings.isRedundancy = false
            let report = CoverageReport(scores: CoverageScores(scenarios: [scenario], code: code, isRedundancy: false), settings: settings)
            return report.issues(file: Self.folder.appendingPathComponent("Basket.feature"), line: 1, subject: "Feature").map(\.severity)
        }
        #expect(CoverageSettings().errorLevel == .off)
        #expect(severities() == [.warning])
        Cucumber.coverageErrorLevel = 50
        #expect(severities() == [.error])
    }

    // Xcode stops the test process when a suite records an issue, which the runner did at a feature's end (#509).
    @Test(arguments: [(CoverageIssue.Severity.warning, "warning"), (.error, "error")])
    func aCoverageIssueIsPrintedWithItsLocationNotRecorded(severity: CoverageIssue.Severity, label: String) {
        var lines = [String]()
        let file = Self.folder.appendingPathComponent("Basket.feature")
        let issue = CoverageIssue(severity: severity, message: "Feature coverage 38%", file: file, line: 1, kind: .coverage)
        issue.record { lines.append($0) }
        #expect(lines == ["\(file.path):1: \(label): Feature coverage 38%"])
    }

    // Recording in the suite is opt-in, because Xcode stops the test process when a suite records an issue (#509).
    @Test func coverageIssuesAreRecordedInSuitesOnlyWhenSettingsSayIt() {
        defer { Cucumber.coverageRecordsIssuesInSuites = nil }
        #expect(!CoverageSettings.read(environment: [:]).recordsIssuesInSuites)
        #expect(CoverageSettings.read(environment: ["CUCUMBER_COVERAGE_RECORDS_ISSUES_IN_SUITES": "YES"]).recordsIssuesInSuites)
        Cucumber.coverageRecordsIssuesInSuites = false
        #expect(!CoverageSettings.read(environment: ["CUCUMBER_COVERAGE_RECORDS_ISSUES_IN_SUITES": "YES"]).recordsIssuesInSuites)
        Cucumber.coverageRecordsIssuesInSuites = true
        #expect(CoverageSettings.read(environment: [:]).recordsIssuesInSuites)
    }

    @Test func anErrorRecordedInASuiteFailsIt() {
        var lines = [String]()
        let issue = CoverageIssue(severity: .error, message: "Feature coverage 38%", file: Self.folder.appendingPathComponent("Basket.feature"), line: 1, kind: .coverage)
        withKnownIssue {
            issue.record(inSuite: true) { lines.append($0) }
        }
        #expect(lines.isEmpty)
    }
}
