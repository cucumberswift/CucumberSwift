//
//  BazelRunnerTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class BazelRunnerTests: BazelRunnerTestCase {
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
        XCTAssertEqual(call.arguments.last, "--experimental_convenience_symlinks=normal", "The runner's own link flags come after the target's")
        let config = try XCTUnwrap(call.arguments.firstIndex(of: "--config=ci"))
        let prefix = try XCTUnwrap(call.arguments.firstIndex(of: "--symlink_prefix=bazel-"))
        XCTAssertLessThan(config, prefix, "A --config expands where it stands: the runner's prefix must come after it, or the config's wins")
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

    func testATestIsRunOnceAndAFailedRunFailsItWhateverRetriesTheProjectSets() throws {
        let copy = try makeCopy()
        let commands = commands(in: copy)
        _ = runner(.init(label: "//Tests:AppTests", arguments: ["--flaky_test_attempts=3", "--runs_per_test_detects_flakes"]), commands: commands).test(in: copy, request: TestRequest())
        let arguments = try XCTUnwrap(commands.calls.first).arguments
        XCTAssertEqual(arguments.last { $0.hasPrefix("--flaky_test_attempts") }, "--flaky_test_attempts=1", "A retry that passes would hide a failed attempt")
        XCTAssertEqual(arguments.last { $0.contains("runs_per_test_detects_flakes") }, "--noruns_per_test_detects_flakes", "A run that passes would hide one that failed")
    }

    func testAnInheritedCoveragePathIsClearedWhenCoverageIsMeasured() throws {
        let copy = try makeCopy()
        let commands = commands(in: copy)
        _ = runner(commands: commands, environment: ["CUCUMBER_COVERAGE_PATH": "/elsewhere"]).test(in: copy, request: TestRequest(measuresCoverage: true))
        let arguments = try XCTUnwrap(commands.calls.first).arguments
        XCTAssertTrue(arguments.contains("--test_env=CUCUMBER_COVERAGE_PATH="), "An empty path puts the coverage in the test's outputs")
        XCTAssertFalse(arguments.contains("--test_env=CUCUMBER_COVERAGE_PATH=/elsewhere"))
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
}
#endif
