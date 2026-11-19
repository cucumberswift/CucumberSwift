//
//  BazelRunnerResultsTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class BazelRunnerResultsTests: BazelRunnerTestCase {
    func testTheTestLogsAreReadWhateverPrefixTheProjectSetsForItsLinks() throws {
        let copy = try makeCopy()
        func commands(prefix: String) -> RecordingCommands {
            RecordingCommands { call in
                if call.command == "test" {
                    let logs = URL(fileURLWithPath: copy.path + "/" + prefix + "testlogs/Tests/AppTests")
                    try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
                    try? "Executed 4 tests, with 0 failures".write(to: logs.appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
                }
                return .finished(0)
            }
        }
        let normal = commands(prefix: "bazel-")
        XCTAssertEqual(runner(commands: normal).test(in: copy, request: TestRequest()).testsRun, 4)
        let arguments = try XCTUnwrap(normal.calls.first).arguments
        XCTAssertTrue(arguments.contains("--symlink_prefix=bazel-"), "A project's .bazelrc prefix mustn't move the test logs")
        XCTAssertTrue(arguments.contains("--experimental_convenience_symlinks=normal"))
        // A prefix in the target's own arguments is the project's choice, and the logs are where it says.
        let custom = commands(prefix: ".bazel/")
        let run = runner(.init(label: "//Tests:AppTests", arguments: ["--symlink_prefix=.bazel/"]), commands: custom).test(in: copy, request: TestRequest())
        XCTAssertEqual(run.testsRun, 4)
        let customArguments = try XCTUnwrap(custom.calls.first).arguments
        XCTAssertEqual(customArguments.last { $0.hasPrefix("--symlink_prefix") }, "--symlink_prefix=.bazel/")
        // A named config that sets its own prefix comes after the project's directly given one, and would win: the runner
        // repeats the prefix it reads at the very end.
        let configured = commands(prefix: "mine-")
        let withConfig = BazelRunner.Target(label: "//Tests:AppTests", arguments: ["--symlink_prefix=mine-", "--config=ci"])
        XCTAssertEqual(runner(withConfig, commands: configured).test(in: copy, request: TestRequest()).testsRun, 4)
        let configuredArguments = try XCTUnwrap(configured.calls.first).arguments
        let config = try XCTUnwrap(configuredArguments.firstIndex(of: "--config=ci"))
        let lastPrefix = try XCTUnwrap(configuredArguments.lastIndex { $0.hasPrefix("--symlink_prefix=") })
        XCTAssertEqual(configuredArguments[lastPrefix], "--symlink_prefix=mine-")
        XCTAssertGreaterThan(lastPrefix, config, "The prefix the runner reads must come after the config")
        // Bazel also takes the flag and its value as two arguments.
        let separate = commands(prefix: "apart-")
        let twoArguments = BazelRunner.Target(label: "//Tests:AppTests", arguments: ["--symlink_prefix", "apart-", "--config=ci"])
        XCTAssertEqual(runner(twoArguments, commands: separate).test(in: copy, request: TestRequest()).testsRun, 4)
        let separateArguments = try XCTUnwrap(separate.calls.first).arguments
        XCTAssertEqual(separateArguments.last { $0.hasPrefix("--symlink_prefix=") }, "--symlink_prefix=apart-")
    }

    func testTheTestLogsAreReadFromAnAbsoluteSymlinkPrefix() throws {
        let copy = try makeCopy()
        let links = FileManager.default.temporaryDirectory.appendingPathComponent("links-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: links) }
        let commands = RecordingCommands { call in
            if call.command == "test" {
                let logs = links.appendingPathComponent("mine-testlogs/Tests/AppTests")
                try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
                try? "Executed 4 tests, with 0 failures".write(to: logs.appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
            }
            return .finished(0)
        }
        let absolute = BazelRunner.Target(label: "//Tests:AppTests", arguments: ["--symlink_prefix=\(links.path)/mine-"])
        let run = runner(absolute, commands: commands).test(in: copy, request: TestRequest())
        XCTAssertEqual(run.testsRun, 4, "An absolute prefix names the folder itself, not a folder in the copy")
    }

    func testTheReportIsWrittenToAFolderTheSandboxAllows() throws {
        let copy = try makeCopy()
        let commands = commands(in: copy)
        let run = runner(commands: commands).test(in: copy, request: TestRequest(writesReport: true))
        let arguments = try XCTUnwrap(commands.calls.first).arguments
        let path = try XCTUnwrap(arguments.first { $0.hasPrefix("--test_env=CUCUMBER_REPORT_PATH=") }).replacingOccurrences(of: "--test_env=CUCUMBER_REPORT_PATH=", with: "")
        XCTAssertTrue(path.hasSuffix("runner/reports/report-1.json"), path)
        XCTAssertTrue(arguments.contains { $0.hasPrefix("--sandbox_writable_path=") && $0.hasSuffix("runner/reports") })
        XCTAssertNil(run.cucumberReport, "No report was written")
        // The same runner's first call writes a report to the path it was given, its second writes none: only the first has one.
        let firstCallWrites = FirstOnly()
        let writesOnce = RecordingCommands { call in
            if call.command == "test", firstCallWrites.consume(), let setting = call.arguments.first(where: { $0.hasPrefix("--test_env=CUCUMBER_REPORT_PATH=") }) {
                try? "[]".write(toFile: String(setting.dropFirst("--test_env=CUCUMBER_REPORT_PATH=".count)), atomically: true, encoding: .utf8)
            }
            return .finished(0)
        }
        let bazel = runner(commands: writesOnce)
        XCTAssertEqual(bazel.test(in: copy, request: TestRequest(writesReport: true)).cucumberReport?.lastPathComponent, "report-1.json")
        XCTAssertNil(bazel.test(in: copy, request: TestRequest(writesReport: true)).cucumberReport, "The second call wrote no report-2.json")
    }

    func testCoverageFromTheTestsOutputsIsKeptForEachRun() throws {
        let copy = try makeCopy()
        let bazel = runner(commands: commands(in: copy, coverage: true))
        let first = bazel.test(in: copy, request: TestRequest(measuresCoverage: true))
        let second = bazel.test(in: copy, request: TestRequest(measuresCoverage: true))
        XCTAssertEqual(first.coverageFolder?.lastPathComponent, "coverage-1")
        XCTAssertEqual(second.coverageFolder?.lastPathComponent, "coverage-2")
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(first.coverageFolder).appendingPathComponent("run-1/manifest.json").path))
        XCTAssertNil(bazel.test(in: copy, request: TestRequest()).coverageFolder, "A run that doesn't measure has no coverage folder")
    }

    func testRepeatedRunsAndShardsAreReadFromTheirOwnFolders() throws {
        let copy = try makeCopy()
        let commands = RecordingCommands { call in
            if call.command == "test" {
                let target = copy.appendingPathComponent("bazel-testlogs/Tests/AppTests")
                for (result, count) in [("run_1_of_2/shard_1_of_2", 2), ("run_1_of_2/shard_2_of_2", 3), ("run_2_of_2", 5)] {
                    let folder = target.appendingPathComponent(result)
                    let run = folder.appendingPathComponent("test.outputs/_cucumberCoverage/run-1")
                    try? FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
                    try? "Executed \(count) tests, with 0 failures".write(to: folder.appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
                    try? "{}".write(to: run.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
                }
            }
            return .finished(0, output: "bazel output")
        }
        let run = runner(commands: commands).test(in: copy, request: TestRequest(measuresCoverage: true))
        XCTAssertEqual(run.testsRun, 10, "Each run's and shard's own log counts its tests, and the counts add up: 2 + 3 + 5")
        let coverage = try XCTUnwrap(run.coverageFolder)
        let kept = try FileManager.default.contentsOfDirectory(atPath: coverage.path).sorted()
        XCTAssertEqual(kept.count, 3, "Every run and shard keeps its run folder: \(kept)")
        XCTAssertTrue(kept.allSatisfy { $0.hasPrefix("run-") })
        for folder in kept {
            XCTAssertTrue(FileManager.default.fileExists(atPath: coverage.appendingPathComponent(folder).appendingPathComponent("manifest.json").path))
        }
    }

    func testCoverageThatMissesAShardIsNotKept() throws {
        let copy = try makeCopy()
        let commands = RecordingCommands { call in
            if call.command == "test" {
                let target = copy.appendingPathComponent("bazel-testlogs/Tests/AppTests")
                for (shard, measured) in [("shard_1_of_2", true), ("shard_2_of_2", false)] {
                    let folder = target.appendingPathComponent(shard)
                    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    try? "Executed 2 tests, with 0 failures".write(to: folder.appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
                    if measured {
                        let run = folder.appendingPathComponent("test.outputs/_cucumberCoverage/run-1")
                        try? FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
                        try? "{}".write(to: run.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
                    }
                }
            }
            return .finished(0, output: "bazel output")
        }
        let run = runner(commands: commands).test(in: copy, request: TestRequest(measuresCoverage: true))
        XCTAssertNil(run.coverageFolder, "A shard without coverage would make its scenarios' code look untested")
    }

    func testCoverageFolderThatHasNoRunFolderIsNotKept() throws {
        let copy = try makeCopy()
        let commands = RecordingCommands { call in
            if call.command == "test" {
                let target = copy.appendingPathComponent("bazel-testlogs/Tests/AppTests")
                for (shard, runs) in [("shard_1_of_2", 1), ("shard_2_of_2", 0)] {
                    let coverage = target.appendingPathComponent(shard).appendingPathComponent("test.outputs/_cucumberCoverage")
                    try? FileManager.default.createDirectory(at: coverage, withIntermediateDirectories: true)
                    try? "Executed 2 tests, with 0 failures".write(to: target.appendingPathComponent(shard).appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
                    if runs > 0 {
                        let run = coverage.appendingPathComponent("run-1")
                        try? FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
                        try? "{}".write(to: run.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
                    }
                }
            }
            return .finished(0)
        }
        let run = runner(commands: commands).test(in: copy, request: TestRequest(measuresCoverage: true))
        XCTAssertNil(run.coverageFolder, "A shard whose coverage folder is empty contributes no scenarios: keep none")
    }

    func testTheTestsOutputsAreNotZipped() throws {
        let copy = try makeCopy()
        let commands = commands(in: copy)
        _ = runner(commands: commands).test(in: copy, request: TestRequest(measuresCoverage: true))
        let arguments = try XCTUnwrap(commands.calls.first).arguments
        XCTAssertTrue(arguments.contains("--nozip_undeclared_test_outputs"), "A zipped outputs folder has no coverage folder to keep")
        XCTAssertGreaterThan(try XCTUnwrap(arguments.firstIndex(of: "--nozip_undeclared_test_outputs")), try XCTUnwrap(arguments.firstIndex(of: "--nocache_test_results")))
    }
}
#endif
