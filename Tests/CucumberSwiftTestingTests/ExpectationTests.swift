#if canImport(XCTest)
@testable import CucumberSwiftTesting
import Foundation
import Testing
import XCTest

/// `Cucumber.expectation(description:)` and `wait(for:timeout:)`, from synchronous and `async` steps. An
/// extension of `CucumberTests`, so that it runs one test at a time with the runner's other tests.
extension CucumberTests {
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

    /// As with CucumberSwift, whose `XCTWaiter` has no delegate to tell.
    @Test func aWaitThatTimesOutDoesNotFailTheStep() async {
        Given("a sync timeout") { [self] _, _ in
            Cucumber.shared.wait(for: [Cucumber.shared.expectation(description: "never")], timeout: 0.1)
            ran.append("sync")
        }
        Then("an async timeout") { [self] _, _ in
            await Cucumber.shared.wait(for: [Cucumber.shared.expectation(description: "never")], timeout: 0.1)
            ran.append("async")
        }
        await Cucumber.shared.run(scenario([step(.given, "a sync timeout", line: 3), step(.then, "an async timeout", line: 4)]))
        #expect(ran == ["sync", "async"])
    }
}
#endif
