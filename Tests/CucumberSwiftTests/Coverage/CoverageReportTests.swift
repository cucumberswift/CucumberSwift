//
//  CoverageReportTests.swift
//  CucumberSwiftTests
//
//  A feature's scores past their levels are warnings and errors on its feature file, with the
//  functions whose code no scenario ran, and the run prints each feature's scores (#502).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageReportTests: XCTestCase {
    /// The default settings without the redundancy score, for the tests of the coverage score.
    private static let coverageOnly: CoverageSettings = {
        var settings = CoverageSettings()
        settings.isRedundancy = false
        return settings
    }()

    private let code = MeasuredCode(functions: [
        MeasuredCode.Function(name: "Calculator.classify(Int)", file: CoverageReportTests.path("app", "Calculator.swift"), line: 15, regions: 0..<10)
    ])
    private let file = URL(fileURLWithPath: CoverageReportTests.path("app", "Features", "Arithmetic.feature"))

    /// A path in the temporary folder, from its folders and file name.
    private static func path(_ parts: String...) -> String {
        parts.reduce(FileManager.default.temporaryDirectory) { $0.appendingPathComponent($1) }.path
    }

    private func report(_ regions: Set<Int>, settings: CoverageSettings = CoverageReportTests.coverageOnly) -> CoverageReport {
        let scenarios = [
            CoverageScores.Scenario(name: "Classifying", line: 19, tags: [], duration: 0.5, regions: regions),
            CoverageScores.Scenario(name: "Again", line: 25, tags: [], duration: 0.25, regions: regions)
        ]
        return CoverageReport(scores: CoverageScores(scenarios: scenarios, code: code, isRedundancy: settings.isRedundancy), settings: settings)
    }

    func testCoverageAtOrBelowTheErrorLevelIsAnErrorNamingWhatDidntRun() throws {
        let issues = report([0, 1, 2, 3, 4]).issues(file: file, line: 1, subject: "Feature")
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issue.severity, .error)
        XCTAssertEqual(issue.line, 1)
        XCTAssertEqual(issue.file, file)
        XCTAssertEqual(issue.message, "Feature coverage 50%: its scenarios ran 5 of the 10 regions in the 1 function they entered"
            + " (error at or below 50%, warning at or below 80%)."
            + " Not run: Calculator.classify(Int), 5 regions, entered by the scenarios at lines 19, 25.")
    }

    func testCoverageAtOrBelowTheWarningLevelIsAWarning() {
        XCTAssertEqual(report(Set(0..<8)).issues(file: file, line: 1, subject: "Feature").map(\.severity), [.warning])
    }

    func testCoverageAboveTheWarningLevelHasNoIssue() {
        XCTAssertEqual(report(Set(0..<9)).issues(file: file, line: 1, subject: "Feature"), [])
    }

    func testALevelThatIsOffIsNotChecked() {
        var settings = Self.coverageOnly
        settings.errorLevel = .off
        settings.warningLevel = .off
        XCTAssertEqual(report([0], settings: settings).issues(file: file, line: 1, subject: "Feature"), [])
    }

    func testRedundancyAtOrAboveItsLevelsIsAWarningOrAnErrorAndAScenarioThatAddsNothingIsAWarning() {
        var settings = CoverageSettings()
        settings.warningLevel = .off
        settings.errorLevel = .off
        settings.isRedundancy = true
        let issues = report(Set(0..<10), settings: settings).issues(file: file, line: 1, subject: "Feature")
        XCTAssertEqual(issues.map(\.severity), [.warning, .warning, .warning])
        XCTAssertEqual(issues.map(\.line), [1, 19, 25])
        XCTAssertEqual(issues[1].message, "Scenario adds no coverage of its own: other scenarios ran all of its code. It took 0.50s.")
        settings.redundancyErrorLevel = 50
        XCTAssertEqual(report(Set(0..<10), settings: settings).issues(file: file, line: 1, subject: "Feature").first?.severity, .error)
        settings.redundancyWarningLevel = .off
        settings.redundancyErrorLevel = .off
        XCTAssertEqual(report(Set(0..<10), settings: settings).issues(file: file, line: 1, subject: "Feature"), [])
    }

    func testTheSummaryListsEachScenariosShareAndTime() {
        let summary = report([0, 1, 2, 3, 4]).summary(name: "Arithmetic")
        XCTAssertEqual(summary, """
        CucumberSwift coverage: Arithmetic: 50% of the code its scenarios ran (5 of 10 regions in 1 function), 50% of all measured code
            Share  Own regions      Time  Scenario
              25%            0     0.50s  Classifying (line 19)
              25%            0     0.25s  Again (line 25)
        """)
    }

    func testALevelIsANumberFrom0To100OrOff() {
        XCTAssertEqual(CoverageLevel(" 70 "), .percent(70))
        XCTAssertEqual(CoverageLevel("no"), .off)
        XCTAssertEqual(CoverageLevel("OFF"), .off)
        XCTAssertNil(CoverageLevel("101"))
        XCTAssertNil(CoverageLevel("high"))
        XCTAssertNil(CoverageLevel(nil))
        let level: CoverageLevel = 60
        XCTAssertEqual(level, .percent(60))
        // The edges: anything else isn't a level, so the default applies.
        XCTAssertEqual(CoverageLevel("0"), .percent(0))
        XCTAssertEqual(CoverageLevel("100"), .percent(100))
        XCTAssertEqual(CoverageLevel("off"), .off)
        XCTAssertEqual(CoverageLevel("false"), .off)
        for text in ["101", "-1", "", "   ", "7 0", "abc", "٧٠", "70%"] {
            XCTAssertNil(CoverageLevel(text), text)
        }
    }

    func testANameIsShortenedToItsTypeFunctionAndParameters() {
        XCTAssertEqual(ReadableName.shortened("Calculator.Calculator.classify(Swift.Int) -> Swift.String"), "Calculator.classify(Int)")
        XCTAssertEqual(ReadableName.shortened("Calculator.Calculator.divide(_: Swift.Int, by: Swift.Int) throws -> Swift.Int"),
                       "Calculator.divide(_: Int, by: Int)")
        XCTAssertEqual(ReadableName.shortened("App.Model.apply((Swift.Int) -> Swift.Int) -> ()"), "Model.apply((Int) -> Int)")
        XCTAssertEqual(ReadableName.shortened("closure #1 (Swift.Int) -> Swift.Int in Calc.Calculator.classify(Swift.Int) -> Swift.String"),
                       "closure in Calculator.classify(Int)")
        XCTAssertEqual(ReadableName.shortened("closure #2 () -> () in closure #1 () -> () in App.Model.load() -> ()"), "closure in Model.load()")
        // Only the standard library's `Swift.`, not the end of a module's name.
        XCTAssertEqual(ReadableName.shortened("CucumberSwift.Cucumber.run(CucumberSwift.Step) -> ()"), "Cucumber.run(CucumberSwift.Step)")
        XCTAssertEqual(ReadableName.of("main"), "main")
    }

    func testARulesIssuesNameTheRuleAndAreAtItsLine() throws {
        let issue = try XCTUnwrap(report([0, 1, 2, 3, 4]).issues(file: file, line: 12, subject: "Rule").first)
        XCTAssertEqual(issue.line, 12)
        XCTAssertTrue(issue.message.hasPrefix("Rule coverage 50%: its scenarios ran 5 of the 10 regions"), issue.message)
    }
}
