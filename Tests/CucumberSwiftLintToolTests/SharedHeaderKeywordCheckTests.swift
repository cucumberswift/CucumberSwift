@testable import CucumberSwiftLintTool
import XCTest

/// In Azerbaijani, `Nümunələr` is both a Scenario and an Examples keyword. Inside a scenario the lint
/// tool reads it as Examples, and anywhere else as a Scenario, as CucumberSwift does (#364).
final class SharedHeaderKeywordCheckTests: LintTestCase {
    func testAnAzerbaijaniOutlinesNumunelerAreItsExamples() throws {
        let messages = try lint("""
        # language: az
        Özəllik: Xiyar
          Ssenarinin strukturu: Yemək
            Əgər <eat> xiyar yeyirəm
            Nümunələr:
              | eat |
              | 5   |
              | 7   |
        """, steps: #"When("{int} xiyar yeyirəm") { _, _ in }"#)
        XCTAssertEqual(messages, [])
    }

    func testAzerbaijaniExamplesMayFollowAPlainScenario() throws {
        let messages = try lint("""
        # language: az
        Özəllik: Xiyar
          Ssenari: Birinci
            Əgər bir xiyar yeyirəm
          Nümunələr:
            | a |
            | 1 |
        """)
        XCTAssertEqual(messages, [])
    }

    func testNumunelerAfterAFeatureABackgroundOrARuleIsAScenarioInAzerbaijani() throws {
        let messages = try lint("""
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
        """, steps: """
        Given("bir səbət") { _, _ in }
        When("{word} xiyar yeyirəm") { _, _ in }
        """)
        XCTAssertEqual(messages, [])
    }
}
