//
//  ScenarioTestNamesTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import CucumberSwiftGherkin
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

    func testRefusesTwoFeatureTitlesThatMakeOneSuiteName() throws {
        try write("Feature: Pay now\n\n  Scenario: Pay\n    Given a card\n", to: "Features/A.feature")
        try write("Feature: Pay-now\n\n  Scenario: Pay\n    Given a card\n", to: "Features/B.feature")
        var names = ScenarioTestNames(root: folder)
        for feature in ["Features/A.feature", "Features/B.feature"] {
            XCTAssertThrowsError(try names.swiftTestingIdentifier(for: id(3, feature: feature))) {
                XCTAssertTrue("\($0)".contains("could be either one's"), "\($0)")
            }
            XCTAssertThrowsError(try names.testNames(for: id(3, feature: feature)))
        }
    }

    func testRefusesTwoTitlesThatMakeOneSuiteNameOnlyAfterTheFallbackForAReservedName() throws {
        // The plugin can't name a suite `Test`, so it names it `Feature`, as it does a feature titled `Feature`.
        try write("Feature: Feature\n\n  Scenario: Pay\n    Given a card\n", to: "Features/A.feature")
        try write("Feature: Test\n\n  Scenario: Pay\n    Given a card\n", to: "Features/B.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertThrowsError(try names.swiftTestingIdentifier(for: id(3, feature: "Features/A.feature"))) {
            XCTAssertTrue("\($0)".contains("could be either one's"), "\($0)")
        }
        XCTAssertThrowsError(try names.swiftTestingIdentifier(for: id(3, feature: "Features/B.feature")))
    }

    func testRefusesTwoFeatureFilesWithOneTitleBecauseTheirNumbersCouldSwap() throws {
        try write(voting, to: "Features/Voting.feature")
        try write(voting, to: "Other/Elections.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertThrowsError(try names.testNames(for: id(3))) {
            XCTAssertTrue("\($0)".contains("the features \"Voting\" and \"Voting\""), "\($0)")
        }
    }

    func testSeesWhichRunnerRunsAFeatureFromTheSwiftFilesNextToIt() throws {
        try write(voting, to: "XC/Features/Voting.feature")
        try write("import CucumberSwift\n", to: "XC/Steps.swift")
        try write(voting.replacingOccurrences(of: "Voting", with: "Retiring"), to: "ST/Features/Retiring.feature")
        try write("import CucumberSwiftTesting\nimport Testing\n", to: "ST/Steps.swift")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.runner(for: id(3, feature: "XC/Features/Voting.feature")), .xctest)
        XCTAssertEqual(try names.runner(for: id(3, feature: "ST/Features/Retiring.feature")), .swiftTesting)
    }

    func testNamesTheSwiftTestingTestOfAScenarioAsThePluginGeneratesIt() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.swiftTestingIdentifier(for: id(3)), "CucumberFeatures/Voting/AnAdultCanVote(_:)")
        XCTAssertEqual(try names.swiftTestingIdentifier(for: id(16)), "CucumberFeatures/Voting/AnAdultCanVote_2(_:)", "A repeated name gets a number")
    }

    func testNamesTheSwiftTestingTestOfATitleWithNoLettersAReservedTitleAndANonASCIITitle() throws {
        // The plugin names a test `Scenario` when the title gives no name or a reserved one, numbered as a repeat.
        try write("""
        Feature: Names

          Scenario:
            Given a card

          Scenario: !!!
            Given a card

          Scenario: Test
            Given a card

          Scenario: \u{DC}berweisung
            Given a card
        """, to: "Features/Names.feature")
        var names = ScenarioTestNames(root: folder)
        let identifiers = try [3, 6, 9, 12].map { try names.swiftTestingIdentifier(for: id($0, feature: "Features/Names.feature")) }
        let letters = FeatureFile.typeName(for: "\u{DC}berweisung")
        XCTAssertEqual(identifiers, [
            "CucumberFeatures/Names/Scenario(_:)",
            "CucumberFeatures/Names/Scenario_2(_:)",
            "CucumberFeatures/Names/Scenario_3(_:)",
            "CucumberFeatures/Names/\(letters)(_:)"
        ])
        XCTAssertEqual(letters, "\u{DC}berweisung", "The plugin keeps a letter outside ASCII in a name")
    }

    func testAnOutlineIsOneSwiftTestingTestWhicheverLineOfItIsGiven() throws {
        try write(voting, to: "Features/Voting.feature")
        var names = ScenarioTestNames(root: folder)
        XCTAssertEqual(try names.swiftTestingIdentifier(for: id(7)), "CucumberFeatures/Voting/Ages(_:)")
        XCTAssertEqual(try names.swiftTestingIdentifier(for: id(14)), "CucumberFeatures/Voting/Ages(_:)")
        XCTAssertThrowsError(try names.swiftTestingIdentifier(for: id(2))) {
            XCTAssertTrue("\($0)".contains("no scenario at line 2"), "\($0)")
        }
    }
}
#endif
