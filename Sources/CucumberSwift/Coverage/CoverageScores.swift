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
        let dependencies = ["/checkouts/", "/SourcePackages/", "/.build/", "/DerivedData/", "/Pods/", "/Carthage/"]
        guard !dependencies.contains(where: file.contains), !file.hasPrefix(cucumberSwiftFolder) else { return false }
        if testBundleHoldsAllCode { return !file.contains("/Tests/") }
        return !binary.contains(".xctest/")
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

        init(name: String, line: Int, tags: [String], duration: TimeInterval, regions: Set<Int>, group: String? = nil) {
            self.name = name
            self.line = line
            self.tags = tags
            self.duration = duration
            self.regions = regions
            self.group = group ?? "line \(line)"
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
        /// Whether every region the scenario ran was also run by another scenario, outside its Scenario
        /// Outline. Only set with the redundancy score on.
        let addsNothing: Bool
        /// The scenario's ``Scenario/group``.
        let group: String
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
    static let redundantTag = "@redundant"

    /// The regions the scenarios ran, of the regions in the functions they entered.
    let coveredRegions: Int
    let regionsInFunctionsRun: Int
    /// All the regions that coverage measures, whether a scenario entered their function or not.
    let measuredRegions: Int
    let functionsRun: Int
    /// Nil with the redundancy score off.
    let redundancy: Double?
    let scenarios: [ScenarioScore]
    let gaps: [Gap]

    /// The feature's coverage, from 0 to 100: the regions its scenarios ran, of the regions in the
    /// functions they entered.
    var coverage: Double { percent(coveredRegions, of: regionsInFunctionsRun) }

    /// The regions the feature's scenarios ran, of all the code coverage measures, from 0 to 100.
    var coverageOfAllCode: Double { percent(coveredRegions, of: measuredRegions) }

    // swiftlint:disable:next function_body_length
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

        // A Scenario Outline's examples are one group, so that rows that run the same code with other data
        // don't count as redundant.
        let counted = scenarios.filter { !$0.tags.contains(Self.redundantTag) }
        var groups = [String: Set<Int>]()
        for scenario in counted { groups[scenario.group, default: []].formUnion(scenario.regions) }
        var groupRuns = [Int: Int]()
        for regions in groups.values {
            for region in regions { groupRuns[region, default: 0] += 1 }
        }
        // With three or more groups, the code every one of them runs, such as their shared setup, doesn't
        // count. With two, it would hide two scenarios that run the same code.
        if groups.count >= 3 {
            groupRuns = groupRuns.filter { $0.value < groups.count }
        }
        if isRedundancy {
            let runsCounted = groupRuns.values.reduce(0, +)
            let repeated = groupRuns.values.reduce(0) { $0 + $1 - 1 }
            redundancy = runsCounted == 0 ? 0 : 100 * Double(repeated) / Double(runsCounted)
        } else {
            redundancy = nil
        }

        let total = regionsInFunctionsRun
        self.scenarios = scenarios.map { scenario in
            let own = scenario.regions.filter { runs[$0] == 1 }.count
            let share = scenario.regions.reduce(0.0) { $0 + 1 / Double(runs[$1] ?? 1) }
            let group = scenario.tags.contains(Self.redundantTag) ? [] : groups[scenario.group] ?? []
            let groupRegions = group.filter { groupRuns[$0] != nil }
            let addsNothing = isRedundancy && groups.count >= 2 && !groupRegions.isEmpty
                && groupRegions.allSatisfy { (groupRuns[$0] ?? 0) > 1 }
            return ScenarioScore(name: scenario.name,
                                 line: scenario.line,
                                 duration: scenario.duration,
                                 regions: scenario.regions.count,
                                 ownRegions: own,
                                 share: total == 0 ? 0 : 100 * share / Double(total),
                                 addsNothing: addsNothing,
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
