//
//  CoverageRunFixture.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import Foundation
@testable import CucumberSwiftCoverageMerge

/// A coverage run folder, `run-<name>`, as CucumberSwift writes it with `CUCUMBER_COVERAGE` on: its `manifest.json`.
struct CoverageRunFixture {
    /// A function the run measured, and where each of its regions is: `[lineStart, columnStart, lineEnd, columnEnd]`.
    /// Nil `spans` is a run from a CucumberSwift that didn't record them.
    struct Function {
        var name: String
        var file: String
        var spans: [[Int]]?
        var regionCount: Int?
    }

    /// A scenario, and the regions it ran, numbered in the run from 0 across the functions in their order.
    struct Scenario {
        var feature: String
        var line: Int
        var name: String
        var ran: [Int]
    }

    var binary = "VotingTests"
    var functions: [Function]
    var scenarios: [Scenario]

    func write(named name: String, in folder: URL) throws {
        let measured = functions.map { function in
            CoverageManifest.MeasuredFunction(binary: binary,
                                              name: function.name,
                                              readableName: function.name,
                                              file: function.file,
                                              line: function.spans?.first?.first ?? 1,
                                              regions: function.regionCount ?? function.spans?.count ?? 0,
                                              spans: function.spans)
        }
        let records = scenarios.map { scenario in
            CoverageManifest.ScenarioRecord(feature: scenario.feature,
                                            featureName: "Voting",
                                            line: scenario.line,
                                            name: scenario.name,
                                            tags: [],
                                            profiles: [],
                                            duration: 0.1,
                                            featureLine: 1,
                                            issueFile: nil,
                                            coverage: .init(regions: scenario.ran,
                                                            backgroundRegions: [],
                                                            steps: [],
                                                            group: "line \(scenario.line)",
                                                            rule: nil,
                                                            ruleLine: nil))
        }
        let manifest = CoverageManifest(run: name,
                                        startDate: Date(),
                                        binaries: [],
                                        scenarios: records,
                                        measured: measured,
                                        settings: .init(CoverageSettings()))
        let run = folder.appendingPathComponent("run-\(name)")
        try FileManager.default.createDirectory(at: run, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(to: run.appendingPathComponent("manifest.json"))
    }
}
#endif
