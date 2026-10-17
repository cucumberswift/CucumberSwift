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
    @Test func aPatternThatDoesNotCompileFailsAtItsLineAndMatchesNothing() async {
        // A string literal would bind to the Cucumber expression overload, as with CucumberSwift.
        let pattern = "(unclosed"
        await withKnownIssue {
            Given(pattern) { _, _ in }
        } matching: { issue in
            issue.comments.contains { $0.rawValue.hasPrefix("Invalid regular expression '(unclosed'") }
        }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "(unclosed", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3
        }
    }
}
