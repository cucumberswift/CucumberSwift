//
//  ScenarioTestNamesTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class ScenarioTestNamesTests: TemporaryFolderTestCase {
    private let voting = """
    Feature: Voting

      Scenario: An adult can vote
        Given a person aged 30
        Then the person can vote

      Scenario Outline: Ages
        Given a person aged <age>
        Then the person can vote: <vote>

        Examples:
          | age | vote  |
          | 5   | false |
          | 30  | true  |

      Scenario: An adult can vote
        Given a person aged 40
        Then the person can vote
    """

    private func write(_ text: String, to path: String) throws {
        let url = folder.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func id(_ line: Int, feature: String = "Features/Voting.feature") -> ScenarioID {
        ScenarioID(feature: feature, line: line, name: "")
    }

    func testNamesTheTestOfAScenarioByItsLineAsCucumberSwiftNamesItByDefault() throws {
        try write(voting, to: "Tests/Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.testNames(for: id(3)), ["Voting \u{203A} An adult can vote"])
    }

    func testAScenarioWhoseNameRepeatsAnEarlierOneGetsANumber() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.testNames(for: id(16)), ["Voting \u{203A} An adult can vote 2"])
    }

    func testAnOutlinesLineNamesEveryRowAndARowsLineNamesThatRow() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        let all = try names.testNames(for: id(7))
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.allSatisfy { $0.hasPrefix("Voting \u{203A} Ages") })
        XCTAssertEqual(try names.testNames(for: id(14)), [all[1]])
    }

    func testCamelCaseNamesAndTheConfiguredDelimiter() throws {
        try write(voting, to: "Features/Voting.feature")
        var classic = ScenarioTestNames(root: folder, readable: false)
        XCTAssertEqual(try classic.testNames(for: id(3)), ["Voting|AnAdultCanVote"])
        var custom = ScenarioTestNames(root: folder, readable: false, delimiter: "_")
        XCTAssertEqual(try custom.testNames(for: id(3)), ["Voting_AnAdultCanVote"])
    }

    func testReadsWhetherReadableNamesAreOffFromTheEnvironment() {
        XCTAssertTrue(ScenarioTestNames.readableTestNames(in: [:]))
        XCTAssertTrue(ScenarioTestNames.readableTestNames(in: ["CUCUMBER_READABLE_TEST_NAMES": "YES"]))
        XCTAssertFalse(ScenarioTestNames.readableTestNames(in: ["CUCUMBER_READABLE_TEST_NAMES": "NO"]))
        XCTAssertFalse(ScenarioTestNames.readableTestNames(in: ["CUCUMBER_READABLE_TEST_NAMES": "false"]))
    }

    func testSeveralScenariosGiveEachTestOnce() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.testNames(for: [id(3), id(3)]), ["Voting \u{203A} An adult can vote"])
    }

    func testRefusesALineThatIsNoScenarioAndAFileThatIsMissing() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertThrowsError(try names.testNames(for: id(4))) {
            XCTAssertTrue("\($0)".contains("no scenario at line 4"), "\($0)")
        }
        XCTAssertThrowsError(try names.testNames(for: id(3, feature: "Features/Missing.feature"))) {
            XCTAssertTrue("\($0)".contains("No feature file"), "\($0)")
        }
    }

    func testRefusesAPathThatFitsTwoFiles() throws {
        try write(voting, to: "A/Features/Voting.feature")
        try write(voting, to: "B/Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertThrowsError(try names.testNames(for: id(3))) {
            XCTAssertTrue("\($0)".contains("2 feature files"), "\($0)")
        }
    }

    func testRefusesTwoFeatureFilesWithOneTitleBecauseTheirNumbersCouldSwap() throws {
        try write(voting, to: "Features/Voting.feature")
        try write(voting, to: "Other/Elections.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertThrowsError(try names.testNames(for: id(3))) {
            XCTAssertTrue("\($0)".contains("both the feature \"Voting\""), "\($0)")
        }
    }
}
