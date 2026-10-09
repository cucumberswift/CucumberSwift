import XCTest
@testable import CucumberSwift

/// In Azerbaijani, `Nümunələr` is both a Scenario and an Examples keyword. Inside a scenario it is
/// Examples, and anywhere else a Scenario, as in cucumber-jvm's Gherkin parser (#364).
final class SharedHeaderKeywordTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        Gherkin.errors.removeAll()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testAnAzerbaijaniOutlinesNumunelerExamplesGiveEachRowAScenario() {
        let cucumber = Cucumber(withString: """
        # language: az
        Özəllik: Xiyar
          Ssenarinin strukturu: Yemək
            Verilir <start> xiyar
            Əgər <eat> xiyar yeyirəm
            Və <left> xiyar qalır

            Nümunələr:
              | start | eat | left |
              | 12    | 5   | 7    |
              | 20    | 5   | 15   |
        """)
        let scenarios = cucumber.features.first?.scenarios ?? []
        XCTAssertEqual(scenarios.map(\.title), ["Yemək (start: 12, eat: 5, left: 7)", "Yemək (start: 20, eat: 5, left: 15)"])
        XCTAssertEqual(scenarios.first?.steps.map(\.match), ["12 xiyar", "5 xiyar yeyirəm", "7 xiyar qalır"])
        XCTAssertEqual(scenarios.last?.steps.map(\.match), ["20 xiyar", "5 xiyar yeyirəm", "15 xiyar qalır"])
        XCTAssertEqual(Gherkin.errors.snapshot, [])
    }

    func testNumunelerAfterAFeatureABackgroundOrARuleStartsAScenarioInAzerbaijani() {
        let cucumber = Cucumber(withString: """
        # language: az
        Özəllik: Xiyar
          Nümunələr: Birinci
            Əgər bir xiyar yeyirəm

          Rule: Qayda
            Kontekst:
              Verilir bir səbət

            Nümunələr: İkinci
              Əgər iki xiyar yeyirəm

          Rule: Başqa qayda
            Nümunələr: Üçüncü
              Əgər üç xiyar yeyirəm
        """)
        let scenarios = cucumber.features.first?.scenarios ?? []
        XCTAssertEqual(scenarios.map(\.title), ["Birinci", "İkinci", "Üçüncü"])
        XCTAssertEqual(scenarios.map { $0.steps.map(\.match) }, [
            ["bir xiyar yeyirəm"],
            ["bir səbət", "iki xiyar yeyirəm"],
            ["üç xiyar yeyirəm"]
        ])
        XCTAssertEqual(Gherkin.errors.snapshot, [])
    }

    func testNumunelerAfterAScenariosStepsIsExamplesInAzerbaijani() {
        let azerbaijani = Cucumber(withString: """
        # language: az
        Özəllik: Xiyar
          Ssenari: Birinci
            Əgər bir xiyar yeyirəm

          Nümunələr:
            | a |
            | 1 |
        """)
        let english = Cucumber(withString: """
        Feature: Xiyar
          Scenario: Birinci
            When bir xiyar yeyirəm

          Examples:
            | a |
            | 1 |
        """)
        XCTAssertEqual(english.features.first?.scenarios.map(\.title), ["Birinci"])
        XCTAssertEqual(azerbaijani.features.first?.scenarios.map(\.title), ["Birinci"])
        XCTAssertEqual(Gherkin.errors.snapshot, [])
    }
}
