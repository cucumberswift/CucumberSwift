//
//  TestSupport.swift
//  CucumberSwiftMutationTests
//

import Foundation
import XCTest
@testable import CucumberSwiftMutation

/// A command runner that runs nothing: `handler` decides what each command returns, and every command is recorded.
final class FakeRunner: CommandRunning, @unchecked Sendable {
    struct Call: Equatable {
        let arguments: [String]
        let directory: URL
        let environment: [String: String]
        let timeout: TimeInterval?
    }

    private let lock = NSLock()
    private var recorded = [Call]()
    private let handler: (Call) -> CommandResult

    var calls: [Call] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    init(handler: @escaping (Call) -> CommandResult) {
        self.handler = handler
    }

    func run(
        _ executable: String,
        _ arguments: [String],
        in directory: URL,
        environment: [String: String],
        timeout: TimeInterval?
    ) -> CommandResult {
        let call = Call(arguments: arguments, directory: directory, environment: environment, timeout: timeout)
        lock.lock()
        recorded.append(call)
        lock.unlock()
        // The commands that copy and delete are real; only `swift` is replaced.
        if executable.hasSuffix("/swift") || executable == "swift" { return handler(call) }
        return ProcessRunner().run(executable, arguments, in: directory, environment: environment, timeout: timeout)
    }
}

/// Finds mutants without swift-syntax: the text `>=` becomes `>` and `<`, at each place it appears.
struct FakeDiscoverer: MutantDiscovering {
    /// The replacements whose mutants a comment marks as ignored, with the comment's text.
    var ignoring = [String: String]()

    func mutants(inFiles files: [URL], relativeTo root: URL) throws -> [Mutant] {
        var found = [Mutant]()
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let relative = String(file.resolvingSymlinksInPath().path.dropFirst(root.resolvingSymlinksInPath().path.count + 1))
            guard let range = source.range(of: ">=") else { continue }
            let offset = source.utf8.distance(from: source.utf8.startIndex, to: range.lowerBound)
            for replacement in [">", "<"] {
                var mutant = Mutant.fixture(file: relative, original: ">=", replacement: replacement, offset: offset)
                mutant.ignoredReason = ignoring[replacement]
                found.append(mutant)
            }
        }
        return found
    }
}

class TemporaryFolderTestCase: XCTestCase {
    var folder: URL!

    override func setUpWithError() throws {
        folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mutation-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDown() {
        _ = ProcessRunner().run("/bin/chmod", ["-R", "u+w", folder.path], in: folder.deletingLastPathComponent(), environment: [:], timeout: 30)
        try? FileManager.default.removeItem(at: folder)
    }

    /// A package with one source file, a test file, a build folder and a `.git` folder.
    func makePackage(named name: String = "Voting", source: String = "public func canVote(age: Int) -> Bool { age >= 18 }\n") throws -> URL {
        let root = folder.appendingPathComponent(name)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: root.appendingPathComponent("Sources/Voting"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: root.appendingPathComponent("Tests/VotingTests"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: root.appendingPathComponent(".build/debug"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try "// swift-tools-version:5.9\n".write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try source.write(to: root.appendingPathComponent("Sources/Voting/Voting.swift"), atomically: true, encoding: .utf8)
        try "// tests\n".write(to: root.appendingPathComponent("Tests/VotingTests/VotingTests.swift"), atomically: true, encoding: .utf8)
        try "artifact".write(to: root.appendingPathComponent(".build/debug/artifact"), atomically: true, encoding: .utf8)
        try "ref".write(to: root.appendingPathComponent(".git/HEAD"), atomically: true, encoding: .utf8)
        return root
    }
}

extension CommandResult {
    static func finished(_ status: Int32, output: String = "", timedOut: Bool = false, duration: TimeInterval = 1) -> CommandResult {
        CommandResult(status: status, output: output, timedOut: timedOut, duration: duration)
    }
}

extension Mutant {
    /// A mutant on line 1 of `file`, with its place worked out from `offset`.
    static func fixture(
        id: Int = 0,
        file: String = "Sources/Voting/Voting.swift",
        original: String = ">=",
        replacement: String = ">",
        offset: Int = 44,
        mutator: String = "RelationalOperator",
        line: Int = 1,
        column: Int? = nil
    ) -> Mutant {
        Mutant(
            id: id,
            file: file,
            line: line,
            column: column ?? offset + 1,
            endLine: line,
            endColumn: (column ?? offset + 1) + original.utf8.count,
            offset: offset,
            length: original.utf8.count,
            original: original,
            replacement: replacement,
            mutator: mutator
        )
    }
}

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}

final class CopyListing: @unchecked Sendable {
    var names = [String]()
}

/// A runner that runs nothing and counts what the run asks of it.
final class SpyRunner: TestRunner, @unchecked Sendable {
    private let prepared: Counter
    private let cleaned: Counter
    private let buildStatus: Bool
    private let testsRun: Int
    private let prepareFails: Bool
    let excludedFromCopy: [String]
    var onPrepare: (URL) -> Void = { _ in }

    init(prepared: Counter, cleaned: Counter, buildStatus: Bool = true, testsRun: Int = 3, prepareFails: Bool = false, excluded: [String] = []) {
        self.prepared = prepared
        self.cleaned = cleaned
        self.buildStatus = buildStatus
        self.testsRun = testsRun
        self.prepareFails = prepareFails
        excludedFromCopy = excluded
    }

    struct PrepareFailure: Error, CustomStringConvertible {
        let description = "cannot prepare"
    }

    func prepare(copy: URL) throws {
        prepared.increment()
        onPrepare(copy)
        if prepareFails { throw PrepareFailure() }
    }

    func build(in copy: URL, timeout: TimeInterval?) -> BuildResult {
        BuildResult(succeeded: buildStatus, duration: 1)
    }

    func test(in copy: URL, request: TestRequest) -> TestRun {
        TestRun(status: 0, duration: 1, testsRun: testsRun)
    }

    func cleanUp(copy: URL) {
        cleaned.increment()
    }
}
