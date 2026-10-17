//
//  LocalizedStepDefinitionTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Testing

/// The localized step types, with the runner.
extension CucumberTests {
    func localizedStep(_ keyword: Step.Keyword, _ keywordName: String, _ text: String, line: Int) -> GherkinStep {
        GherkinStep(keyword: keyword, keywordName: keywordName, text: text, line: line, column: 5, suggestion: "")
    }

    @Test func aLocalizedStepDefinitionMatchesTheStepsOfItsKeyword() async {
        ES_Dado("tengo {int} pepinos") { [self] match, _ in ran.append("dado \(try match.first(\.int))") }
        ES_Cuando("como {int}") { [self] match, _ in ran.append("cuando \(try match.first(\.int))") }
        ES_Entonces("me quedan {int}") { [self] match, _ in ran.append("entonces \(try match.first(\.int))") }
        ES_Y("tengo hambre") { [self] _, _ in ran.append("y") }

        await Cucumber.shared.run(scenario([
            localizedStep(.given, "Dado", "tengo 5 pepinos", line: 4),
            localizedStep([.and, .given], "Y", "tengo hambre", line: 5),
            localizedStep(.when, "Cuando", "como 2", line: 6),
            localizedStep(.then, "Entonces", "me quedan 3", line: 7)
        ]))
        #expect(ran == ["dado 5", "y", "cuando 2", "entonces 3"])
    }

    @Test func aLocalizedStepDefinitionDoesNotMatchAStepOfAnotherKeyword() async {
        ES_Entonces("tengo {int} pepinos") { [self] _, _ in ran.append("entonces") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([localizedStep(.given, "Dado", "tengo 5 pepinos", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.line == 4
        }
        #expect(ran.isEmpty)
    }
}
