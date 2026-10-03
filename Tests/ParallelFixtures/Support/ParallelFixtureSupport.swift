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
    ///
    /// The UI test runner on macOS and Mac Catalyst is sandboxed and may not write to that folder. It then
    /// writes the record to `parallel-test-records` in its own temporary folder, where CI collects it too.
    static func record(_ scenario: Scenario) {
        guard let folder = ProcessInfo.processInfo.environment["PARALLEL_TEST_RECORDS"], !folder.isEmpty else { return }
        let feature = scenario.feature?.title ?? "No feature"
        let name = "\(feature) line \(scenario.location.line) \(scenario.title)"
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
        let file = "\(String(name)).\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString)"
        let sandboxFolder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("parallel-test-records").path
        var errors = [String]()
        for candidate in [folder, sandboxFolder] {
            do {
                try FileManager.default.createDirectory(atPath: candidate, withIntermediateDirectories: true)
                try Data().write(to: URL(fileURLWithPath: candidate, isDirectory: true).appendingPathComponent(file))
                return
            } catch {
                errors.append("\(candidate): \(error.localizedDescription)")
            }
        }
        XCTFail("Could not record '\(scenario.title)': \(errors.joined(separator: "; "))")
    }
}
