//
//  MergedCoverage.swift
//  CucumberSwiftCoverageMerge
//
//  The public face of the merge: what cucumberswift-coverage-merge and the mutation testing tool import.
//

import Foundation

/// The scenarios of several runs, merged as one run, and what each one ran.
public struct MergedCoverage {
    /// A region of a measured function.
    public struct Region: Hashable, Sendable {
        /// The function's number in ``MergedCoverage/functions``.
        public let function: Int
        /// The region's place in the function, from 0.
        public let index: Int
    }

    /// A function that the runs measured.
    public struct Function: Equatable, Sendable {
        public let name: String
        public let file: String
        public let line: Int
        /// How many regions the function has.
        public let regionCount: Int
        /// The number of the function's first region in the merged numbering: its regions are
        /// `firstRegion..<firstRegion + regionCount`.
        public let firstRegion: Int
        /// Where each region is, in region order: first line, first column, last line, last column, with columns
        /// counted in UTF-8 bytes from 1. Nil when the runs' manifests don't record them.
        public let spans: [[Int]]?
    }

    /// How the regions of several runs of one build are numbered as one.
    public struct Renumbering: Equatable, Sendable {
        public let functions: [Function]
        /// For each run, in the order of ``runFolders``, the merged number of each region, by its number in the run.
        public let localToGlobal: [[Int]]
        /// The run folders, in order.
        public let runFolders: [URL]
    }

    /// Reads the manifests in `folders`, as ``init(folders:)`` does, and numbers the regions of the functions that
    /// the runs measured again, as one build, without scoring them. Throws when there is no run, or when two runs
    /// are of different builds.
    public static func renumbering(ofRunsIn folders: [URL]) throws -> Renumbering {
        let runs = try CoverageMerge.read(folders)
        let renumbering = try CoverageMerge.renumber(runs.map { $0.manifest.measured ?? [] })
        return Renumbering(functions: function(list: renumbering.functions, spans: renumbering.spans),
                           localToGlobal: renumbering.maps,
                           runFolders: runs.map(\.folder))
    }

    private static func function(list: [MeasuredCode.Function], spans: [[[Int]]?]) -> [Function] {
        zip(list, spans).map { function, spans in
            Function(name: function.name, file: function.file, line: function.line, regionCount: function.regions.count,
                     firstRegion: function.regions.lowerBound, spans: spans)
        }
    }

    /// A scenario that ran, once, whichever runs it ran in.
    public struct Scenario: Equatable, Sendable {
        /// The feature file's URI, by the part that is the same in every run.
        public let feature: String
        public let featureName: String
        public let line: Int
        public let name: String
        public let tags: [String]
        public let duration: TimeInterval
        /// The regions the scenario ran.
        public let ran: Set<Region>
    }

    public let functions: [Function]
    public let scenarios: [Scenario]
    private let merge: CoverageMerge

    /// Merges the runs in `folders`: run folders, `run-<id>`, or coverage folders that hold them. Throws when
    /// there is none, or the runs can't be merged, with a message that says why.
    public init(folders: [URL]) throws {
        let merge = try CoverageMerge(runs: CoverageMerge.read(folders))
        self.merge = merge
        let code = merge.code
        let renumbering = try CoverageMerge.renumber(merge.runs.map { $0.manifest.measured ?? [] })
        functions = Self.function(list: renumbering.functions, spans: renumbering.spans)
        let starts = code.functions.map(\.regions.lowerBound)
        scenarios = merge.scenarios.map { merged in
            let scenario = merged.scenario
            let ran = scenario.regions.compactMap { number -> Region? in
                guard let function = code.functions.firstIndex(where: { $0.regions.contains(number) }) else { return nil }
                return Region(function: function, index: number - starts[function])
            }
            return Scenario(feature: merged.feature,
                            featureName: merged.featureName,
                            line: scenario.line,
                            name: scenario.name,
                            tags: scenario.tags,
                            duration: scenario.duration,
                            ran: Set(ran))
        }
    }

    /// Prints each feature's and each Rule's scores and issues as a run prints them. Returns whether an issue is
    /// an error.
    public func report(output: (String) -> Void) -> Bool {
        merge.report(output: output)
    }
}
