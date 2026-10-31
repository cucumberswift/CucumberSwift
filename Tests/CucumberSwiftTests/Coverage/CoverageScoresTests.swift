//
//  CoverageScoresTests.swift
//  CucumberSwiftTests
//
//  A feature's coverage is the code its scenarios ran, of the code in the functions they entered; each
//  scenario's share of it adds up to it; and its redundancy is how much of that code more than one
//  scenario ran (#502).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageScoresTests: XCTestCase {
    /// Three functions: `add` with regions 0 to 3, `subtract` with 4 to 7, and `classify` with 8 to 13.
    private let code = MeasuredCode(functions: [
        MeasuredCode.Function(name: "Calculator.add(Int, Int)", file: CoverageScoresTests.path("app", "Calculator.swift"), line: 3, regions: 0..<4),
        MeasuredCode.Function(name: "Calculator.subtract(Int, Int)", file: CoverageScoresTests.path("app", "Calculator.swift"), line: 9, regions: 4..<8),
        MeasuredCode.Function(name: "Calculator.classify(Int)", file: CoverageScoresTests.path("app", "Calculator.swift"), line: 15, regions: 8..<14)
    ])

    /// A path in the temporary folder, from its folders and file name.
    private static func path(_ parts: String...) -> String {
        parts.reduce(FileManager.default.temporaryDirectory) { $0.appendingPathComponent($1) }.path
    }

    private func scenario(_ line: Int, _ regions: Set<Int>, tags: [String] = [], duration: TimeInterval = 1) -> CoverageScores.Scenario {
        CoverageScores.Scenario(name: "Scenario \(line)", line: line, tags: tags, duration: duration, regions: regions)
    }

    func testTheCoverageCountsOnlyTheFunctionsTheScenariosEntered() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [8])], code: code, isRedundancy: false)
        XCTAssertEqual(scores.coveredRegions, 4)
        XCTAssertEqual(scores.regionsInFunctionsRun, 10)
        XCTAssertEqual(scores.functionsRun, 2)
        XCTAssertEqual(scores.coverage, 40)
        XCTAssertEqual(scores.coverageOfAllCode, 100 * 4 / 14.0)
        XCTAssertNil(scores.redundancy)
    }

    func testTheScenariosSharesAddUpToTheCoverageWithSharedRegionsSplitEvenly() throws {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [0, 4]), scenario(14, [8])], code: code, isRedundancy: false)
        let shares = scores.scenarios.map(\.share)
        XCTAssertEqual(shares.reduce(0, +), scores.coverage, accuracy: 0.0001)
        XCTAssertEqual(shares[0], 100 * 2.5 / 14, accuracy: 0.0001)
        XCTAssertEqual(shares[1], 100 * 1.5 / 14, accuracy: 0.0001)
        XCTAssertEqual(scores.scenarios.map(\.ownRegions), [2, 1, 1])
    }

    func testTheRedundancyIsTheRepeatedPartOfWhatTheScenariosRan() throws {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])], code: code, isRedundancy: true)
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 50)
        XCTAssertEqual(scores.scenarios.map(\.addsNothing), [true, true])
    }

    func testWithRedundancyOffNothingAboutItIsMeasured() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1])], code: code, isRedundancy: false)
        XCTAssertNil(scores.redundancy)
        XCTAssertEqual(scores.scenarios.map(\.addsNothing), [false, false])
    }

    func testWithThreeScenariosTheCodeAllOfThemRunDoesNotCount() throws {
        // Region 0 is shared setup that every scenario runs; only regions 4 and 5 are run twice.
        let scores = CoverageScores(scenarios: [scenario(4, [0, 4]), scenario(9, [0, 4, 5]), scenario(14, [0, 5, 8])], code: code, isRedundancy: true)
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 100 * 2 / 5.0, accuracy: 0.0001)
        // The second scenario's regions 4 and 5 are each run by another scenario too.
        XCTAssertEqual(scores.scenarios.map(\.addsNothing), [true, true, false])
    }

    func testAnOutlinesExamplesAreComparedWithTheOtherScenariosNotWithEachOther() throws {
        let scores = CoverageScores(scenarios: [scenario(4, [8, 9]), scenario(4, [8, 10]), scenario(12, [0, 1])], code: code, isRedundancy: true)
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 0)
        XCTAssertEqual(scores.scenarios.map(\.addsNothing), [false, false, false])
    }

    func testAScenarioTaggedRedundantIsLeftOutOfTheRedundancy() throws {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1]), scenario(9, [0, 1], tags: ["@redundant"])], code: code, isRedundancy: true)
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 0)
        XCTAssertEqual(scores.scenarios.map(\.addsNothing), [false, false])
    }

    func testAScenarioTaggedRedundantInAFeatureFileIsLeftOut() throws {
        let cucumber = Cucumber(withString: """
        Feature: Adding
            Scenario: Adding
                Given a calculator
            @redundant
            Scenario: Adding again
                Given a calculator
        """)
        let parsed = try XCTUnwrap(cucumber.features.first).scenarios
        // The parser keeps the tag without its `@`.
        XCTAssertEqual(parsed[1].tags, ["redundant"])
        let scenarios = parsed.map { CoverageScores.Scenario(name: $0.title, line: Int($0.location.line), tags: $0.tags, duration: 1, regions: [0, 1]) }
        let scores = CoverageScores(scenarios: scenarios, code: code, isRedundancy: true)
        XCTAssertEqual(try XCTUnwrap(scores.redundancy), 0)
        XCTAssertEqual(scores.scenarios.map(\.addsNothing), [false, false])
    }

    func testTheGapsAreTheFunctionsEnteredWithRegionsNotRunMostFirst() {
        let scores = CoverageScores(scenarios: [scenario(4, [0, 1, 2]), scenario(9, [8])], code: code, isRedundancy: false)
        XCTAssertEqual(scores.gaps, [
            CoverageScores.Gap(function: "Calculator.classify(Int)", file: CoverageScoresTests.path("app", "Calculator.swift"), line: 15, regionsNotRun: 5, enteredBy: [9]),
            CoverageScores.Gap(function: "Calculator.add(Int, Int)", file: CoverageScoresTests.path("app", "Calculator.swift"), line: 3, regionsNotRun: 1, enteredBy: [4])
        ])
    }

    func testARegionIsFoundInItsFunction() {
        XCTAssertEqual(code.function(of: 0)?.line, 3)
        XCTAssertEqual(code.function(of: 7)?.line, 9)
        XCTAssertEqual(code.function(of: 13)?.line, 15)
        XCTAssertNil(code.function(of: 14))
    }

    func testTheDefaultCodeLeavesOutDependenciesAndTests() {
        let app = Self.path("DD", "App.app", "App")
        let testBundle = Self.path("DD", "AppTests.xctest", "Contents", "MacOS", "AppTests")
        let packageTests = Self.path("b", "AppPackageTests.xctest", "Contents", "MacOS", "AppPackageTests")
        let model = Self.path("me", "App", "Sources", "App", "Model.swift")
        let checkout = Self.path("DD", "SourcePackages", "checkouts", "Lib", "Lib.swift")
        func measured(_ file: String, binary: String? = nil, sources: [String] = [], all: Bool = false) -> Bool {
            MeasuredCode.isMeasured(file: file, binary: binary ?? app, sources: sources, testBundleHoldsAllCode: all)
        }
        XCTAssertTrue(measured(model))
        XCTAssertFalse(measured(checkout))
        XCTAssertFalse(measured(Self.path("me", "App", ".build", "checkouts", "Lib", "Lib.swift")))
        XCTAssertFalse(measured(Self.path("me", "App", "Tests", "StepDefinitions.swift"), binary: testBundle))
        XCTAssertTrue(measured(model, binary: packageTests, all: true))
        XCTAssertFalse(measured(Self.path("me", "App", "Tests", "AppTests", "Steps.swift"), binary: packageTests, all: true))
        XCTAssertTrue(measured(checkout, sources: ["checkouts/Lib"]))
        XCTAssertFalse(measured(model, sources: ["checkouts/Lib"]))
        XCTAssertFalse(measured(""))
        XCTAssertFalse(measured(MeasuredCode.cucumberSwiftFolder + "Sources/CucumberSwift/Runner/Cucumber.swift"))
        XCTAssertTrue(MeasuredCode.cucumberSwiftFolder.hasSuffix("/"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: MeasuredCode.cucumberSwiftFolder + "Package.swift"))
    }
}
