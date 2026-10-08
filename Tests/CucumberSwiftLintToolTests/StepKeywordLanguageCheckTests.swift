@testable import CucumberSwiftGherkin
@testable import CucumberSwiftLintTool
import XCTest

/// The lint tool reads every step keyword of every language as CucumberSwift does, including a keyword
/// of more than one word, such as `Gegeben sei`, or with no space after it, such as `前提` (#363).
final class StepKeywordLanguageCheckTests: XCTestCase {
    func testEveryStepKeywordOfEveryLanguageStartsAStep() throws {
        let object = try JSONSerialization.jsonObject(with: Data(Language.languages.utf8))
        // Besides the languages, the data has a title and an empty "properties".
        let languages = try XCTUnwrap(object as? [String: Any]).compactMapValues { $0 as? [String: Any] }.filter { $0.value["feature"] != nil }
        XCTAssertGreaterThan(languages.count, 70)
        for (code, language) in languages {
            let feature = try XCTUnwrap((language["feature"] as? [String])?.first, code)
            let scenario = try XCTUnwrap((language["scenario"] as? [String])?.first, code)
            let forms = Set(["given", "when", "then", "and", "but"].flatMap { language[$0] as? [String] ?? [] }).sorted()
            let lines = ["# language: \(code)", "\(feature): A feature", "  \(scenario): A scenario"]
                + forms.map { "    \($0)1 step" }
            var messages = [String]()
            // With no step definition, every step the tool reads is undefined.
            FeatureChecker(file: "\(code).feature", definitions: []).check(contents: lines.joined(separator: "\n")) {
                messages.append("\($0.line):\($0.column) \($0.message)")
            }
            XCTAssertEqual(messages,
                           forms.indices.map { "\($0 + 4):5 Undefined step: no step definition matches \"1 step\"" },
                           code)
        }
    }
}
