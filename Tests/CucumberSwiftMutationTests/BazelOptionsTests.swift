//
//  BazelOptionsTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class BazelOptionsTests: BazelRunnerTestCase {
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
        let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL.path
        let empty = try MutationOptions.parse([], environment: ["BUILD_WORKSPACE_DIRECTORY": ""])
        XCTAssertEqual(empty.root.standardizedFileURL.path, current, "An empty variable names no workspace")
    }

    func testTheRootProblemOfABazelWorkspaceNamesModuleBazel() throws {
        var options = MutationOptions(root: folder)
        options.bazelTarget = target
        XCTAssertTrue(options.rootProblem?.contains("no MODULE.bazel") == true)
        try "x".write(to: folder.appendingPathComponent("MODULE.bazel"), atomically: true, encoding: .utf8)
        XCTAssertNil(options.rootProblem)
    }
}
#endif
