//
//  CucumberSwiftParallelConsumerTests.swift
//  CucumberSwiftParallelConsumerTests
//
//  A consumer of experimental parallel testing (#31), run by CI with Xcode's parallel testing on. Each
//  worker checks that a scenario's steps ran once each, in order. CI checks the rest across workers:
//  every scenario ran exactly once, and more than one worker ran them. For that, each scenario writes a
//  record, named after the scenario and the worker's process, to the folder in the environment variable
//  `PARALLEL_TEST_RECORDS`, when it is set.
//
//  Not part of CucumberSwift.xctestplan, whose CI job fails any bundle that runs in parallel.
//

import Foundation
import XCTest
import CucumberSwift

enum ParallelTestRecords {
    /// Writes an empty file named after the scenario, by its feature and its line, and this worker's process.
    static func record(_ scenario: Scenario) {
        guard let folder = ProcessInfo.processInfo.environment["PARALLEL_TEST_RECORDS"], !folder.isEmpty else { return }
        let feature = scenario.feature?.title ?? "No feature"
        let name = "\(feature) line \(scenario.location.line) \(scenario.title)"
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
        let url = URL(fileURLWithPath: folder, isDirectory: true)
            .appendingPathComponent("\(String(name)).\(ProcessInfo.processInfo.processIdentifier)")
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
            try Data().write(to: url)
        } catch {
            XCTFail("Could not record '\(scenario.title)' at \(url.path): \(error)")
        }
    }
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        // A subclass of CucumberTest, as consumers write it.
        class TestDiscovery: CucumberTest {
            // Empty on purpose: XCTest hands this subclass to a worker of its own, which must not run the scenarios again.
        }
        return Bundle(for: TestDiscovery.self)
    }

    public func setupSteps() {
        Cucumber.experimentalParallelTesting = true

        var items = 0
        var stepsRun = [Int]()

        BeforeScenario { _ in
            items = 0
            stepsRun = []
        }
        BeforeStep { step in
            if let index = step.scenario?.steps.firstIndex(where: { $0 === step }) {
                stepsRun.append(index)
            }
        }
        AfterScenario { scenario in
            XCTAssertEqual(stepsRun, Array(scenario.steps.indices), "The steps of '\(scenario.title)' did not each run once, in order")
            ParallelTestRecords.record(scenario)
        }

        Given("a fresh cart") { _, _ in
            XCTAssertEqual(items, 0)
        }
        When("I add {int} items") { match, _ in
            items += try match.first(\.int)
        }
        Then("the cart holds {int} items") { match, _ in
            XCTAssertEqual(items, try match.first(\.int))
        }
        // Long enough that Xcode hands the scenarios to more than one worker.
        Then("the scenario takes a moment") { _, _ in
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}
