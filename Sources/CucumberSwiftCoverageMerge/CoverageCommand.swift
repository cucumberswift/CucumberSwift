//
//  CoverageCommand.swift
//  CucumberSwiftCoverageMerge
//
//  `cucumberswift coverage …`, which the cucumberswift tool's main.swift calls.
//

import Foundation

/// `cucumberswift coverage …`: what the tool does with the coverage that runs write.
public enum CoverageCommand {
    public static let usage = "usage: cucumberswift coverage merge <coverage folder or run folder>…"

    /// Runs the subcommand named by `arguments`, which follow `coverage`, and returns the exit status: 0, 1 when a
    /// score reaches an error level, 2 when the arguments or the runs can't be used. A missing or unknown
    /// subcommand prints the usage and returns 2.
    public static func run(arguments: [String]) -> Int32 {
        guard arguments.first == "merge" else {
            print(usage)
            return arguments.contains { ["-h", "--help"].contains($0) } ? 0 : 2
        }
        return merge(arguments: Array(arguments.dropFirst()))
    }

    /// Scores the scenarios of several runs as one run: the workers of a parallel run, or the shards of a suite.
    /// Each folder is a run's folder, run-<id>, or a coverage folder that holds them, as CUCUMBER_COVERAGE_PATH
    /// sets it. Prints each feature's and each Rule's scores, and each issue as `file:line: warning: message`,
    /// with the levels the runs checked.
    private static func merge(arguments: [String]) -> Int32 {
        guard !arguments.isEmpty, !arguments.contains(where: { ["-h", "--help"].contains($0) }) else {
            print(usage)
            return arguments.isEmpty ? 2 : 0
        }
        do {
            let folders = arguments.map { URL(fileURLWithPath: $0, isDirectory: true) }
            return try MergedCoverage(folders: folders).report { print($0) } ? 1 : 0
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            return 2
        }
    }
}
