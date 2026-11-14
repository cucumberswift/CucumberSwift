//
//  ScenarioCoverage.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import CucumberSwiftCoverageMerge
import Foundation

/// The code each scenario ran in the unmutated copy, read from the coverage folders that CucumberSwift writes with
/// `CUCUMBER_COVERAGE` on, as `cucumberswift coverage merge` reads them. A mutant whose code no scenario ran can't be
/// detected by any scenario, so the run doesn't test it.
public struct ScenarioCoverage: Equatable, Sendable {
    /// Why the coverage can't tell which scenarios ran a mutant's code.
    public enum ReadError: Error, Equatable, CustomStringConvertible {
        /// The run measured functions, but recorded no places for their regions: a CucumberSwift older than the tool.
        case noRegionPlaces(file: String)
        /// A test process of the run left a run folder without its manifest, so the code its scenarios ran is unknown.
        case incompleteRun(folder: String)

        public var description: String {
            switch self {
                case .noRegionPlaces(let file):
                    return "the coverage has no places for the code regions of \(file). The package's CucumberSwift may be older than the tool."
                case .incompleteRun(let folder):
                    return "\(folder) has no manifest.json, so the coverage of its scenarios is missing."
            }
        }
    }

    public struct Region: Codable, Hashable, Sendable {
        public let file: String
        public let lineStart: Int
        public let columnStart: Int
        public let lineEnd: Int
        public let columnEnd: Int

        /// The region's size, lines first and then columns, to find the innermost region at a position.
        var size: Int { (lineEnd - lineStart) * 10_000 + max(0, columnEnd - columnStart) }

        public init(file: String, lineStart: Int, columnStart: Int, lineEnd: Int, columnEnd: Int) {
            self.file = file
            self.lineStart = lineStart
            self.columnStart = columnStart
            self.lineEnd = lineEnd
            self.columnEnd = columnEnd
        }

        /// Whether the region holds `line` at `column`, with both 1-based and counted in UTF-8 bytes.
        func contains(line: Int, column: Int) -> Bool {
            guard lineStart <= line, line <= lineEnd else { return false }
            if line == lineStart, columnStart > 0, column < columnStart { return false }
            if line == lineEnd, columnEnd > 0, column > columnEnd { return false }
            return true
        }
    }

    public struct Scenario: Codable, Equatable, Sendable {
        public let feature: String
        public let line: Int
        public let name: String
        /// The numbers of the regions the scenario ran: places in ``ScenarioCoverage/regions``.
        public let ran: [Int]

        public init(feature: String, line: Int, name: String, ran: [Int]) {
            self.feature = feature
            self.line = line
            self.name = name
            self.ran = ran
        }
    }

    public let regions: [Region]
    public let scenarios: [Scenario]

    /// The coverage of the runs under `folder`, merged as `cucumberswift coverage merge` merges them, or nil when
    /// there is no run there, or the runs measured no code. A test run that has several test bundles, as an Xcode scheme can,
    /// or several test processes, as `swift test` does for XCTest and Swift Testing, writes a run folder for each. The
    /// merge numbers each function's regions once, whichever runs measured it. Throws when a run folder has no
    /// manifest, the runs can't be merged, or they don't record where their regions are.
    public static func read(inRunsUnder folder: URL) throws -> ScenarioCoverage? {
        let runs = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        let runFolders = runs.filter { $0.lastPathComponent.hasPrefix("run-") }.sorted { $0.path < $1.path }
        guard !runFolders.isEmpty else { return nil }
        // Each folder is a test process of this run, so one without a manifest lost the coverage of its scenarios. The
        // other runs alone would make a mutant that only its scenarios ran look like code that no scenario runs.
        if let incomplete = runFolders.first(where: { !FileManager.default.fileExists(atPath: $0.appendingPathComponent("manifest.json").path) }) {
            throw ReadError.incompleteRun(folder: incomplete.path)
        }
        let merged = try MergedCoverage(folders: [folder])
        guard !merged.functions.isEmpty else { return nil }
        var regions = [Region]()
        var firstRegion = [Int]()
        for function in merged.functions {
            guard function.spans.count == function.regionCount else { throw ReadError.noRegionPlaces(file: function.file) }
            firstRegion.append(regions.count)
            regions += function.spans.map {
                Region(file: function.file, lineStart: $0.lineStart, columnStart: $0.columnStart, lineEnd: $0.lineEnd, columnEnd: $0.columnEnd)
            }
        }
        let scenarios = merged.scenarios.map { scenario in
            Scenario(feature: scenario.feature,
                     line: scenario.line,
                     name: scenario.name,
                     ran: scenario.ran.map { firstRegion[$0.function] + $0.index }.sorted())
        }
        return ScenarioCoverage(regions: regions, scenarios: scenarios)
    }

    public init(regions: [Region], scenarios: [Scenario]) {
        self.regions = regions
        self.scenarios = scenarios
    }

    /// The scenarios that ran the code at `mutant`'s place: the ones that ran the innermost measured region holding it.
    /// Empty when no scenario ran it, or when the place isn't in measured code at all.
    public func scenarios(running mutant: Mutant) -> [ScenarioID] {
        let holding = regions.indices.filter { index in
            let region = regions[index]
            return (region.file == mutant.file || region.file.hasSuffix("/" + mutant.file))
                && region.contains(line: mutant.line, column: mutant.column)
        }
        guard let smallest = holding.map({ regions[$0].size }).min() else { return [] }
        let innermost = Set(holding.filter { regions[$0].size == smallest })
        return scenarios.filter { scenario in scenario.ran.contains { innermost.contains($0) } }
            .map { ScenarioID(uri: $0.feature, line: $0.line, name: $0.name) }
    }
}
#endif
