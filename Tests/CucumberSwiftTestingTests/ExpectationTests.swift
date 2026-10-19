#if canImport(XCTest)
@testable import CucumberSwiftTesting
import Foundation
import Testing
import XCTest

/// `Cucumber.expectation(description:)` and `wait(for:timeout:)`, from synchronous and `async` steps. An
/// extension of `CucumberTests`, so that it runs one test at a time with the runner's other tests.
extension CucumberTests {
    private static let timedOutMessage = #"Asynchronous wait failed: Exceeded timeout of 0.1 seconds, with unfulfilled expectations: "never", "nor this"."#
    private static let invertedMessage = #"Fulfilled inverted expectation "inverted"."#

    private static func unfulfilledExpectations() -> [XCTestExpectation] {
        [Cucumber.shared.expectation(description: "never"), Cucumber.shared.expectation(description: "nor this")]
    }

    private static func invertedExpectation() -> XCTestExpectation {
        let expectation = Cucumber.shared.expectation(description: "inverted")
        expectation.isInverted = true
        expectation.fulfill()
        return expectation
    }

    private func scenario(texts: [String]) -> GherkinScenario {
        scenario(texts.enumerated().map { index, text in step(.given, text, line: 3 + index) })
    }

    @Test func aSynchronousWaitEndsWhenWorkOffTheMainActorFulfillsTheExpectation() async {
        Given("a background wait") { [self] _, _ in
            let expectation = Cucumber.shared.expectation(description: "background")
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
            Cucumber.shared.wait(for: [expectation], timeout: 5)
            ran.append("waited")
        }
        await Cucumber.shared.run(scenario(texts: ["a background wait"]))
        #expect(ran == ["waited"])
    }

    @Test func anAwaitedWaitLetsAMainActorTaskFulfillTheExpectation() async {
        Given("an awaited wait") { [self] _, _ in
            let expectation = Cucumber.shared.expectation(description: "main actor")
            Task { @MainActor [self] in
                ran.append("fulfilled")
                expectation.fulfill()
            }
            await Cucumber.shared.wait(for: [expectation], timeout: 5)
            ran.append("waited")
        }
        await Cucumber.shared.run(scenario(texts: ["an awaited wait"]))
        #expect(ran == ["fulfilled", "waited"])
    }

    @Test func anAwaitedWaitLetsMainQueueWorkFulfillTheExpectation() async {
        Given("an awaited wait") { [self] _, _ in
            let expectation = Cucumber.shared.expectation(description: "main queue")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                ran.append("fulfilled")
                expectation.fulfill()
            }
            await Cucumber.shared.wait(for: [expectation], timeout: 5)
            ran.append("waited")
        }
        await Cucumber.shared.run(scenario(texts: ["an awaited wait"]))
        #expect(ran == ["fulfilled", "waited"])
    }

    /// Runs a scenario whose first step, at line 3, is the wait that the test defined as "a wait", and expects
    /// it to fail there with `message`, and the next step to be skipped.
    private func expectTheWaitFails(with message: String) async {
        Then("the next step") { [self] _, _ in ran.append("next") }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a wait", line: 3), step(.then, "the next step", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.fileID == "Features/Test.feature" && issue.sourceLocation?.line == 3
                && issue.comments.map(\.rawValue) == [message]
        }
        #expect(ran == ["waited"])
    }

    @Test func aWaitThatTimesOutFailsTheStep() async {
        Given("a wait") { [self] _, _ in
            Cucumber.shared.wait(for: Self.unfulfilledExpectations(), timeout: 0.1)
            ran.append("waited")
        }
        await expectTheWaitFails(with: Self.timedOutMessage)
    }

    @Test func aWaitForAFulfilledInvertedExpectationFailsTheStep() async {
        Given("a wait") { [self] _, _ in
            Cucumber.shared.wait(for: [Self.invertedExpectation()], timeout: 0.1)
            ran.append("waited")
        }
        await expectTheWaitFails(with: Self.invertedMessage)
    }

    @Test func anAwaitedWaitThatTimesOutFailsTheStep() async {
        Given("a wait") { [self] _, _ in
            await Cucumber.shared.wait(for: Self.unfulfilledExpectations(), timeout: 0.1)
            ran.append("waited")
        }
        await expectTheWaitFails(with: Self.timedOutMessage)
    }

    @Test func anAwaitedWaitForAFulfilledInvertedExpectationFailsTheStep() async {
        Given("a wait") { [self] _, _ in
            await Cucumber.shared.wait(for: [Self.invertedExpectation()], timeout: 0.1)
            ran.append("waited")
        }
        await expectTheWaitFails(with: Self.invertedMessage)
    }
}
#endif
