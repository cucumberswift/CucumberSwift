//
//  ParallelFixtureSupport.swift
//  ParallelFixtures
//
//  What every parallel fixture checks, whatever kind of target it is. Each worker checks that a scenario's
//  steps ran once each, in order. CI checks the rest across workers: every scenario ran exactly once, and
//  more than one worker ran them. For that, each run of a scenario writes a record, named after the
//  scenario, the worker's process and a UUID, to the folder in the environment variable
//  `PARALLEL_TEST_RECORDS`, when it is set.
//

import Foundation
import XCTest
import CucumberSwift

enum ParallelFixtureSupport {
    /// Turns on experimental parallel testing and adds the hooks that check each scenario and record it.
    static func setUp() {
        Cucumber.experimentalParallelTesting = true

        var stepsRun = [Int]()
        BeforeScenario { _ in
            stepsRun = []
        }
        BeforeStep { step in
            if let index = step.scenario?.steps.firstIndex(where: { $0 === step }) {
                stepsRun.append(index)
            }
        }
        AfterScenario { scenario in
            XCTAssertEqual(stepsRun, Array(scenario.steps.indices), "The steps of '\(scenario.title)' did not each run once, in order")
            record(scenario)
        }
    }

    /// Writes an empty file named after the scenario, by its feature and its line, this worker's process,
    /// and a UUID, so that a second run of the scenario in the same worker writes a second record.
    static func record(_ scenario: Scenario) {
        guard let folder = ProcessInfo.processInfo.environment["PARALLEL_TEST_RECORDS"], !folder.isEmpty else { return }
        let feature = scenario.feature?.title ?? "No feature"
        let name = "\(feature) line \(scenario.location.line) \(scenario.title)"
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
        let url = URL(fileURLWithPath: folder, isDirectory: true)
            .appendingPathComponent("\(String(name)).\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
            try Data().write(to: url)
        } catch {
            XCTFail("Could not record '\(scenario.title)' at \(url.path): \(error)")
        }
    }
}
