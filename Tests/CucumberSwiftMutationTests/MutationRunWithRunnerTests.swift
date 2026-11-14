//
//  MutationRunWithRunnerTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

/// A mutation run with a `TestRunner` of its own: what the run asks of the runner, and a run through `xcodebuild`.
final class MutationRunWithRunnerTests: TemporaryFolderTestCase {
    private var root: URL!
    private var output: URL!
    private var log = [String]()

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = try makePackage()
        output = folder.appendingPathComponent("reports")
    }

    private func options() -> MutationOptions {
        var options = MutationOptions(root: root)
        options.output = output
        options.workDirectory = folder.appendingPathComponent("work")
        options.minimumTimeout = 5
        return options
    }

    func testTheRunnerIsPreparedOnceAndCleanedUpAfterEveryEnd() {
        let prepared = Counter()
        let cleaned = Counter()
        for outcome in [Int32(0), Int32(1)] {
            let spy = SpyRunner(prepared: prepared, cleaned: cleaned, buildStatus: outcome == 0, testsRun: outcome == 0 ? 3 : 0)
            let status = MutationRun(options: options(), discoverer: FakeDiscoverer(), testRunner: spy) { [weak self] in self?.log.append($0) }.run()
            XCTAssertEqual(status, outcome == 0 ? MutationRun.Status.completed : MutationRun.Status.baselineFailed)
        }
        XCTAssertEqual(prepared.value, 2, "Once for each run")
        XCTAssertEqual(cleaned.value, 2, "After the run that finished and after the one that stopped at its baseline")
    }

    func testTheTagsReachEveryTestRunAsASettingWithoutAnEnvironmentVariable() {
        var settings = options()
        settings.tags = "@smoke"
        let spy = SpyRunner(prepared: Counter(), cleaned: Counter())
        _ = MutationRun(options: settings, discoverer: FakeDiscoverer(), testRunner: spy) { [weak self] in self?.log.append($0) }.run()
        let requests = spy.requests
        XCTAssertGreaterThanOrEqual(requests.count, 4, "Two baseline runs and a run for each mutant")
        XCTAssertTrue(requests.allSatisfy { $0.settings["CUCUMBER_TAGS"] == "@smoke" })
        let withoutTags = SpyRunner(prepared: Counter(), cleaned: Counter())
        _ = MutationRun(options: options(), discoverer: FakeDiscoverer(), testRunner: withoutTags) { [weak self] in self?.log.append($0) }.run()
        XCTAssertTrue(withoutTags.requests.allSatisfy { $0.settings["CUCUMBER_TAGS"] == nil })
    }

    func testARunnerThatCannotPrepareFailsTheRunAndStillCleansUp() {
        let prepared = Counter()
        let cleaned = Counter()
        let spy = SpyRunner(prepared: prepared, cleaned: cleaned, prepareFails: true)
        let status = MutationRun(options: options(), discoverer: FakeDiscoverer(), testRunner: spy) { [weak self] in self?.log.append($0) }.run()
        XCTAssertEqual(status, MutationRun.Status.failed)
        XCTAssertTrue(log.joined().contains("error: cannot prepare"), log.joined())
        XCTAssertEqual(cleaned.value, 1)
    }

    func testTheRunnerLeavesOutTheFoldersItNames() throws {
        try "x".write(to: root.appendingPathComponent("skipped.txt"), atomically: true, encoding: .utf8)
        let spy = SpyRunner(prepared: Counter(), cleaned: Counter(), excluded: ["skipped.txt"])
        var settings = options()
        settings.dryRun = true
        let seen = CopyListing()
        spy.onPrepare = { copy in seen.names = ((try? FileManager.default.contentsOfDirectory(atPath: copy.path)) ?? []).sorted() }
        _ = MutationRun(options: settings, discoverer: FakeDiscoverer(), testRunner: spy) { [weak self] in self?.log.append($0) }.run()
        XCTAssertTrue(seen.names.contains("Package.swift"))
        XCTAssertFalse(seen.names.contains("skipped.txt"), seen.names.joined(separator: ", "))
    }

    // MARK: through xcodebuild

    func testRunsMutationTestingThroughXcodebuild() throws {
        // The copy has the project the runner builds.
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Voting.xcodeproj"), withIntermediateDirectories: true)
        var settings = options()
        settings.xcode = XcodebuildRunner.Target(container: "Voting.xcodeproj", scheme: "Voting", destination: "platform=macOS")
        let commands = RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: "{\"totalTestCount\": 4}") }
            if let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            let directory = call.arguments.firstIndex(of: "-derivedDataPath").map { call.arguments[$0 + 1] } ?? ""
            let copy = URL(fileURLWithPath: directory).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("package")
            let source = (try? String(contentsOf: copy.appendingPathComponent("Sources/Voting/Voting.swift"), encoding: .utf8)) ?? ""
            let killed = call.arguments.first == "test-without-building" && source.contains("age < 18")
            return .finished(killed ? 65 : 0, output: killed ? "** TEST FAILED **" : "** BUILD SUCCEEDED **")
        }
        let status = MutationRun(options: settings, discoverer: FakeDiscoverer(), runner: commands) { [weak self] in self?.log.append($0) }.run()
        XCTAssertEqual(status, MutationRun.Status.completed, log.joined(separator: "\n"))
        let summary = try String(contentsOf: output.appendingPathComponent("summary.txt"), encoding: .utf8)
        XCTAssertTrue(summary.contains("Mutation score: 50.0%"), summary)
        let actions = commands.calls.compactMap { $0.arguments.first }
        XCTAssertEqual(actions.filter { $0 == "build-for-testing" }.count, 3, "The baseline's build and one for each of the 2 mutants")
        let tests = commands.calls.filter { $0.arguments.first == "test-without-building" }
        XCTAssertEqual(tests.first?.environment["TEST_RUNNER_CUCUMBER_COVERAGE"], "YES", "The first baseline run measures the scenarios")
        let mutants = tests.filter { $0.environment["TEST_RUNNER_CUCUMBERSWIFT_MUTANT"] != nil }
        XCTAssertEqual(mutants.count, 2)
        XCTAssertTrue(mutants.allSatisfy { $0.environment["TEST_RUNNER_CUCUMBER_COVERAGE"] == "NO" })
    }

    func testAnXcodebuildRunThatRanNoTestStopsTheRun() throws {
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Voting.xcodeproj"), withIntermediateDirectories: true)
        var settings = options()
        settings.xcode = XcodebuildRunner.Target(container: "Voting.xcodeproj", scheme: "Voting", destination: "platform=macOS")
        // Xcode says TEST SUCCEEDED, and its result bundle counts 0 tests.
        let commands = RecordingCommands { call in
            if call.arguments.first == "xcresulttool" { return .finished(0, output: "{\"totalTestCount\": 0}") }
            if let index = call.arguments.firstIndex(of: "-resultBundlePath") {
                try? FileManager.default.createDirectory(atPath: call.arguments[index + 1], withIntermediateDirectories: true)
            }
            return .finished(0, output: "** TEST SUCCEEDED **")
        }
        let status = MutationRun(options: settings, discoverer: FakeDiscoverer(), runner: commands) { [weak self] in self?.log.append($0) }.run()
        XCTAssertEqual(status, MutationRun.Status.baselineFailed)
        XCTAssertTrue(log.joined().contains("ran no test"), log.joined())
    }

    func testRefusesAFolderWithoutTheProject() {
        var settings = options()
        settings.xcode = XcodebuildRunner.Target(container: "Missing.xcodeproj", scheme: "Voting", destination: "platform=macOS")
        let status = MutationRun(options: settings, discoverer: FakeDiscoverer(), runner: RecordingCommands()) { [weak self] in self?.log.append($0) }.run()
        XCTAssertEqual(status, MutationRun.Status.failed)
        XCTAssertTrue(log.joined().contains("no Missing.xcodeproj"), log.joined())
    }
}
#endif
