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

    init(handler: @escaping (Call) -> CommandResult) {
        self.handler = handler
    }

    var calls: [Call] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func run(_ executable: String, _ arguments: [String], in directory: URL, environment: [String: String], timeout: TimeInterval?) -> CommandResult {
        let call = Call(arguments: arguments, directory: directory, environment: environment, timeout: timeout)
        lock.lock()
        recorded.append(call)
        lock.unlock()
        // The commands that copy and delete are real; only `swift` is replaced.
        if executable.hasSuffix("/swift") || executable == "swift" { return handler(call) }
        return ProcessRunner().run(executable, arguments, in: directory, environment: environment, timeout: timeout)
    }
}

extension CommandResult {
    static func finished(_ status: Int32, output: String = "", timedOut: Bool = false, duration: TimeInterval = 1) -> CommandResult {
        CommandResult(status: status, output: output, timedOut: timedOut, duration: duration)
    }
}

/// Finds mutants without swift-syntax: the text `>=` becomes `>` and `<`, at each place it appears.
struct FakeDiscoverer: MutantDiscovering {
    func mutants(inFiles files: [URL], relativeTo root: URL) throws -> [Mutant] {
        var found = [Mutant]()
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let relative = String(file.resolvingSymlinksInPath().path.dropFirst(root.resolvingSymlinksInPath().path.count + 1))
            guard let range = source.range(of: ">=") else { continue }
            let offset = source.utf8.distance(from: source.utf8.startIndex, to: range.lowerBound)
            for replacement in [">", "<"] {
                found.append(Mutant(id: 0, file: relative, line: 1, column: offset + 1, endLine: 1, endColumn: offset + 3,
                                    offset: offset, length: 2, original: ">=", replacement: replacement, mutator: "RelationalOperator"))
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
