//
//  BazelRunnerTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class BazelRunnerTests: TemporaryFolderTestCase {
    private let target = BazelRunner.Target(label: "//Tests:AppTests")

    private func makeCopy(workspaceFile: String = "MODULE.bazel") throws -> URL {
        let copy = folder.appendingPathComponent("work/workspace")
        try FileManager.default.createDirectory(at: copy, withIntermediateDirectories: true)
        try "module(name = \"app\")\n".write(to: copy.appendingPathComponent(workspaceFile), atomically: true, encoding: .utf8)
        return copy
    }

    private func runner(
        _ target: BazelRunner.Target? = nil,
        commands: CommandRunning,
        cleanUp: CommandRunning? = nil,
        environment: [String: String] = [:]
    ) -> BazelRunner {
        BazelRunner(
            target: target ?? self.target,
            bazel: "/usr/bin/true",
            diskCache: folder.appendingPathComponent("cache"),
            commands: commands,
            cleanUpCommands: cleanUp ?? commands,
            environment: environment
        )
    }

    /// A `bazel` that writes the test's log where Bazel does, with `output` in it, and the coverage it leaves in the test's outputs.
    private func commands(in copy: URL, output: String = "Executed 3 tests, with 0 failures", status: Int32 = 0, coverage: Bool = false) -> RecordingCommands {
        RecordingCommands { call in
            if call.command == "test" {
                let logs = copy.appendingPathComponent("bazel-testlogs/Tests/AppTests")
                try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
                try? output.write(to: logs.appendingPathComponent("test.log"), atomically: true, encoding: .utf8)
                if coverage {
                    let run = logs.appendingPathComponent("test.outputs/_cucumberCoverage/run-1")
                    try? FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
                    try? "{}".write(to: run.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
                }
            }
            return .finished(status, output: "bazel output")
        }
    }

    func testTheLabelNamesThePackageFolderAndTheTest() {
        XCTAssertEqual(BazelRunner.Target(label: "//Tests:AppTests").package?.folder, "Tests")
        XCTAssertEqual(BazelRunner.Target(label: "//Tests:AppTests").package?.name, "AppTests")
        XCTAssertEqual(BazelRunner.Target(label: "//:AppTests").package?.folder, "")
        XCTAssertEqual(BazelRunner.Target(label: "//app/Tests").package?.name, "Tests")
        XCTAssertNil(BazelRunner.Target(label: "@other//Tests:AppTests").package)
        XCTAssertNil(BazelRunner.Target(label: "Tests:AppTests").package)
    }

    func testPrepareRefusesWhatItCannotBuild() throws {
        let empty = folder.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        XCTAssertThrowsError(try runner(commands: RecordingCommands()).prepare(copy: empty)) { XCTAssertTrue("\($0)".contains("no MODULE.bazel")) }
        let copy = try makeCopy()
        XCTAssertThrowsError(try runner(.init(label: "@other//:t"), commands: RecordingCommands()).prepare(copy: copy)) {
            XCTAssertTrue("\($0)".contains("starts with //"), "\($0)")
        }
        let missing = BazelRunner(target: target, bazel: "no-such-bazel", cleanUpCommands: RecordingCommands(), environment: ["PATH": folder.path])
        XCTAssertThrowsError(try missing.prepare(copy: copy)) { XCTAssertTrue("\($0)".contains("Couldn't find no-such-bazel"), "\($0)") }
        XCTAssertNoThrow(try runner(commands: RecordingCommands()).prepare(copy: copy))
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("cache").path), "The shared disk cache is made")
    }

    func testAWorkspaceFileIsEnoughWithoutBzlmod() throws {
        XCTAssertNoThrow(try runner(commands: RecordingCommands()).prepare(copy: try makeCopy(workspaceFile: "WORKSPACE")))
    }

    func testBuildsWithCoverageInLLVMsFormatAndTheSharedDiskCache() throws {
        let commands = RecordingCommands()
        let copy = try makeCopy()
        let result = runner(.init(label: "//Tests:AppTests", arguments: ["--config=ci"]), commands: commands).build(in: copy, timeout: 90)
        XCTAssertTrue(result.succeeded)
        let call = try XCTUnwrap(commands.calls.first)
        XCTAssertEqual(Array(call.afterStartup.prefix(2)), ["build", "//Tests:AppTests"])
        XCTAssertTrue(call.arguments.contains("--collect_code_coverage"))
        XCTAssertTrue(call.arguments.contains("--features=llvm_coverage_map_format"))
        XCTAssertTrue(call.arguments.contains("--features=-gcc_coverage_map_format"))
        XCTAssertTrue(call.arguments.contains("--disk_cache=\(folder.appendingPathComponent("cache").path)"))
        XCTAssertEqual(call.arguments.last, "--config=ci")
        XCTAssertEqual(call.timeout, 90)
    }

    func testAUsersDiskCacheReplacesTheSharedOne() throws {
        let commands = RecordingCommands()
        _ = runner(.init(label: "//Tests:AppTests", arguments: ["--disk_cache=/mine"]), commands: commands).build(in: try makeCopy(), timeout: nil)
        XCTAssertEqual(commands.calls[0].arguments.filter { $0.hasPrefix("--disk_cache") }, ["--disk_cache=/mine"])
    }

    func testSettingsReachTheTestsAsTestEnvAndTheRequestWinsOverTheToolsEnvironment() throws {
        let copy = try makeCopy()
        let commands = commands(in: copy)
        let run = runner(commands: commands, environment: ["CUCUMBER_TAGS": "@a", "CUCUMBER_COVERAGE": "NO", "HOME": "/h"]).test(
            in: copy, request: TestRequest(settings: ["CUCUMBERSWIFT_MUTANT": "7", "CUCUMBER_COVERAGE": "YES"])
        )
        let arguments = try XCTUnwrap(commands.calls.first).arguments
        XCTAssertEqual(Array(try XCTUnwrap(commands.calls.first).afterStartup.prefix(2)), ["test", "//Tests:AppTests"])
        XCTAssertTrue(arguments.contains("--test_env=CUCUMBER_TAGS=@a"))
        XCTAssertTrue(arguments.contains("--test_env=CUCUMBERSWIFT_MUTANT=7"))
        XCTAssertTrue(arguments.contains("--test_env=CUCUMBER_COVERAGE=YES"))
        XCTAssertFalse(arguments.contains("--test_env=CUCUMBER_COVERAGE=NO"))
        XCTAssertFalse(arguments.contains { $0.contains("HOME") }, "Only CucumberSwift's settings go on")
        XCTAssertTrue(arguments.contains("--nocache_test_results"), "A repeated test must run again")
        XCTAssertEqual(commands.calls.first?.environment, [:], "Bazel's environment doesn't carry the settings")
        XCTAssertTrue(run.succeeded)
    }

    func testCountsTheTestsFromTheTestsOwnLogAndANonZeroStatusFailsTheRun() throws {
        let copy = try makeCopy()
        let passed = runner(commands: commands(in: copy, output: "Executed 5 tests, with 0 failures")).test(in: copy, request: TestRequest())
        XCTAssertEqual(passed.testsRun, 5)
        XCTAssertNotNil(passed.log)
        let failed = runner(commands: commands(in: copy, output: "Executed 5 tests, with 1 failure", status: 3)).test(in: copy, request: TestRequest())
        XCTAssertEqual(failed.testsRun, 5)
        XCTAssertFalse(failed.succeeded)
        try FileManager.default.removeItem(at: copy.appendingPathComponent("bazel-testlogs"))
        let none = runner(commands: RecordingCommands()).test(in: copy, request: TestRequest())
        XCTAssertEqual(none.testsRun, 0, "A run with no test log ran no test")
    }

    func testACommandThatNeverStartedOrAnInfrastructureStatusIsNotATestResult() throws {
        let copy = try makeCopy()
        let missing = BazelRunner(target: target, bazel: "no-such-bazel", cleanUpCommands: RecordingCommands(), environment: ["PATH": folder.path])
        XCTAssertFalse(missing.build(in: copy, timeout: nil).started)
        XCTAssertFalse(missing.test(in: copy, request: TestRequest()).started)
        let notLaunched = RecordingCommands { _ in
            var result = CommandResult.finished(127)
            result.started = false
            return result
        }
        XCTAssertFalse(runner(commands: notLaunched).build(in: copy, timeout: nil).started)
        XCTAssertFalse(runner(commands: notLaunched).test(in: copy, request: TestRequest()).started)
        // 36 is Bazel's status for a problem with the machine: no test failed.
        let infrastructure = runner(commands: commands(in: copy, output: "Executed 5 tests, with 0 failures", status: 36)).test(in: copy, request: TestRequest())
        XCTAssertFalse(infrastructure.started)
        for status: Int32 in [0, 3] {
            XCTAssertTrue(runner(commands: commands(in: copy, status: status)).test(in: copy, request: TestRequest()).started)
        }
        XCTAssertTrue(runner(commands: commands(in: copy, status: 1)).build(in: copy, timeout: nil).started)
    }

    func testABuildThatStoppedWithAMachineProblemIsNotAnUnviableMutant() throws {
        let copy = try makeCopy()
        // 1 is a build that failed: the mutant doesn't build. 36 is a problem with the machine, and 2 a bad command line:
        // neither says anything about the mutant, and a build that never really started stops the run with Bazel's output.
        let failed = runner(commands: RecordingCommands { _ in .finished(1, output: "error: compile") }).build(in: copy, timeout: nil)
        XCTAssertFalse(failed.succeeded)
        XCTAssertTrue(failed.started, "A build that failed to compile is unviable")
        for status: Int32 in [2, 36, 37] {
            let result = runner(commands: RecordingCommands { _ in .finished(status, output: "infrastructure") }).build(in: copy, timeout: nil)
            XCTAssertFalse(result.succeeded)
            XCTAssertFalse(result.started, "Status \(status) isn't a build failure")
        }
        XCTAssertTrue(runner(commands: RecordingCommands()).build(in: copy, timeout: nil).started)
    }

    func testEveryCommandRunsWithAnOutputBaseOfTheRunsOwn() throws {
        let copy = try makeCopy()
        let commands = commands(in: copy)
        let bazel = runner(commands: commands)
        _ = bazel.build(in: copy, timeout: nil)
        _ = bazel.test(in: copy, request: TestRequest())
        bazel.cleanUp(copy: copy)
        let expected = "--output_base=\(copy.deletingLastPathComponent().appendingPathComponent("runner/output-base").path)"
        XCTAssertEqual(commands.calls.map(\.command), ["build", "test", "clean"])
        for call in commands.calls {
            XCTAssertEqual(call.arguments.first, expected, "A startup option goes before the command: \(call.arguments)")
        }
    }

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
        XCTAssertEqual(customArguments.filter { $0.hasPrefix("--symlink_prefix") }, ["--symlink_prefix=.bazel/"])
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

    func testCleanUpDeletesTheOutputBaseAndFallsBackToShuttingTheServerDown() throws {
        let copy = try makeCopy()
        let expunged = RecordingCommands()
        runner(commands: RecordingCommands(), cleanUp: expunged).cleanUp(copy: copy)
        XCTAssertEqual(expunged.calls.map(\.afterStartup), [["clean", "--expunge"]])
        let failing = RecordingCommands { call in .finished(call.command == "clean" ? 1 : 0) }
        runner(commands: RecordingCommands(), cleanUp: failing).cleanUp(copy: copy)
        XCTAssertEqual(failing.calls.map(\.afterStartup), [["clean", "--expunge"], ["shutdown"]])
        let gone = RecordingCommands()
        runner(commands: RecordingCommands(), cleanUp: gone).cleanUp(copy: folder.appendingPathComponent("deleted"))
        XCTAssertTrue(gone.calls.isEmpty, "A copy that is already deleted has nothing to clean")
    }

    func testTheOptionsNameABazelTarget() throws {
        let options = try MutationOptions.parse([
            "--root", "/p", "--bazel-target", "//Tests:AppTests", "--sources", "App", "--bazel-arg", "--config=ci", "--bazel-arg", "--keep_going"
        ])
        XCTAssertEqual(options.bazelTarget, BazelRunner.Target(label: "//Tests:AppTests", arguments: ["--config=ci", "--keep_going"]))
        XCTAssertTrue(options.makeRunner() is BazelRunner)
        XCTAssertEqual(options.sources, ["App"])
        XCTAssertNil(try MutationOptions.parse(["--root", "/p"]).bazelTarget)
    }

    func testRefusesBazelOptionsThatDoNotFitTogether() {
        let root = ["--root", "/p"]
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--bazel-arg", "--keep_going"])) { XCTAssertTrue("\($0)".contains("need --bazel-target"), "\($0)") }
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--bazel-target", "//:t"])) { XCTAssertTrue("\($0)".contains("needs --sources"), "\($0)") }
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--bazel-target", "//:t", "--sources", "A", "--target", "A"])) { XCTAssertTrue("\($0)".contains("pass --sources"), "\($0)") }
        XCTAssertThrowsError(try MutationOptions.parse(root + [
            "--bazel-target", "//:t", "--sources", "A", "--project", "A.xcodeproj", "--scheme", "A", "--destination", "d"
        ])) { XCTAssertTrue("\($0)".contains("not both"), "\($0)") }
    }

    func testRefusesBazelOptionsThatAreIgnoredOrNamedWithTheirDefaults() {
        let root = ["--root", "/p"]
        // `--bazel bazel` names the default, and is still an option that needs a target.
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--bazel", "bazel"])) { XCTAssertTrue("\($0)".contains("need --bazel-target"), "\($0)") }
        // BazelRunner never runs xcodebuild, so a custom one would be ignored without a word.
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--bazel-target", "//:t", "--sources", "A", "--xcodebuild", "/custom/xcodebuild"])) {
            XCTAssertTrue("\($0)".contains("--xcodebuild"), "\($0)")
        }
        XCTAssertNoThrow(try MutationOptions.parse(root + ["--xcodebuild", "/custom/xcodebuild"]), "SwiftPM and Xcode runs keep accepting it")
    }

    func testBazelRunStartsInTheRunfilesAndTheWorkspaceIsTheDefaultRoot() throws {
        let environment = ["BUILD_WORKSPACE_DIRECTORY": "/the/workspace"]
        XCTAssertEqual(try MutationOptions.parse(["--bazel-target", "//:t", "--sources", "A"], environment: environment).root.path, "/the/workspace")
        XCTAssertEqual(try MutationOptions.parse(["--root", "/p", "--bazel-target", "//:t", "--sources", "A"], environment: environment).root.path, "/p", "--root wins")
        XCTAssertEqual(try MutationOptions.parse([], environment: ["BUILD_WORKSPACE_DIRECTORY": ""]).root.standardizedFileURL.path,
                       URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL.path, "An empty variable names no workspace")
    }

    func testTheRootProblemOfABazelWorkspaceNamesModuleBazel() throws {
        var options = MutationOptions(root: folder)
        options.bazelTarget = target
        XCTAssertTrue(options.rootProblem?.contains("no MODULE.bazel") == true)
        try "x".write(to: folder.appendingPathComponent("MODULE.bazel"), atomically: true, encoding: .utf8)
        XCTAssertNil(options.rootProblem)
    }
}
/// True the first time `consume()` is called, false after.
private final class FirstOnly: @unchecked Sendable {
    private let lock = NSLock()
    private var used = false
    func consume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        defer { used = true }
        return !used
    }
}

extension RecordingCommands.Call {
    /// The arguments after the startup options, which start with the command: `build`, `test`, `clean` or `shutdown`.
    var afterStartup: [String] { Array(arguments.drop { $0.hasPrefix("--output_base=") }) }
    var command: String? { afterStartup.first }
}
#endif
