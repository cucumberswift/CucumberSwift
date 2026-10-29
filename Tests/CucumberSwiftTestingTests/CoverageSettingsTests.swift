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
        #expect(!CucumberSettings.isCoverage(environment: [:]))
        #expect(CucumberSettings.isCoverage(environment: [key: "yes"]))
        #expect(!CucumberSettings.isCoverage(environment: [key: "maybe"]))
        Cucumber.coverage = false
        #expect(!CucumberSettings.isCoverage(environment: [key: "YES"]))
    }

    @Test func theCoveragePathComesFromTheStaticVariableThenTheEnvironmentVariable() {
        defer { Cucumber.coveragePath = nil }
        let key = "CUCUMBER_COVERAGE_PATH"
        #expect(CucumberSettings.coveragePath(environment: [:]) == nil)
        #expect(CucumberSettings.coveragePath(environment: [key: " /tmp/env "]) == "/tmp/env")
        Cucumber.coveragePath = "/tmp/code"
        #expect(CucumberSettings.coveragePath(environment: [key: "/tmp/env"]) == "/tmp/code")
        Cucumber.coveragePath = " "
        #expect(CucumberSettings.coveragePath(environment: [key: "/tmp/env"]) == nil)
    }

    // Through the environment only: other suites set `Cucumber.parallelTesting` while this one runs.
    @Test func coverageRunsScenariosOneAtATimeEvenWithParallelTesting() {
        let environment = ["CUCUMBER_COVERAGE": "YES", "CUCUMBER_PARALLEL_TESTING": "YES"]
        #expect(!CucumberSettings.runsInParallel(compiled: true, environment: environment))
        #expect(CucumberSettings.runsInParallel(compiled: true, environment: ["CUCUMBER_PARALLEL_TESTING": "YES"]))
    }
}
