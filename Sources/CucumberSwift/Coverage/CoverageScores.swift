//
//  CoverageScores.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// The code that coverage measures, as numbered regions, each in one function. A scenario's coverage is
/// the set of region numbers it ran.
struct MeasuredCode: Equatable {
    struct Function: Equatable {
        let name: String
        let file: String
        let line: Int
        /// The function's regions' numbers.
        let regions: Range<Int>
    }

    /// CucumberSwift's own package folder, whose code is never yours, wherever the package is: in
    /// `checkouts`, or at a local path.
    static let cucumberSwiftFolder: String = {
        // This file is at Sources/<module>/Coverage/ in the package.
        var folder = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0..<4 { folder.deleteLastPathComponent() }
        return folder.path + "/"
    }()

    /// The folders whose files are dependencies', wherever they are in a file's path: the packages that
    /// SwiftPM and Xcode check out, the build folders, and CocoaPods' and Carthage's folders.
    static let dependencyFolders: Set<String> = ["checkouts", "SourcePackages", ".build", "DerivedData", "Pods", "Carthage"]

    /// The folder of a package's tests, by SwiftPM's convention.
    static let testsFolder = "Tests"

    let functions: [Function]

    var regionCount: Int { functions.last?.regions.upperBound ?? 0 }

    /// Whether CucumberSwift measures the code in `file`, which `binary` holds.
    ///
    /// With `sources`, only the files whose path contains one of them count. Otherwise every file counts
    /// except the dependencies', CucumberSwift's and, when the app or a framework has its own binary, the
    /// test bundle's.
    /// When the test bundle holds all the code, as `swift test` builds it, its files under a `Tests`
    /// folder are left out instead.
    static func isMeasured(file: String, binary: String, sources: [String], testBundleHoldsAllCode: Bool) -> Bool {
        guard !file.isEmpty else { return false }
        if !sources.isEmpty { return sources.contains { file.contains($0) } }
        let folders = Set(URL(fileURLWithPath: file).pathComponents.dropLast())
        guard folders.isDisjoint(with: dependencyFolders), !file.hasPrefix(cucumberSwiftFolder) else { return false }
        if testBundleHoldsAllCode { return !folders.contains(testsFolder) }
        return !URL(fileURLWithPath: binary).pathComponents.contains { $0.hasSuffix(".xctest") }
    }

    /// The index in ``functions`` of the function that region `region` belongs to.
    func functionIndex(of region: Int) -> Int? {
        var low = 0
        var high = functions.count - 1
        while low <= high {
            let middle = (low + high) / 2
            let function = functions[middle]
            if function.regions.contains(region) { return middle }
            if region < function.regions.lowerBound { high = middle - 1 } else { low = middle + 1 }
        }
        return nil
    }

    /// The function that region `region` belongs to.
    func function(of region: Int) -> Function? {
        functionIndex(of: region).map { functions[$0] }
    }
}

/// A feature's two scores: how much of the code its scenarios ran they covered, higher is better, and how
/// much of what they covered more than one of them covered, lower is better. With each scenario's share
/// of the coverage, its time, and the functions whose code no scenario ran.
struct CoverageScores: Codable, Equatable {
    /// The regions one of a scenario's steps after its Background ran.
    struct StepRun: Equatable {
        let line: Int
        let regions: Set<Int>
    }

    /// A redundant step outside the Background: some of the code it runs, in functions that other
    /// scenarios run in exactly the same way.
    struct RedundantStep: Codable, Equatable {
        /// The step's line.
        let line: Int
        /// The share of the regions the step ran that are in those functions, from 0 to 100.
        let percent: Double
        /// The line of the step in another scenario that runs most of the same code.
        let similarTo: Int
        /// Whether the two steps' scenarios run exactly the same code after the Background, so that they differ
        /// only in their values, and a Scenario Outline fits better than a Background.
        let suggestsOutline: Bool
    }

    /// A scenario as the scores see it.
    struct Scenario {
        let name: String
        let line: Int
        let tags: [String]
        let duration: TimeInterval
        let regions: Set<Int>
        /// The scenarios of one Scenario Outline, its examples, have the same group: the lines of the steps
        /// they share. Every other scenario has a group of its own.
        let group: String
        /// The regions the scenario ran during its Background steps: code shared by every scenario, which the redundancy
        /// leaves out. They still count toward the coverage.
        private(set) var backgroundRegions = Set<Int>()
        /// The regions each of its steps after the Background ran.
        private(set) var steps = [StepRun]()

        /// The regions the redundancy counts: those the scenario ran after its Background steps.
        var countedRegions: Set<Int> {
            regions.subtracting(backgroundRegions)
        }

        /// Whether the scenario is tagged `@redundant`. The parser keeps a tag without its `@`, and a tag
        /// written in code may have one.
        var isTaggedRedundant: Bool {
            tags.contains { $0.hasPrefix("@") ? $0.dropFirst() == CoverageScores.redundantTag : $0 == CoverageScores.redundantTag }
        }

        init(name: String,
             line: Int,
             tags: [String],
             duration: TimeInterval,
             regions: Set<Int>,
             group: String? = nil) {
            self.name = name
            self.line = line
            self.tags = tags
            self.duration = duration
            self.regions = regions
            self.group = group ?? "line \(line)"
        }

        /// This scenario with the regions it ran during its Background steps.
        func with(backgroundRegions: Set<Int>) -> Scenario {
            var copy = self
            copy.backgroundRegions = backgroundRegions
            return copy
        }

        /// This scenario with the regions each of its steps after the Background ran.
        func with(steps: [StepRun]) -> Scenario {
            var copy = self
            copy.steps = steps
            return copy
        }
    }

    struct ScenarioScore: Codable, Equatable {
        let name: String
        let line: Int
        let duration: TimeInterval
        /// The regions the scenario ran.
        let regions: Int
        /// The regions no other scenario ran.
        let ownRegions: Int
        /// The scenario's part of ``CoverageScores/coverage``: each region it ran counts in full when it
        /// alone ran it, and is split evenly between the scenarios that ran it otherwise. The shares add
        /// up to the coverage.
        let share: Double
        /// Whether the scenario is redundant: other scenarios kept run all the code it runs after its
        /// Background steps. Only set with the redundancy score on.
        let addsNothing: Bool
        /// The scenario's time when it is redundant, and 0 otherwise. Nil with the redundancy score off.
        let wastedTime: TimeInterval?
        /// The scenario's ``Scenario/group``.
        let group: String
        /// How the scenario differs from the one it overlaps, when the two run much the same code but each checks
        /// something the other doesn't. Only set with mutation testing on.
        var overlap: Overlap?
    }

    /// The mutants each scenario detected, by the scenario's line, with what each mutant changes, by its ID. With
    /// these, the redundancy judges the scenarios by the mutants they detect as well as by their code.
    struct Detections: Equatable {
        var kills: [Int: Set<String>]
        var changes: [String: String]
    }

    /// A scenario that runs only code other scenarios run, but detects a mutant they miss, and the scenario it
    /// overlaps most: one of the two should take the best of both.
    struct Overlap: Codable, Equatable {
        /// The line of the scenario this one overlaps.
        let line: Int
        /// The regions this scenario runs that the other doesn't, and the other way around.
        let regionsHere: Int
        let regionsThere: Int
        /// What the mutants change that only this scenario detects, and the other way around.
        let detectsHere: [String]
        let detectsThere: [String]
    }

    /// A function the feature entered, with regions none of its scenarios ran.
    struct Gap: Codable, Equatable {
        let function: String
        let file: String
        let line: Int
        let regionsNotRun: Int
        /// The lines of the scenarios that entered the function.
        let enteredBy: [Int]
    }

    /// A scenario tagged with this is left out of the redundancy score: one you keep on purpose though
    /// other scenarios run its code, such as a test for a bug that came back.
    static let redundantTag = "redundant"

    /// The regions the scenarios ran, of the regions in the functions they entered.
    let coveredRegions: Int
    let regionsInFunctionsRun: Int
    /// All the regions that coverage measures, whether a scenario entered their function or not.
    let measuredRegions: Int
    let functionsRun: Int
    /// The share of the scenarios that are redundant, from 0 to 100, counting a Scenario Outline's examples
    /// as one. Nil with the redundancy score off.
    let redundancy: Double?
    /// The time the redundant scenarios took. Nil with the redundancy score off.
    let wastedTime: TimeInterval?
    let scenarios: [ScenarioScore]
    let gaps: [Gap]
    /// The redundant steps, by line. Empty with the redundancy score off.
    let redundantSteps: [RedundantStep]
    /// Whether the redundancy judged the scenarios by the mutants they detect as well as by their code.
    let isMutationAware: Bool

    /// The feature's coverage, from 0 to 100: the regions its scenarios ran, of the regions in the
    /// functions they entered.
    var coverage: Double { percent(coveredRegions, of: regionsInFunctionsRun) }

    /// The regions the feature's scenarios ran, of all the code coverage measures, from 0 to 100.
    var coverageOfAllCode: Double { percent(coveredRegions, of: measuredRegions) }

    /// The seconds all the scenarios took.
    var duration: TimeInterval { scenarios.reduce(0) { $0 + $1.duration } }

    /// The steps outside the Background that run, in the same way as other scenarios do, functions that
    /// belong in the Background: the redundant steps.
    ///
    /// A function is run the same way when two or more scenarios, a Scenario Outline's examples counting as
    /// one, ran exactly the same regions of it in their steps. A function that scenarios run with different
    /// inputs, such as `sum` with positive and with negative numbers, runs different regions, so it isn't
    /// a redundant step.
    private static func redundantSteps(of scenarios: [Scenario], code: MeasuredCode) -> [RedundantStep] {
        var groups = [String: [Int: Set<Int>]]()
        for scenario in scenarios where !scenario.isTaggedRedundant {
            for step in scenario.steps {
                groups[scenario.group, default: [:]][step.line, default: []].formUnion(step.regions)
            }
        }
        guard groups.count >= 2 else { return [] }
        func byFunction(_ regions: Set<Int>) -> [Range<Int>: Set<Int>] {
            var result = [Range<Int>: Set<Int>]()
            for region in regions {
                if let function = code.function(of: region) { result[function.regions, default: []].insert(region) }
            }
            return result
        }
        let allRegions = groups.mapValues { $0.values.reduce(into: Set<Int>()) { $0.formUnion($1) } }
        let functionRuns = groups.mapValues { byFunction($0.values.reduce(into: Set<Int>()) { $0.formUnion($1) }) }
        // For each function, how many groups ran each set of its regions.
        var sameWay = [Range<Int>: [Set<Int>: Int]]()
        for runs in functionRuns.values {
            for (function, regions) in runs { sameWay[function, default: [:]][regions, default: 0] += 1 }
        }
        var found = [Int: RedundantStep]()
        for (group, steps) in groups {
            for (line, regions) in steps where !regions.isEmpty {
                var repeated = Set<Int>()
                for (function, ran) in byFunction(regions) {
                    let count = functionRuns[group]?[function].flatMap { sameWay[function]?[$0] } ?? 0
                    if count >= 2 { repeated.formUnion(ran) }
                }
                let similar = groups.filter { $0.key != group }
                    .flatMap { other in other.value.map { (group: other.key, line: $0.key, shared: $0.value.intersection(repeated).count) } }
                    .max { ($0.shared, $1.line) < ($1.shared, $0.line) }
                guard let similar, similar.shared > 0 else { continue }
                let percent = 100 * Double(repeated.count) / Double(regions.count)
                let isOutline = allRegions[group] == allRegions[similar.group]
                found[line] = RedundantStep(line: line, percent: percent, similarTo: similar.line, suggestsOutline: isOutline)
            }
        }
        return found.values.sorted { $0.line < $1.line }
    }

    /// With `detections`, the redundancy also judges the scenarios by the mutants they detect.
    init(scenarios: [Scenario], code: MeasuredCode, isRedundancy: Bool, detections: Detections? = nil) {
        var runs = [Int: Int]()
        for scenario in scenarios {
            for region in scenario.regions { runs[region, default: 0] += 1 }
        }
        let covered = Set(runs.keys)
        let functionsRun = Set(covered.compactMap { code.function(of: $0)?.regions })
        coveredRegions = covered.count
        regionsInFunctionsRun = functionsRun.reduce(0) { $0 + $1.count }
        measuredRegions = code.regionCount
        self.functionsRun = functionsRun.count

        // Redundancy is measured only with its score on.
        let measured = isRedundancy ? Self.redundancy(of: scenarios, detections: detections) : nil
        redundancy = measured?.score
        isMutationAware = isRedundancy && detections != nil
        // A redundant scenario's whole time is wasted: removing it would test no less code.
        let wasted = scenarios.map { scenario in
            measured.map { $0.redundantGroups.contains(scenario.group) && !scenario.isTaggedRedundant ? scenario.duration : 0 }
        }
        wastedTime = measured == nil ? nil : wasted.reduce(0) { $0 + ($1 ?? 0) }

        redundantSteps = isRedundancy ? Self.redundantSteps(of: scenarios, code: code) : []

        let total = regionsInFunctionsRun
        self.scenarios = zip(scenarios, wasted).map { scenario, wastedTime in
            let own = scenario.regions.filter { runs[$0] == 1 }.count
            let share = scenario.regions.reduce(0.0) { $0 + 1 / Double(runs[$1] ?? 1) }
            let addsNothing = !scenario.isTaggedRedundant && measured?.redundantGroups.contains(scenario.group) == true
            var score = ScenarioScore(name: scenario.name,
                                      line: scenario.line,
                                      duration: scenario.duration,
                                      regions: scenario.regions.count,
                                      ownRegions: own,
                                      share: total == 0 ? 0 : 100 * share / Double(total),
                                      addsNothing: addsNothing,
                                      wastedTime: wastedTime,
                                      group: scenario.group)
            if !scenario.isTaggedRedundant, let partner = measured?.overlaps[scenario.group] {
                score.overlap = Self.overlap(of: scenario.group, with: partner, in: scenarios, detections: detections)
            }
            return score
        }

        let entered = code.functions.filter { functionsRun.contains($0.regions) }
        gaps = entered.compactMap { function in
            let notRun = function.regions.filter { !covered.contains($0) }.count
            guard notRun > 0 else { return nil }
            let enteredBy = scenarios.filter { !$0.regions.isDisjoint(with: function.regions) }.map(\.line)
            return Gap(function: function.name,
                       file: function.file,
                       line: function.line,
                       regionsNotRun: notRun,
                       enteredBy: Array(Set(enteredBy)).sorted())
        }
        .sorted { ($0.regionsNotRun, $1.file, $1.line) > ($1.regionsNotRun, $0.file, $0.line) }
    }

    /// A part of a feature that is scored on its own: its scenarios that aren't in a Rule, when `rule` is
    /// nil, or the scenarios of one of its Rules.
    struct Part: Equatable {
        let rule: ScenarioRule?
        let scores: CoverageScores
    }

    /// The scores of a feature's scenarios: one part for its scenarios outside a Rule, first, then one for
    /// each Rule, in the order of their lines. Each part scores its scenarios in the order of their lines in
    /// the feature file, whatever order they ran in.
    /// With `detections`, the redundancy also judges the scenarios by the mutants they detect.
    static func parts(of scenarios: [(rule: ScenarioRule?, scenario: Scenario)],
                      code: MeasuredCode,
                      isRedundancy: Bool,
                      detections: Detections? = nil) -> [Part] {
        let inOrder = scenarios.enumerated()
            .sorted { ($0.element.scenario.line, $0.offset) < ($1.element.scenario.line, $1.offset) }
            .map(\.element)
        let rules = Set(inOrder.compactMap(\.rule)).sorted { $0.line < $1.line }
        let parts: [ScenarioRule?] = (inOrder.contains { $0.rule == nil } ? [nil] : []) + rules
        return parts.map { rule in
            let ran = inOrder.filter { $0.rule == rule }.map(\.scenario)
            return Part(rule: rule, scores: CoverageScores(scenarios: ran, code: code, isRedundancy: isRedundancy, detections: detections))
        }
    }

    private func percent(_ part: Int, of whole: Int) -> Double {
        whole == 0 ? 0 : 100 * Double(part) / Double(whole)
    }
}

extension CoverageScores {
    /// Reads the scores from a manifest. A manifest that CucumberSwift 6.8 wrote has no `isMutationAware`, which is
    /// then false: the field is new, so the manifest's form, and its version, stay the same.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coveredRegions = try container.decode(Int.self, forKey: .coveredRegions)
        regionsInFunctionsRun = try container.decode(Int.self, forKey: .regionsInFunctionsRun)
        measuredRegions = try container.decode(Int.self, forKey: .measuredRegions)
        functionsRun = try container.decode(Int.self, forKey: .functionsRun)
        redundancy = try container.decodeIfPresent(Double.self, forKey: .redundancy)
        wastedTime = try container.decodeIfPresent(TimeInterval.self, forKey: .wastedTime)
        scenarios = try container.decode([ScenarioScore].self, forKey: .scenarios)
        gaps = try container.decode([Gap].self, forKey: .gaps)
        redundantSteps = try container.decode([RedundantStep].self, forKey: .redundantSteps)
        isMutationAware = try container.decodeIfPresent(Bool.self, forKey: .isMutationAware) ?? false
    }
}
