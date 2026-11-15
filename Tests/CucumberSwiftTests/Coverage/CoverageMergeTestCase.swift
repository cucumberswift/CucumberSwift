//
//  CoverageMergeTestCase.swift
//  CucumberSwiftTests
//
//  What the tests of the coverage merge share: runs of a small suite, as manifests, and what a run of all its
//  scenarios one at a time scores (#515).
//

import Foundation
import XCTest
@testable import CucumberSwift

class CoverageMergeTestCase: XCTestCase {
    /// A function of the code under test: its key in every run, and its regions.
    struct Function {
        let name: String
        let regions: Int
    }

    /// A scenario, and the regions it ran, by function and region within it.
    struct Ran {
        let line: Int
        let name: String
        var rule: ScenarioRule?
        var group: String?
        var background = [(String, Int)]()
        var steps = [(line: Int, regions: [(String, Int)])]()
        var duration = 0.25

        var regions: [(String, Int)] { background + steps.flatMap(\.regions) }
    }

    let functions = [Function(name: "add", regions: 2), Function(name: "classify", regions: 4), Function(name: "unused", regions: 3)]
    let feature = "file:///Users/me/Library/Developer/CoreSimulator/Devices/A/App.app/PlugIns/MyTests.xctest/Features/Arithmetic.feature"
    let issueFile = "file:///src/Arithmetic.feature"
    var folder = FileManager.default.temporaryDirectory

    /// Five scenarios of one feature: three outside a Rule, and two in a Rule.
    var scenarios: [Ran] {
        let rule = ScenarioRule(title: "Naming numbers", line: 20)
        return [
            Ran(line: 4, name: "Adding", background: [("classify", 0)], steps: [(5, [("add", 0)])]),
            Ran(line: 8, name: "Adding again", background: [("classify", 0)], steps: [(9, [("add", 0)])]),
            Ran(line: 12, name: "Adding more", background: [("classify", 0)], steps: [(13, [("add", 1)])]),
            Ran(line: 23, name: "Naming seven", rule: rule, group: "24", steps: [(24, [("classify", 0), ("classify", 1)])]),
            Ran(line: 30, name: "Naming eight", rule: rule, group: "24", steps: [(24, [("classify", 0), ("classify", 2)])])
        ]
    }

    override func setUpWithError() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CoverageMergeTests-\(UUID().uuidString)")
        self.folder = folder
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
    }

    /// The manifest functions of `order`, which numbers their regions in that order.
    func measured(_ order: [Function], spans: Bool = true) -> [CoverageManifest.MeasuredFunction] {
        order.map { function in
            // Where a function is doesn't depend on the order a run lists it in.
            let first = 10 * ((functions.firstIndex { $0.name == function.name } ?? 0) + 1)
            return CoverageManifest.MeasuredFunction(binary: "MyTests",
                                                     name: "$s5Calc\(function.name)",
                                                     readableName: "Calc.\(function.name)()",
                                                     file: "/src/Calc.swift",
                                                     line: first,
                                                     regions: function.regions,
                                                     spans: spans ? (0..<function.regions).map { [first + $0, 1, first + $0, 9] } : nil)
        }
    }

    /// The run's manifest, which numbers the functions' regions in the order `order` lists them.
    func manifest(_ scenarios: [Ran],
                  order: [Function],
                  settings: CoverageSettings = CoverageSettings(),
                  uri: String? = nil) -> CoverageManifest {
        var first = [String: Int]()
        var next = 0
        for function in order {
            first[function.name] = next
            next += function.regions
        }
        func numbers(_ regions: [(String, Int)]) -> [Int] {
            regions.compactMap { name, index in first[name].map { $0 + index } }.sorted()
        }
        let records = scenarios.map { ran in
            CoverageManifest.ScenarioRecord(feature: uri ?? feature,
                                            featureName: "Arithmetic",
                                            line: ran.line,
                                            name: ran.name,
                                            tags: [],
                                            profiles: [],
                                            duration: ran.duration,
                                            featureLine: 1,
                                            issueFile: issueFile,
                                            coverage: .init(regions: numbers(ran.regions),
                                                            backgroundRegions: numbers(ran.background),
                                                            steps: ran.steps.map { .init(line: $0.line, regions: numbers($0.regions)) },
                                                            group: ran.group ?? "line \(ran.line)",
                                                            rule: ran.rule?.title,
                                                            ruleLine: ran.rule?.line))
        }
        return CoverageManifest(run: UUID().uuidString,
                                startDate: Date(),
                                binaries: [],
                                scenarios: records,
                                scoresProblem: "parallel testing",
                                measured: measured(order, spans: false),
                                settings: .init(settings))
    }

    /// A run of `manifest`, in the folder `path`.
    func run(_ manifest: CoverageManifest, at path: String? = nil) -> CoverageMerge.Run {
        CoverageMerge.Run(folder: path.map { URL(fileURLWithPath: $0) } ?? folder, manifest: manifest)
    }

    /// The parts that a run of all `scenarios`, one at a time, scores, as the recorder scores them.
    func serialParts(_ scenarios: [Ran], settings: CoverageSettings = CoverageSettings()) -> [CoverageScores.Part] {
        var first = [String: Int]()
        var measured = [MeasuredCode.Function]()
        for (index, function) in functions.enumerated() {
            let start = measured.last?.regions.upperBound ?? 0
            first[function.name] = start
            measured.append(.init(name: "Calc.\(function.name)()",
                                  file: "/src/Calc.swift",
                                  line: 10 * (index + 1),
                                  regions: start..<start + function.regions))
        }
        func numbers(_ regions: [(String, Int)]) -> Set<Int> {
            Set(regions.compactMap { name, index in first[name].map { $0 + index } })
        }
        let ran = scenarios.map { ran -> (rule: ScenarioRule?, scenario: CoverageScores.Scenario) in
            let scenario = CoverageScores.Scenario(name: ran.name,
                                                   line: ran.line,
                                                   tags: [],
                                                   duration: ran.duration,
                                                   regions: numbers(ran.regions),
                                                   group: ran.group)
                .with(backgroundRegions: numbers(ran.background))
                .with(steps: ran.steps.map { CoverageScores.StepRun(line: $0.line, regions: numbers($0.regions)) })
            return (ran.rule, scenario)
        }
        return CoverageScores.parts(of: ran, code: MeasuredCode(functions: measured), isRedundancy: settings.isRedundancy)
    }
}
