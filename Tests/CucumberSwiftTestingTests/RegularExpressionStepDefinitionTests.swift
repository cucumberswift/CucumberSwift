//
//  RegularExpressionStepDefinitionTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Testing

/// The step definitions with a regular expression in a string, whose closure takes a `[String]`.
extension CucumberTests {
    @available(*, deprecated)
    @Test func theClosureTakesTheWholeMatchAndEachCaptureGroup() async {
        Given("I have (\\d+) (\\w+)") { [self] groups, _ in ran.append(groups.joined(separator: "|")) }
        await Cucumber.shared.run(scenario([step(.given, "I have 5 cukes", line: 3)]))
        #expect(ran == ["I have 5 cukes|5|cukes"])
    }

    @available(*, deprecated)
    @Test func theExpressionMatchesAnywhereWithoutRegardToCaseUnlessItIsAnchored() async {
        Given("CUKES") { [self] groups, _ in ran.append(groups.joined(separator: "|")) }
        Then("^cukes$") { [self] _, _ in ran.append("anchored") }
        And("^cukes$") { [self] _, _ in ran.append("never") }
        await Cucumber.shared.run(scenario([step(.given, "I have 5 cukes", line: 3), step(.then, "cukes", line: 4)]))
        #expect(ran == ["cukes", "anchored"])
    }

    @available(*, deprecated)
    @Test func aGroupThatTakesNoPartInTheMatchIsLeftOut() async {
        Given("a(x)?b") { [self] groups, _ in ran.append(groups.joined(separator: "|")) }
        await Cucumber.shared.run(scenario([step(.given, "ab", line: 3)]))
        #expect(ran == ["ab"])
    }

    @available(*, deprecated)
    @Test func aPatternThatDoesNotCompileIsReportedAtItsLineAndMatchesNothing() async {
        // A string literal would bind to the Cucumber expression overload, as with CucumberSwift.
        let pattern = "(unclosed"
        let line = #line + 1
        Given(pattern) { _, _ in }
        // Written outside any test, as `setupSteps()` runs while Swift Testing discovers them: nothing is
        // recorded until the Gherkin test reports it.
        await withKnownIssue {
            Cucumber.shared.reportInvalidStepDefinitions()
        } matching: { issue in
            issue.sourceLocation?.line == line
                && issue.sourceLocation?.filePath == #filePath
                && issue.comments.contains { $0.rawValue == "Invalid regular expression '(unclosed': expected ')'" }
        }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "(unclosed", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3
        }
    }

    @Test func anExpressionThatIsAnInvalidRegularExpressionIsReportedAtItsLineAndMatchesNothing() async {
        let line = #line + 1
        Given("^(unclosed$") { _, _ in }
        await withKnownIssue {
            Cucumber.shared.reportInvalidStepDefinitions()
        } matching: { issue in
            issue.sourceLocation?.line == line
                && issue.sourceLocation?.filePath == #filePath
                && issue.comments.contains { $0.rawValue.contains("^(unclosed$") }
        }
        // It matches nothing, and the step is undefined rather than trapping.
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "unclosed", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3
        }
    }

    @Test func validStepDefinitionsReportNothing() {
        Given("^I have (\\d+) cukes$") { _, _ in }
        Given("I have {int} apples") { _, _ in }
        Cucumber.shared.reportInvalidStepDefinitions()
        #expect(Cucumber.shared.invalidDefinitions.isEmpty)
    }
}
