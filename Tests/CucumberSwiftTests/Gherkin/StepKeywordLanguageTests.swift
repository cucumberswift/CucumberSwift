import Foundation
import XCTest
@testable import CucumberSwift

/// Every step keyword of every language in the Gherkin language data starts a step, including a keyword
/// of more than one word, such as `Gegeben sei`, or with no space after it, such as `前提` (#363).
final class StepKeywordLanguageTests: XCTestCase {
    /// The step keywords of one language, as the language data writes them, such as `Gegeben sei `.
    struct StepKeywords {
        let code: String
        let feature: String
        let scenario: String
        let forms: [String]
    }

    static let languages: [StepKeywords] = {
        guard let object = try? JSONSerialization.jsonObject(with: Data(Language.languages.utf8)),
              let json = object as? [String: Any] else { return [] }
        return json.compactMap { code, value -> StepKeywords? in
            guard let language = value as? [String: Any],
                  let feature = (language["feature"] as? [String])?.first,
                  let scenario = (language["scenario"] as? [String])?.first else { return nil }
            let forms = ["given", "when", "then", "and", "but"].flatMap { language[$0] as? [String] ?? [] }
            return StepKeywords(code: code, feature: feature, scenario: scenario, forms: Array(Set(forms)).sorted())
        }
        .sorted { $0.code < $1.code }
    }()

    // Starts no step in any language, and no keyword ends in a digit.
    static let text = "1 cucumber"

    /// The keyword `line` starts with as the parser should read it: the longest form it starts with, as
    /// written in `line`.
    static func keyword(of line: String, in language: StepKeywords) -> String {
        let form = language.forms
            .filter { line.lowercased().hasPrefix($0.lowercased()) }
            .max { $0.count < $1.count } ?? ""
        return String(line.prefix(form.trimmingCharacters(in: .whitespaces).count))
    }

    override func tearDownWithError() throws {
        Scope.language = .default
    }

    func testAMultiWordKeywordStartsAStep() {
        let cucumber = Cucumber(withString: """
        # language: de
        Funktionalität: Korb
          Szenario: Gurken
            Gegeben sei ich habe 3 Gurken
            Dann habe ich 3 Gurken
        """)
        let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }
        XCTAssertEqual(steps.map(\.match), ["ich habe 3 Gurken", "habe ich 3 Gurken"])
        XCTAssertEqual(steps.map { $0.keyword.toString() }, ["Gegeben sei", "Dann"])
    }

    func testEveryStepKeywordOfEveryLanguageStartsAStep() throws {
        XCTAssertGreaterThan(Self.languages.count, 70)
        for language in Self.languages {
            // A keyword written with no space after it starts a step with or without one.
            let lines = language.forms.map { $0 + Self.text }
                + language.forms.filter { $0.last != " " }.map { $0 + " " + Self.text }
            let cucumber = Cucumber(withString: """
            # language: \(language.code)
            \(language.feature): A feature
              \(language.scenario): A scenario
            \(lines.map { "    " + $0 }.joined(separator: "\n"))
            """)
            let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }
            XCTAssertEqual(steps.map(\.match), lines.map { _ in Self.text }, language.code)
            XCTAssertEqual(steps.map { $0.keyword.toString() },
                           lines.map { line in Self.keyword(of: line, in: language) },
                           language.code)
        }
    }

    func testAStepKeywordStartsAStepInAnyCase() throws {
        XCTAssertEqual(Scope.scopeFor(str: "GEGEBEN SEI ich habe Gurken", in: try XCTUnwrap(Language("de"))), .step(.given))
        XCTAssertEqual(Scope.scopeFor(str: "given I have cukes"), .step(.given))
    }

    func testTheLongestKeywordALineStartsWithIsItsKeyword() throws {
        let german = try XCTUnwrap(Language("de"))
        XCTAssertEqual(german.stepKeyword(startingLine: "Gegeben seien die Gurken"), "Gegeben seien")
        XCTAssertEqual(german.stepKeyword(startingLine: "Gegeben sei die Gurke"), "Gegeben sei")
        let french = try XCTUnwrap(Language("fr"))
        XCTAssertEqual(french.stepKeyword(startingLine: "Et que j'ai un concombre"), "Et que")
        XCTAssertEqual(french.stepKeyword(startingLine: "Et j'ai un concombre"), "Et")
        XCTAssertEqual(french.stepKeyword(startingLine: "Étant donné qu'il y a un concombre"), "Étant donné qu'")
    }

    // A keyword the language data writes with a space after it is only a keyword when the space follows,
    // or when it ends the line, so ordinary description lines are still descriptions.
    func testADescriptionLineIsNotAStepInAnyLanguage() {
        for language in Self.languages {
            let spaced = language.forms.filter { $0.last == " " && $0 != "* " }
            let lines = ["Lorem ipsum dolor sit amet."]
                + spaced.map { $0.trimmingCharacters(in: .whitespaces) + Self.text }
                    // Such as Czech `A také` without its space, which starts with the keyword `A `.
                    .filter { line in !language.forms.contains { line.lowercased().hasPrefix($0.lowercased()) } }
            let cucumber = Cucumber(withString: """
            # language: \(language.code)
            \(language.feature): A feature
              \(language.scenario): A scenario
            \(lines.map { "    " + $0 }.joined(separator: "\n"))
            """)
            let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }
            XCTAssertEqual(steps.map(\.match), [], language.code)
        }
    }

    func testAKeywordAloneOnItsLineStartsAStep() throws {
        let german = try XCTUnwrap(Language("de"))
        XCTAssertEqual(german.stepKeyword(startingLine: "Gegeben sei"), "Gegeben sei")
        XCTAssertNil(german.stepKeyword(startingLine: "Gegeben seid"))
        XCTAssertEqual(Scope.scopeFor(str: "Given"), .step(.given))
    }
}
