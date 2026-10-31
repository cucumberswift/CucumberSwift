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

    /// The function that region `region` belongs to.
    func function(of region: Int) -> Function? {
        var low = 0
        var high = functions.count - 1
        while low <= high {
            let middle = (low + high) / 2
            let function = functions[middle]
            if function.regions.contains(region) { return function }
            if region < function.regions.lowerBound { high = middle - 1 } else { low = middle + 1 }
        }
        return nil
    }
}

/// A feature's two scores: how much of the code its scenarios ran they covered, higher is better, and how
/// much of what they covered more than one of them covered, lower is better. With each scenario's share
/// of the coverage, its time, and the functions whose code no scenario ran.
struct CoverageScores: Codable, Equatable {
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
        /// The regions the scenario ran during its Background steps: shared setup, which the redundancy
        /// leaves out. They still count toward the coverage.
        let setupRegions: Set<Int>

        /// The regions the redundancy counts: those the scenario ran after its Background steps.
        var countedRegions: Set<Int> {
            regions.subtracting(setupRegions)
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
             group: String? = nil,
             setupRegions: Set<Int> = []) {
            self.name = name
            self.line = line
            self.tags = tags
            self.duration = duration
            self.regions = regions
            self.group = group ?? "line \(line)"
            self.setupRegions = setupRegions
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
    }

    /// What the redundancy score measured: the score, and the redundant groups.
    private struct Redundancy {
        let score: Double
        let redundantGroups: Set<String>
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

    /// The feature's coverage, from 0 to 100: the regions its scenarios ran, of the regions in the
    /// functions they entered.
    var coverage: Double { percent(coveredRegions, of: regionsInFunctionsRun) }

    /// The regions the feature's scenarios ran, of all the code coverage measures, from 0 to 100.
    var coverageOfAllCode: Double { percent(coveredRegions, of: measuredRegions) }

    /// The seconds all the scenarios took.
    var duration: TimeInterval { scenarios.reduce(0) { $0 + $1.duration } }

    /// The redundant groups of `scenarios`, and their share of the groups, from 0 to 100. A group is a
    /// scenario, or a Scenario Outline's examples together, and its code is what its scenarios ran after their
    /// Background steps.
    ///
    /// A group is redundant when the groups kept run all of its code. Every group whose code the other
    /// groups don't all run is kept. Of the rest, which the other groups cover, each is kept in the order of
    /// the feature file unless the groups kept so far run its code: so order only decides between groups that
    /// cover each other, such as two that run the same code, and the later one is redundant.
    private static func redundancy(of scenarios: [Scenario]) -> Redundancy {
        var order = [String]()
        var groups = [String: Set<Int>]()
        for scenario in scenarios where !scenario.isTaggedRedundant {
            if groups[scenario.group] == nil { order.append(scenario.group) }
            groups[scenario.group, default: []].formUnion(scenario.countedRegions)
        }
        // A group with no code of its own beyond its Background has nothing to judge.
        let judged = order.filter { groups[$0]?.isEmpty == false }
        func others(than group: String) -> Set<Int> {
            judged.filter { $0 != group }.reduce(into: Set<Int>()) { $0.formUnion(groups[$1] ?? []) }
        }
        let covered = Set(judged.filter { (groups[$0] ?? []).isSubset(of: others(than: $0)) })
        var kept = judged.filter { !covered.contains($0) }.reduce(into: Set<Int>()) { $0.formUnion(groups[$1] ?? []) }
        var redundant = Set<String>()
        for group in judged where covered.contains(group) {
            let regions = groups[group] ?? []
            if regions.isSubset(of: kept) {
                redundant.insert(group)
            } else {
                kept.formUnion(regions)
            }
        }
        let score = judged.isEmpty ? 0 : 100 * Double(redundant.count) / Double(judged.count)
        return Redundancy(score: score, redundantGroups: redundant)
    }

    init(scenarios: [Scenario], code: MeasuredCode, isRedundancy: Bool) {
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
        let measured = isRedundancy ? Self.redundancy(of: scenarios) : nil
        redundancy = measured?.score
        // A redundant scenario's whole time is wasted: removing it would test no less code.
        let wasted = scenarios.map { scenario in
            measured.map { $0.redundantGroups.contains(scenario.group) && !scenario.isTaggedRedundant ? scenario.duration : 0 }
        }
        wastedTime = measured == nil ? nil : wasted.reduce(0) { $0 + ($1 ?? 0) }

        let total = regionsInFunctionsRun
        self.scenarios = zip(scenarios, wasted).map { scenario, wastedTime in
            let own = scenario.regions.filter { runs[$0] == 1 }.count
            let share = scenario.regions.reduce(0.0) { $0 + 1 / Double(runs[$1] ?? 1) }
            let addsNothing = !scenario.isTaggedRedundant && measured?.redundantGroups.contains(scenario.group) == true
            return ScenarioScore(name: scenario.name,
                                 line: scenario.line,
                                 duration: scenario.duration,
                                 regions: scenario.regions.count,
                                 ownRegions: own,
                                 share: total == 0 ? 0 : 100 * share / Double(total),
                                 addsNothing: addsNothing,
                                 wastedTime: wastedTime,
                                 group: scenario.group)
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

    private func percent(_ part: Int, of whole: Int) -> Double {
        whole == 0 ? 0 : 100 * Double(part) / Double(whole)
    }
}
