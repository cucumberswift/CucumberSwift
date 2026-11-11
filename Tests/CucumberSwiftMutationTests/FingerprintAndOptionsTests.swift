//
//  FingerprintAndOptionsTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
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
        XCTAssertTrue(options.findsSources, "Without --sources, the tool finds the package's targets")
        XCTAssertEqual(options.targets, [])
        XCTAssertNil(options.tags)
        XCTAssertEqual(options.format, .text)
    }

    func testThePackageIsTheCurrentFolderWithoutRoot() throws {
        let options = try MutationOptions.parse([])
        let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
        XCTAssertEqual(options.root, current)
        XCTAssertEqual(options.output, current.appendingPathComponent(".build/mutation-testing"))
    }

    func testReadsTheTargetsTagsAndFormat() throws {
        let options = try MutationOptions.parse(["--target", "Shop", "--target", "Cart", "--tags", "before", "--format", "xcode"])
        XCTAssertEqual(options.targets, ["Shop", "Cart"])
        XCTAssertEqual(options.tags, "before")
        XCTAssertEqual(options.format, .xcode)
        XCTAssertThrowsError(try MutationOptions.parse(["--format", "html"])) {
            XCTAssertEqual("\($0)", "--format is text or xcode, not \"html\"")
        }
    }

    func testReadsEveryOption() throws {
        let arguments = [
            "--root", "/p", "--sources", "Sources/A", "--sources", "Sources/B", "--max-mutants", "10",
            "--timeout-multiplier", "5", "--minimum-timeout", "12", "--baseline-runs", "1",
            "--work-dir", "/w", "--output", "/o", "--swift", "/bin/swift", "--dry-run", "--disable-prebuilts"
        ]
        let options = try MutationOptions.parse(arguments)
        XCTAssertEqual(options.sources, ["Sources/A", "Sources/B"])
        XCTAssertFalse(options.findsSources)
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
    }

    func testCountsAreWholeNumbersAboveZero() {
        // `Int(0.5)` is 0: one baseline run would be the range 1...0, which traps, and no mutant would be tested.
        for (option, value) in [("--baseline-runs", "0.5"), ("--max-mutants", "0.5"), ("--max-mutants", "1e300"), ("--baseline-runs", "two")] {
            XCTAssertThrowsError(try MutationOptions.parse(["--root", "/p", option, value])) {
                XCTAssertEqual("\($0)", "\(option) needs a whole number above 0, not \"\(value)\"")
            }
        }
    }

    func testTheDefaultSwiftIsTheFirstOnThePath() throws {
        let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("swift-path-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let bin = folder.appendingPathComponent("bin")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        let swift = bin.appendingPathComponent("swift")
        try "#!/bin/sh\n".write(to: swift, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: swift.path)
        XCTAssertEqual(MutationOptions.swift(onPath: "\(folder.path)/missing:\(bin.path):/usr/bin"), swift.path)
        XCTAssertEqual(MutationOptions.swift(onPath: folder.path), "/usr/bin/swift", "No swift on the path")
        XCTAssertEqual(MutationOptions.swift(onPath: nil), "/usr/bin/swift")
    }
}
#endif
