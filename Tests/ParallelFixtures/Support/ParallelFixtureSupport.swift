//
//  ParallelFixtureSupport.swift
//  ParallelFixtures
//
//  What every parallel fixture checks, whatever kind of target it is. Each worker checks that a scenario's
//  steps ran once each, in order. CI checks the rest across workers (.github/scripts/parallel_records.py):
//  every scenario ran exactly once, more than one worker ran them, and each feature's hooks ran as often,
//  where and when they should (#387). For that, each run of a scenario and each feature hook writes a
//  record to the folder in the environment variable `PARALLEL_TEST_RECORDS`, when it is set. Every worker
//  also writes the Cucumber JSON report to the file in `CUCUMBER_REPORT_PATH`, which CI checks holds every
//  scenario once (#385).
//

import Foundation
import XCTest
import CucumberSwift

enum ParallelFixtureSupport {
    /// The records this process has written, which orders them within a worker.
    private static var sequence = 0

    /// Turns on experimental parallel testing and adds the hooks that check each scenario and record it,
    /// and record each feature hook. CI chooses the unit with `CUCUMBER_PARALLEL_TESTING_UNIT`, and sets
    /// `PARALLEL_FIXTURE_WITHOUT_SETTING=YES` to leave the setting out and check that Xcode's parallel
    /// testing then fails with CucumberSwift's message (#389).
    static func setUp() {
        if ProcessInfo.processInfo.environment["PARALLEL_FIXTURE_WITHOUT_SETTING"] != "YES" {
            Cucumber.parallelTesting = true
        }
        useReportInSandboxIfNeeded()

        BeforeFeature { feature in
            record("before", feature: feature)
        }
        AfterFeature { feature in
            record("after", feature: feature)
        }

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
            record("scenario", feature: scenario.feature, scenario: scenario)
        }
    }

    /// The UI test runner on macOS and Mac Catalyst is sandboxed and may not write to `CUCUMBER_REPORT_PATH`.
    /// It then writes the report to `parallel-test-report/report.json` in its own temporary folder, where CI
    /// collects it too. Everywhere else the environment variable is the setting.
    private static func useReportInSandboxIfNeeded() {
        guard let path = ProcessInfo.processInfo.environment["CUCUMBER_REPORT_PATH"], !path.isEmpty else { return }
        let folder = URL(fileURLWithPath: path).deletingLastPathComponent().path
        if (try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)) == nil
            || !FileManager.default.isWritableFile(atPath: folder) {
            Cucumber.reportPath = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("parallel-test-report/report.json").path
        }
    }

    /// Writes an empty file named `<process>.<sequence>.<kind>.<feature>.<scenario>.<UUID>`: this worker's
    /// process, the record's position among this process's records, `scenario`, `before` or `after`, the
    /// feature's title, the scenario's line and title (`-` for a feature hook), and a UUID, so that a second
    /// run in the same worker writes a second record. Each name has only letters, numbers and dashes.
    ///
    /// The UI test runner on macOS and Mac Catalyst is sandboxed and may not write to that folder. It then
    /// writes the record to `parallel-test-records` in its own temporary folder, where CI collects it too.
    static func record(_ kind: String, feature: Feature?, scenario: Scenario? = nil) {
        guard let folder = ProcessInfo.processInfo.environment["PARALLEL_TEST_RECORDS"], !folder.isEmpty else { return }
        func part(_ text: String) -> String {
            String(text.map { $0.isLetter || $0.isNumber ? $0 : "-" })
        }
        sequence += 1
        let scenarioPart = scenario.map { part("line \($0.location.line) \($0.title)") } ?? "-"
        let parts = [
            String(ProcessInfo.processInfo.processIdentifier),
            String(format: "%06d", sequence),
            kind,
            part(feature?.title ?? "No feature"),
            scenarioPart,
            UUID().uuidString
        ]
        let file = parts.joined(separator: ".")
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
        XCTFail("Could not record \(file): \(errors.joined(separator: "; "))")
    }
}
