import XCTest
@testable import CucumberSwift

/// `Cucumber.wait(for:timeout:)` in an async step: the synchronous form holds the main actor, so work on it
/// or on the main queue can't fulfill the expectation, and the form written with `await` can.
class AsyncWaitTests: XCTestCase {
    override func setUpWithError() throws { Cucumber.shared.reset() }

    private func run(_ body: @escaping @MainActor () async -> Void) {
        let outcome = AsyncStepRunner.wait(timeout: 10, cancelOnFailure: false, hasFailed: { false }, body: { await body() })
        guard case .finished = outcome else { return XCTFail("Expected .finished, got \(outcome)") }
    }

    func testAnAwaitedWaitLetsMainQueueWorkFulfillTheExpectation() {
        var fulfilled = false
        run {
            let expectation = Cucumber.shared.expectation(description: "main queue")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { fulfilled = true; expectation.fulfill() }
            await Cucumber.shared.wait(for: [expectation], timeout: 5)
        }
        XCTAssert(fulfilled)
    }

    func testAnAwaitedWaitLetsAMainActorTaskFulfillTheExpectation() {
        var fulfilled = false
        run {
            let expectation = Cucumber.shared.expectation(description: "main actor")
            Task { @MainActor in fulfilled = true; expectation.fulfill() }
            await Cucumber.shared.wait(for: [expectation], timeout: 5)
        }
        XCTAssert(fulfilled)
    }

    func testAnAwaitedWaitThatTimesOutReturns() {
        run { await Cucumber.shared.wait(for: [Cucumber.shared.expectation(description: "never")], timeout: 0.1) }
    }
}
