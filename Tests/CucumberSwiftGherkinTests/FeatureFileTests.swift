import CucumberSwiftGherkin
import XCTest

final class FeatureFileTests: XCTestCase {
    func parse(_ text: String) throws -> FeatureFile.Feature {
        let file = FeatureFile(parsing: text, uri: "Test.feature")
        XCTAssertEqual(file.problems, [])
        return try XCTUnwrap(file.features.first)
    }

    func testAFeatureHasItsTitleDescriptionTagsAndLine() throws {
        let feature = try parse("""
        @smoke
        Feature: Eating
          Some description
          on two lines

          Scenario: One
            Given a step
        """)
        XCTAssertEqual(feature.title, "Eating")
        XCTAssertEqual(feature.description, "Some description\non two lines\n")
        XCTAssertEqual(feature.tags, ["smoke"])
        XCTAssertEqual(feature.line, 1)
        XCTAssertEqual(feature.scenarios.map(\.title), ["One"])
    }

    func testAScenarioHasTheBackgroundStepsFirstAndTheFeatureTags() throws {
        let feature = try parse("""
        @f
        Feature: F
          Background:
            Given a background step

          @s
          Scenario: S
            When a step
            Then another step
        """)
        let scenario = try XCTUnwrap(feature.scenarios.first)
        XCTAssertEqual(scenario.tags, ["f", "s"])
        XCTAssertNil(scenario.examples)
        XCTAssertEqual(scenario.steps.map(\.text), ["a background step", "a step", "another step"])
        XCTAssertEqual(scenario.steps.map(\.line), [4, 8, 9])
        XCTAssertEqual(scenario.steps.map(\.column), [5, 5, 5])
    }

    func testAndButAndStarStepsContinueThePrimaryKeywordBeforeThem() throws {
        let feature = try parse("""
        Feature: F
          Scenario: S
            Given a step
            And another
            When something happens
            But not this
            * any step
        """)
        let steps = try XCTUnwrap(feature.scenarios.first?.steps)
        XCTAssertEqual(steps.map(\.keywords), [
            [.given],
            [.and, .given],
            [.when],
            [.but, .when],
            [.given, .when, .then, .and, .but]
        ])
    }

    func testAStepHasItsDocStringAndDataTable() throws {
        let feature = try parse("""
        Feature: F
          Scenario: S
            Given a document
              ```json
              {"a": 1}
              ```
            And a table
              | name | price |
              | cukes | 5    |
        """)
        let steps = try XCTUnwrap(feature.scenarios.first?.steps)
        XCTAssertEqual(steps[0].docString?.literal, "{\"a\": 1}")
        XCTAssertEqual(steps[0].docString?.contentType, "json")
        XCTAssertNil(steps[0].dataTable)
        XCTAssertNil(steps[1].docString)
        XCTAssertEqual(steps[1].dataTable, [["name", "price"], ["cukes", "5"]])
    }

    func testAScenarioOutlineHasAnExampleForEachRow() throws {
        let feature = try parse("""
        Feature: F
          Background:
            Given a background step

          Scenario Outline: Eat <eat> of <start>
            Given there are <start> cucumbers
            When I eat <eat> cucumbers
            Then I have this left
              | left   |
              | <left> |

            @small
            Examples:
              | start | eat | left |
              | 12    | 5   | 7    |

            @large
            Examples:
              | start | eat | left |
              | 20    | 5   | 15   |
        """)
        let outline = try XCTUnwrap(feature.scenarios.first)
        XCTAssertEqual(outline.title, "Eat <eat> of <start>")
        XCTAssertEqual(outline.tags, [])
        XCTAssertEqual(outline.steps, [])
        let examples = try XCTUnwrap(outline.examples)
        XCTAssertEqual(examples.map(\.title), ["Eat 5 of 12 (left: 7)", "Eat 5 of 20 (left: 15)"])
        XCTAssertEqual(examples.map(\.line), [15, 20])
        XCTAssertEqual(examples.map(\.tags), [["small"], ["large"]])
        XCTAssertEqual(examples[0].steps.map(\.text), ["a background step", "there are 12 cucumbers", "I eat 5 cucumbers", "I have this left"])
        XCTAssertEqual(examples[0].steps.map(\.line), [3, 6, 7, 8])
        XCTAssertEqual(examples[1].steps.last?.dataTable, [["left"], ["15"]])
    }

    func testARuleHasItsOwnBackground() throws {
        let feature = try parse("""
        Feature: F
          Background:
            Given the feature's background

          Rule: R
            Background:
              Given the rule's background

            Scenario: S
              Then a step
        """)
        XCTAssertEqual(feature.scenarios.first?.steps.map(\.text), ["the feature's background", "the rule's background", "a step"])
    }

    func testALocalizedFeatureFileIsReadInItsLanguage() throws {
        let feature = try parse("""
        # language: es
        Característica: Comer
          Escenario: Uno
            Dado un paso
            Y otro paso
            Entonces un resultado
        """)
        XCTAssertEqual(feature.title, "Comer")
        let steps = try XCTUnwrap(feature.scenarios.first?.steps)
        XCTAssertEqual(steps.map(\.text), ["un paso", "otro paso", "un resultado"])
        XCTAssertEqual(steps.map(\.keywords), [[.given], [.and, .given], [.then]])
    }

    // Swift Testing's messages name a step with its keyword as written, as CucumberSwift's do (#332).
    func testAStepsKeywordNameIsItsKeywordAsWritten() throws {
        let english = try parse("""
        Feature: F
          Scenario: S
            Given a step
            And another
            But not this
        """)
        XCTAssertEqual(english.scenarios.first?.steps.map(\.keywordName), ["Given", "And", "But"])
        let spanish = try parse("""
        # language: es
        Característica: Una cesta de pepinos
          Escenario: Llenar la cesta
            Dado tengo 4 pepinos en mi "cesta"
            Y como 1 pepino
            * tengo hambre
        """)
        XCTAssertEqual(spanish.scenarios.first?.steps.map(\.keywordName), ["Dado", "Y", "*"])
    }

    func testTheNextFileStartsInEnglishAgain() throws {
        _ = FeatureFile(parsing: "# language: es\nCaracterística: Comer\n  Escenario: Uno\n    Dado un paso\n", uri: "es.feature")
        let feature = try parse("Feature: F\n  Scenario: S\n    Given a step\n")
        XCTAssertEqual(feature.scenarios.first?.steps.first?.keywords, [.given])
    }

    func testFilesParsedAtTheSameTimeKeepTheirOwnLanguageAndProblems() {
        let texts = [
            ("en.feature", "Feature: F\n  Scenario: S\n    Given a step\n"),
            ("es.feature", "# language: es\nCaracterística: Comer\n  Escenario: Uno\n    Dado un paso\n"),
            ("xx.feature", "# language: xx\nFeature: F\n  Scenario: S\n    Given a step\n")
        ]
        let expected = texts.map { FeatureFile(parsing: $0.1, uri: $0.0) }
        let lock = NSLock()
        var results = [FeatureFile?](repeating: nil, count: 90)
        DispatchQueue.concurrentPerform(iterations: results.count) { iteration in
            let (uri, text) = texts[iteration % texts.count]
            let file = FeatureFile(parsing: text, uri: uri)
            lock.lock()
            results[iteration] = file
            lock.unlock()
        }
        for (iteration, file) in results.enumerated() {
            XCTAssertEqual(file, expected[iteration % texts.count], "Iteration \(iteration)")
        }
    }

    func testAnUnsupportedLanguageIsAProblem() {
        let file = FeatureFile(parsing: "# language: xx\nFeature: F\n  Scenario: S\n    Given a step\n", uri: "Test.feature")
        XCTAssertEqual(file.problems, ["File: Test.feature declares an unsupported language"])
    }

    func testProblemsAreOnlyThoseOfTheFileParsed() {
        _ = FeatureFile(parsing: "# language: xx\nFeature: F\n", uri: "First.feature")
        XCTAssertEqual(FeatureFile(parsing: "Feature: F\n  Scenario: S\n    Given a step\n", uri: "Second.feature").problems, [])
    }
}
