//
//  MutationRunTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class MutationRunTests: TemporaryFolderTestCase {
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

    private func run(_ runner: FakeRunner, options: MutationOptions? = nil) -> Int32 {
        MutationRun(options: options ?? self.options(), discoverer: FakeDiscoverer(), runner: runner) { [unowned self] in log.append($0) }.run()
    }

    /// `swift build` always works. `swift test` runs `tests`, which sees the source the copy has at that moment.
    private func runner(tests: @escaping (String) -> CommandResult) -> FakeRunner {
        FakeRunner { call in
            if call.arguments.first == "build" { return .finished(0) }
            let source = (try? String(contentsOf: call.directory.appendingPathComponent("Sources/Voting/Voting.swift"), encoding: .utf8)) ?? ""
            let result = tests(source)
            // A run that prints no test count is one that ran no test: give each result the count a real run prints.
            return result.output.contains("Executed") ? result : CommandResult(status: result.status, output: result.output + "\nExecuted 3 tests, with 0 failures", timedOut: result.timedOut, duration: result.duration)
        }
    }

    func testKillsTheMutantThatBreaksATestAndKeepsTheOneThatNoTestNoticed() throws {
        // A test that checks age 5 and age 30, as the scenarios in the spike do, but not age 18.
        let fake = runner { source in source.contains("age < 18") ? .finished(1, output: "failed") : .finished(0) }
        XCTAssertEqual(run(fake), MutationRun.Status.completed)
        let report = try String(contentsOf: output.appendingPathComponent("mutation-report.json"), encoding: .utf8)
        XCTAssertTrue(report.contains("\"status\" : \"Killed\""))
        XCTAssertTrue(report.contains("\"status\" : \"Survived\""))
        let summary = try String(contentsOf: output.appendingPathComponent("summary.txt"), encoding: .utf8)
        XCTAssertTrue(summary.contains("Mutation score: 50.0%"), summary)
        XCTAssertTrue(summary.contains("Voting.swift:1:"), summary)
    }

    func testTheOriginalPackageIsTheSameAfterTheRun() throws {
        let before = ProjectFingerprint.take(of: root)
        _ = run(runner { _ in .finished(1) })
        XCTAssertEqual(ProjectFingerprint.take(of: root), before)
        XCTAssertTrue(log.contains("The package is unchanged."), log.joined(separator: "\n"))
    }

    func testTheTestsSeeTheMutantInTheCopyAndNeverInTheOriginal() throws {
        var seen = [String]()
        let originalPath = root.appendingPathComponent("Sources/Voting/Voting.swift")
        let fake = runner { source in
            seen.append(source)
            // The original is not the file the tests run against.
            XCTAssertEqual(try? String(contentsOf: originalPath, encoding: .utf8), "public func canVote(age: Int) -> Bool { age >= 18 }\n")
            return .finished(0)
        }
        _ = run(fake)
        XCTAssertTrue(seen.contains { $0.contains("age > 18") })
        XCTAssertTrue(seen.contains { $0.contains("age < 18") })
        XCTAssertTrue(seen.contains { $0.contains("age >= 18") }, "The baseline runs the unchanged code")
    }

    func testTheCopyAndTheLockFileAreGoneAtTheEnd() throws {
        _ = run(runner { _ in .finished(0) })
        let work = (try? FileManager.default.contentsOfDirectory(atPath: folder.appendingPathComponent("work").path)) ?? []
        XCTAssertEqual(work, [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.appendingPathComponent("mutation.lock").path))
    }

    func testAFailingBaselineStopsBeforeAnyMutantRuns() {
        let fake = runner { _ in .finished(1, output: "XCTAssertEqual failed") }
        XCTAssertEqual(run(fake), MutationRun.Status.baselineFailed)
        XCTAssertEqual(fake.calls.filter { $0.arguments.first == "test" }.count, 1, "Only the first baseline run happens")
        XCTAssertTrue(log.joined().contains("fail without any change"))
    }

    func testABaselineThatFailsTheSecondTimeStopsToo() {
        var count = 0
        let fake = runner { _ in
            count += 1
            return count == 2 ? .finished(1) : .finished(0)
        }
        XCTAssertEqual(run(fake), MutationRun.Status.baselineFailed)
    }

    func testAPackageThatDoesNotBuildStopsTheRun() {
        let fake = FakeRunner { _ in .finished(1, output: "error: cannot find 'x'") }
        XCTAssertEqual(run(fake), MutationRun.Status.baselineFailed)
        XCTAssertTrue(log.joined().contains("doesn't build"))
    }

    func testAMutantThatDoesNotBuildIsNotCountedAndNotKilled() throws {
        let fake = FakeRunner { call in
            guard call.arguments.first == "build" else { return .finished(0, output: "Executed 3 tests") }
            let source = (try? String(contentsOf: call.directory.appendingPathComponent("Sources/Voting/Voting.swift"), encoding: .utf8)) ?? ""
            return source.contains("age < 18") ? .finished(1, output: "error") : .finished(0)
        }
        _ = run(fake)
        let summary = try String(contentsOf: output.appendingPathComponent("summary.txt"), encoding: .utf8)
        XCTAssertTrue(summary.contains("did not build 1"), summary)
        XCTAssertTrue(summary.contains("Mutation score: 0.0% (0 of 1"), summary)
    }

    func testATimeoutCountsAsDetected() throws {
        let fake = runner { source in source.contains("age < 18") ? .finished(15, timedOut: true) : .finished(0) }
        _ = run(fake)
        let summary = try String(contentsOf: output.appendingPathComponent("summary.txt"), encoding: .utf8)
        XCTAssertTrue(summary.contains("timed out 1"), summary)
        XCTAssertTrue(summary.contains("Mutation score: 50.0%"), summary)
    }

    func testTheTimeoutIsAMultipleOfTheBaselineWithAFloor() {
        let fake = runner { _ in .finished(0, duration: 20) }
        var settings = options()
        settings.minimumTimeout = 30
        _ = run(fake, options: settings)
        let timeouts = fake.calls.compactMap { $0.timeout }
        XCTAssertEqual(Set(timeouts), [60], "3 times the 20 s baseline; only the mutants' runs have a timeout")
    }

    func testMaxMutantsLimitsTheRun() {
        var settings = options()
        settings.maxMutants = 1
        let fake = runner { _ in .finished(0) }
        _ = run(fake, options: settings)
        XCTAssertEqual(fake.calls.filter { $0.environment["CUCUMBERSWIFT_MUTANT"] != nil }.count, 1)
    }

    func testDryRunListsTheMutantsAndRunsNoTests() {
        var settings = options()
        settings.dryRun = true
        let fake = runner { _ in .finished(0) }
        XCTAssertEqual(run(fake, options: settings), MutationRun.Status.completed)
        XCTAssertTrue(fake.calls.filter { ["build", "test"].contains($0.arguments.first) }.isEmpty)
        XCTAssertTrue(log.contains { $0.contains("RelationalOperator >= → >") })
    }

    func testEachMutantGetsItsOwnReportPathAndNumber() {
        let fake = runner { _ in .finished(0) }
        _ = run(fake)
        let mutantCalls = fake.calls.filter { $0.environment["CUCUMBERSWIFT_MUTANT"] != nil }
        XCTAssertEqual(mutantCalls.map { $0.environment["CUCUMBERSWIFT_MUTANT"] }, ["1", "2"])
        XCTAssertEqual(mutantCalls.map { URL(fileURLWithPath: $0.environment["CUCUMBER_REPORT_PATH"] ?? "").lastPathComponent }, ["mutant-1.json", "mutant-2.json"])
    }

    func testAnnotatesTheCucumberReportThatTheTestsWrote() throws {
        // Write the report where the run says to, as CucumberSwift's runners do: the Then step fails for the `<` mutant.
        let fake = FakeRunner { call in
            if call.arguments.first == "build" { return .finished(0) }
            let source = (try? String(contentsOf: call.directory.appendingPathComponent("Sources/Voting/Voting.swift"), encoding: .utf8)) ?? ""
            let killed = source.contains("age < 18")
            if let path = call.environment["CUCUMBER_REPORT_PATH"] {
                let json = """
                [{"name":"Voting","elements":[{"name":"An adult can vote","steps":[
                  {"keyword":"Given ","name":"a person aged 30","result":{"status":"passed"}},
                  {"keyword":"Then ","name":"the person can vote","result":{"status":"\(killed ? "failed" : "passed")"}}]}]}]
                """
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: path).deletingLastPathComponent(), withIntermediateDirectories: true)
                try? json.write(toFile: path, atomically: true, encoding: .utf8)
            }
            return .finished(killed ? 1 : 0, output: "Executed 4 tests")
        }
        _ = run(fake)
        let killedReport = try String(contentsOf: output.appendingPathComponent("cucumber-mutant-1.json"), encoding: .utf8)
        XCTAssertTrue(killedReport.contains("embeddings"), killedReport)
        let stryker = try String(contentsOf: output.appendingPathComponent("mutation-report.json"), encoding: .utf8)
        XCTAssertTrue(stryker.contains("An adult can vote :: Then the person can vote"), "The killing step is named in the report")
        let survivorReport = try String(contentsOf: output.appendingPathComponent("cucumber-mutant-2.json"), encoding: .utf8)
        XCTAssertTrue(survivorReport.contains("embeddings"), survivorReport)
    }

    func testTestsThatRanNothingStopTheRunInsteadOfCountingAsPassed() {
        // `swift test` exits 0 when it finds no test, which would make every mutant survive.
        let fake = FakeRunner { call in
            call.arguments.first == "build" ? .finished(0) : .finished(0, output: "Executed 0 tests, with 0 failures\nTest run with 0 tests in 0 suites passed")
        }
        XCTAssertEqual(run(fake), MutationRun.Status.baselineFailed)
        XCTAssertTrue(log.joined().contains("ran no test"))
    }

    func testTestsThatRanNothingForOneMutantStopTheRun() {
        var tests = 0
        let fake = FakeRunner { call in
            guard call.arguments.first == "test" else { return .finished(0) }
            tests += 1
            // The two baseline runs run tests; the first mutant's run finds none.
            return tests <= 2 ? .finished(0, output: "Executed 5 tests, with 0 failures") : .finished(0, output: "Test run with 0 tests in 0 suites passed")
        }
        XCTAssertEqual(run(fake), MutationRun.Status.failed)
        XCTAssertTrue(log.joined().contains("ran no test"), log.joined())
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.appendingPathComponent("mutation-report.json").path))
    }

    func testRefusesAFolderThatIsNotAPackage() {
        var settings = options()
        settings.root = folder
        XCTAssertEqual(run(runner { _ in .finished(0) }, options: settings), MutationRun.Status.failed)
        XCTAssertTrue(log.joined().contains("no Package.swift"))
    }

    func testRemovesTheCopyOfAKilledRunBeforeStarting() throws {
        let leftBehind = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: output)
        // The recorded process is the test process itself, which is alive, so it counts as another active run...
        let alive = leftBehind.folder
        XCTAssertTrue(FileManager.default.fileExists(atPath: alive.path))
        // ...so rewrite the lock as a process that is gone.
        try JSONEncoder().encode(WorkFolder.Lock(pid: 99_999_999, folder: alive.path)).write(to: output.appendingPathComponent("mutation.lock"))
        _ = run(runner { _ in .finished(0) })
        XCTAssertFalse(FileManager.default.fileExists(atPath: alive.path))
        XCTAssertTrue(log.contains { $0.hasPrefix("Removed the copy that an earlier run left behind") })
    }
}
