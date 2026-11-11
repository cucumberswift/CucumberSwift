//
//  ScenarioCoverage.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import Foundation

/// The code each scenario ran in the unmutated copy, read from the `regions.json` that CucumberSwift writes with
/// `CUCUMBER_COVERAGE_REGIONS` on. A mutant whose code no scenario ran can't be detected by any scenario, so the
/// run doesn't test it.
public struct ScenarioCoverage: Equatable, Sendable {
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

    private struct File: Codable {
        let version: Int
        let regions: [Region]
        let scenarios: [Scenario]
    }

    public let regions: [Region]
    public let scenarios: [Scenario]

    /// The coverage in the `regions.json` of every run folder under `folder`, merged, or nil when there is none. A test
    /// run that has several test bundles, as an Xcode scheme can, writes a run folder for each bundle's process. Each
    /// run numbers its own regions, so the merge numbers a region again by its place, and keeps one of the regions that
    /// two runs share, which both numbered.
    public static func read(inRunsUnder folder: URL) -> ScenarioCoverage? {
        let runs = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        var regions = [Region]()
        var numbers = [Region: Int]()
        var scenarios = [Scenario]()
        var found = false
        for run in runs.sorted(by: { $0.path < $1.path }) where run.lastPathComponent.hasPrefix("run-") {
            guard let data = try? Data(contentsOf: run.appendingPathComponent("regions.json")),
                  let file = try? JSONDecoder().decode(File.self, from: data), file.version == 1 else { continue }
            found = true
            let renumbered = file.regions.map { region -> Int in
                if let number = numbers[region] { return number }
                regions.append(region)
                numbers[region] = regions.count - 1
                return regions.count - 1
            }
            scenarios += file.scenarios.map { scenario in
                let ran = scenario.ran.compactMap { renumbered.indices.contains($0) ? renumbered[$0] : nil }
                return Scenario(feature: scenario.feature, line: scenario.line, name: scenario.name, ran: ran)
            }
        }
        return found ? ScenarioCoverage(regions: regions, scenarios: scenarios) : nil
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
