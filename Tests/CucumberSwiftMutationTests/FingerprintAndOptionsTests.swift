//
//  FingerprintAndOptionsTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class FingerprintTests: TemporaryFolderTestCase {
    func testAnEditedFileIsADifference() throws {
        let root = try makePackage()
        let before = ProjectFingerprint.take(of: root)
        try "changed".write(to: root.appendingPathComponent("Sources/Voting/Voting.swift"), atomically: true, encoding: .utf8)
        XCTAssertEqual(ProjectFingerprint.take(of: root).differences(from: before), ["Sources/Voting/Voting.swift"])
    }

    func testAnAddedAndARemovedFileAreDifferences() throws {
        let root = try makePackage()
        let before = ProjectFingerprint.take(of: root)
        try "new".write(to: root.appendingPathComponent("Sources/Voting/New.swift"), atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(at: root.appendingPathComponent("Tests/VotingTests/VotingTests.swift"))
        XCTAssertEqual(ProjectFingerprint.take(of: root).differences(from: before),
                       ["Sources/Voting/New.swift", "Tests/VotingTests/VotingTests.swift"])
    }

    func testBuildAndGitFoldersAreNotCompared() throws {
        let root = try makePackage()
        let before = ProjectFingerprint.take(of: root)
        try "other".write(to: root.appendingPathComponent(".build/debug/artifact"), atomically: true, encoding: .utf8)
        try "other".write(to: root.appendingPathComponent(".git/HEAD"), atomically: true, encoding: .utf8)
        XCTAssertEqual(ProjectFingerprint.take(of: root).files, before.files)
    }

    func testGitStateIsComparedWhenThePackageIsInARepository() throws {
        let root = try makePackage()
        let status = FakeGit()
        let before = ProjectFingerprint.take(of: root, runner: status)
        status.porcelain = "?? Sources/Voting/Staged.swift\n"
        XCTAssertEqual(ProjectFingerprint.take(of: root, runner: status).differences(from: before), ["git status, index or HEAD"])
    }

    func testAnUnchangedPackageHasNoDifferences() throws {
        let root = try makePackage()
        XCTAssertEqual(ProjectFingerprint.take(of: root).differences(from: ProjectFingerprint.take(of: root)), [])
    }
}

private final class FakeGit: CommandRunning, @unchecked Sendable {
    var porcelain = ""

    func run(
        _: String,
        _ arguments: [String],
        in _: URL,
        environment _: [String: String],
        timeout _: TimeInterval?
    ) -> CommandResult {
        .finished(0, output: arguments.first == "status" ? porcelain : "same")
    }
}

final class MutationOptionsTests: XCTestCase {
    func testDefaults() throws {
        let options = try MutationOptions.parse(["--root", "/tmp/package"])
        XCTAssertEqual(options.root.path, "/tmp/package")
        XCTAssertEqual(options.output.path, "/tmp/package/.build/mutation-testing")
        XCTAssertEqual(options.sources, ["Sources"])
        XCTAssertEqual(options.baselineRuns, 2)
        XCTAssertEqual(options.timeoutMultiplier, 3)
        XCTAssertNil(options.maxMutants)
        XCTAssertFalse(options.dryRun)
    }

    func testReadsEveryOption() throws {
        let arguments = [
            "--root", "/p", "--sources", "Sources/A", "--sources", "Sources/B", "--max-mutants", "10",
            "--timeout-multiplier", "5", "--minimum-timeout", "12", "--baseline-runs", "1",
            "--work-dir", "/w", "--output", "/o", "--swift", "/bin/swift", "--dry-run", "--disable-prebuilts"
        ]
        let options = try MutationOptions.parse(arguments)
        XCTAssertEqual(options.sources, ["Sources/A", "Sources/B"])
        XCTAssertEqual(options.maxMutants, 10)
        XCTAssertEqual(options.timeoutMultiplier, 5)
        XCTAssertEqual(options.minimumTimeout, 12)
        XCTAssertEqual(options.baselineRuns, 1)
        XCTAssertEqual(options.workDirectory?.path, "/w")
        XCTAssertEqual(options.output.path, "/o")
        XCTAssertEqual(options.swift, "/bin/swift")
        XCTAssertTrue(options.dryRun)
        XCTAssertEqual(options.swiftArguments, ["--disable-sandbox", "--disable-experimental-prebuilts"])
    }

    func testRefusesWhatItDoesNotKnow() {
        XCTAssertThrowsError(try MutationOptions.parse(["--root", "/p", "--bogus"])) {
            XCTAssertEqual("\($0)", "Unknown option --bogus")
        }
        XCTAssertThrowsError(try MutationOptions.parse(["--root", "/p", "--max-mutants"])) {
            XCTAssertEqual("\($0)", "--max-mutants needs a value")
        }
        XCTAssertThrowsError(try MutationOptions.parse(["--root", "/p", "--max-mutants", "0"]))
        XCTAssertThrowsError(try MutationOptions.parse(["--root", "/p", "--baseline-runs", "--dry-run"]))
        XCTAssertThrowsError(try MutationOptions.parse([]))
    }

    func testReadsTheXcodeOptions() throws {
        let options = try MutationOptions.parse([
            "--root", "/p", "--workspace", "App.xcworkspace", "--scheme", "App", "--destination", "platform=macOS",
            "--test-target", "AppTests", "--xcodebuild-arg", "-quiet", "--xcodebuild-arg", "-skipMacroValidation"
        ])
        XCTAssertEqual(options.xcode, XcodebuildRunner.Target(
            container: "App.xcworkspace", scheme: "App", destination: "platform=macOS", testTarget: "AppTests",
            arguments: ["-quiet", "-skipMacroValidation"]))
        XCTAssertTrue(options.makeRunner() is XcodebuildRunner)
        XCTAssertNil(try MutationOptions.parse(["--root", "/p"]).xcode)
        XCTAssertTrue(try MutationOptions.parse(["--root", "/p"]).makeRunner() is SwiftPMRunner)
    }

    func testRefusesXcodeOptionsThatDoNotFitTogether() {
        let root = ["--root", "/p"]
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--scheme", "A", "--destination", "platform=macOS"])) {
            XCTAssertTrue("\($0)".contains("need --project or --workspace"), "\($0)")
        }
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--project", "A.xcodeproj", "--destination", "platform=macOS"])) {
            XCTAssertEqual("\($0)", "--project and --workspace need --scheme")
        }
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--project", "A.xcodeproj", "--scheme", "A"])) {
            XCTAssertTrue("\($0)".contains("need --destination"), "\($0)")
        }
        XCTAssertThrowsError(try MutationOptions.parse(root + ["--project", "A.xcodeproj", "--workspace", "A.xcworkspace", "--scheme", "A", "--destination", "d"])) {
            XCTAssertEqual("\($0)", "Pass --project or --workspace, not both")
        }
    }

    func testTheRootProblemNamesTheFileTheRunnerNeeds() throws {
        let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("options-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        var options = MutationOptions(root: folder)
        XCTAssertTrue(options.rootProblem?.contains("no Package.swift") == true)
        options.xcode = XcodebuildRunner.Target(container: "A.xcodeproj", scheme: "A", destination: "platform=macOS")
        XCTAssertTrue(options.rootProblem?.contains("no A.xcodeproj") == true)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("A.xcodeproj"), withIntermediateDirectories: true)
        XCTAssertNil(options.rootProblem)
    }
}
