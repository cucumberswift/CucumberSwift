@testable import CucumberSwift
import CucumberSwiftGherkin
import XCTest

/// `FeatureFile` must read every feature file the way CucumberSwift does, because build tools use it
/// to describe the scenarios CucumberSwift runs. These tests only parse; they run no scenarios.
final class ParserParityTests: XCTestCase {
    /// A scenario as CucumberSwift runs it. Each example of a Scenario Outline is one.
    struct RunnableScenario: Equatable {
        let title: String
        let tags: [String]
        let line: Int
        let column: Int
        let steps: [RunnableStep]
    }

    struct RunnableStep: Equatable {
        let keywords: [String]
        let keywordName: String
        let text: String
        let line: Int
        let column: Int
        let docString: String?
        let rawDocString: String?
        let contentType: String?
        let dataTable: [[String]]?
        /// The step definition suggested when no step definition matches the step.
        let suggestion: String
    }

    static let failure = "XCTFail(\"Step not implemented: replace this line with your test code\")"

    /// Every feature file in the repository's tests, including the Gherkin test data, good and bad.
    var featureFiles: [URL] {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let files = FileManager.default.enumerator(at: tests, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "feature" && !$0.pathComponents.contains(".build") } ?? []
        return files.sorted { $0.path < $1.path }
    }

    func testEveryFeatureFileReadsAsCucumberSwiftReadsIt() throws {
        XCTAssertGreaterThan(featureFiles.count, 40)
        var scenarioCount = 0
        for file in featureFiles {
            let text = try String(contentsOf: file, encoding: .utf8)

            Gherkin.errors.removeAll()
            let features = Cucumber(withString: text).features
            let cucumberSwiftProblems = Gherkin.errors.snapshot
            Gherkin.errors.removeAll()
            let featureFile = FeatureFile(parsing: text, uri: "")

            let name = file.lastPathComponent
            XCTAssertEqual(featureFile.problems, cucumberSwiftProblems, name)
            XCTAssertEqual(featureFile.features.map(\.title), features.map(\.title), name)
            XCTAssertEqual(featureFile.features.map(\.description), features.map(\.desc), name)
            XCTAssertEqual(featureFile.features.map(\.tags), features.map(\.tags), name)
            XCTAssertEqual(featureFile.features.map(\.line), features.map { Int($0.location.line) }, name)
            XCTAssertEqual(featureFile.features.map { runnable($0) }, features.map { runnable($0) }, name)
            scenarioCount += features.flatMap(\.scenarios).count
        }
        // 79 when this was written; fewer means the comparison stopped seeing some scenarios.
        XCTAssertGreaterThanOrEqual(scenarioCount, 79)
    }

    func runnable(_ feature: FeatureFile.Feature) -> [RunnableScenario] {
        feature.scenarios.flatMap { scenario -> [RunnableScenario] in
            guard let examples = scenario.examples else {
                let runnableScenario = RunnableScenario(
                    title: scenario.title,
                    tags: scenario.tags,
                    line: scenario.line,
                    column: scenario.column,
                    steps: scenario.steps.map(runnable))
                return [runnableScenario]
            }
            return examples.map {
                RunnableScenario(title: $0.title, tags: $0.tags, line: $0.line, column: $0.column, steps: $0.steps.map(runnable))
            }
        }
    }

    func runnable(_ step: FeatureFile.Step) -> RunnableStep {
        RunnableStep(
            keywords: step.keywords.map(\.rawValue).sorted(),
            keywordName: step.keywordName,
            text: step.text,
            line: step.line,
            column: step.column,
            docString: step.docString?.literal,
            rawDocString: step.docString?.rawLiteral,
            contentType: step.docString?.contentType,
            dataTable: step.dataTable,
            suggestion: step.suggestedStepDefinition(failure: Self.failure))
    }

    func runnable(_ feature: Feature) -> [RunnableScenario] {
        feature.scenarios.map { scenario in
            RunnableScenario(
                title: scenario.title,
                tags: scenario.tags,
                line: Int(scenario.location.line),
                column: Int(scenario.location.column),
                steps: scenario.steps.map(runnable))
        }
    }

    func runnable(_ step: Step) -> RunnableStep {
        let keywords: [(String, Step.Keyword)] = [("given", .given), ("when", .when), ("then", .then), ("and", .and), ("but", .but)]
        let suggestion = StubGenerator.method(
            for: step.match,
            keyword: step.keyword,
            hasDataTable: step.dataTable != nil,
            hasDocString: step.docString != nil,
            style: .cucumberExpression)
        return RunnableStep(
            keywords: keywords.filter { step.keyword.contains($0.1) }.map(\.0).sorted(),
            keywordName: step.keywordText,
            text: step.match,
            line: Int(step.location.line),
            column: Int(step.location.column),
            docString: step.docString?.literal,
            rawDocString: step.docString?.rawLiteral,
            contentType: step.docString?.contentType,
            dataTable: step.dataTable?.rows,
            suggestion: suggestion.generateSwift())
    }
}
