//
//  SkippedScenarioTests.swift
//  CucumberSwiftTestingTests
//
// A step that throws `XCTSkip`, or calls `Test.cancel`, skips the rest of its scenario, as `XCTSkip` does
// with CucumberSwift (#470): the later steps don't run, the step is reported as skipped, the scenario as
// passed, and the after hooks still run.

@testable import CucumberSwiftTesting
import Foundation
import Testing
#if canImport(XCTest)
import XCTest
#endif

extension CucumberTests {
    private var checkout: GherkinScenario {
        scenario([
            step(.given, "a basket", line: 3),
            step(.when, "I pay by card", line: 4),
            step(.then, "the order is paid", line: 5)
        ])
    }

    private func useOneTestPerScenario(_ isOn: Bool) {
        Cucumber.readableTestNames = nil
        Cucumber.oneTestPerScenario = nil
        Cucumber.shared.environment = isOn ? ["CUCUMBER_ONE_TEST_PER_SCENARIO": "YES"] : [:]
    }

    /// Runs each case, and returns why each was skipped, or `nil` for one that wasn't. Swift 6.3 skips a case
    /// by cancelling it, which throws; before it nothing can, and no case throws.
    private func skipReasons(of cases: [ScenarioCase]) async -> [String?] {
        var reasons = [String?]()
        for testCase in cases {
            do {
                try await Cucumber.shared.run(testCase)
                reasons.append(nil)
            } catch {
                reasons.append(Cucumber.skipReason(of: error) ?? "not a skip: \(error)")
            }
        }
        return reasons
    }

    /// Step definitions for `checkout` whose card step skips with `skip`, and hooks that say they ran.
    private func registerCheckout(skip: @escaping @MainActor () throws -> Void) {
        AfterStep { [self] step in ran.append("after \(step.match)") }
        AfterScenario { [self] _ in ran.append("after scenario") }
        Given("a basket") { [self] _, _ in ran.append("basket") }
        When("I pay by card") { [self] _, _ in
            ran.append("card")
            try skip()
        }
        Then("the order is paid") { [self] _, _ in ran.append("paid") }
    }

    /// Only `XCTSkip` and what `Test.cancel` throws skip: any other error fails the step, a cancellation or a
    /// timeout included, as does `Test.cancel`'s error if Swift Testing ever renames its type.
    @Test func anErrorThatIsNotASkipHasNoSkipReason() {
        struct Failure: Error {}
        struct SkipInfo: Error {}
        #expect(Cucumber.skipReason(of: Failure()) == nil)
        #expect(Cucumber.skipReason(of: CancellationError()) == nil)
        #expect(Cucumber.skipReason(of: StepTimeoutError(timeout: 1)) == nil)
        #expect(Cucumber.skipReason(of: SkipInfo()) == nil)
    }

    #if canImport(XCTest)
    @Test func aStepThatThrowsXCTSkipSkipsTheRestOfItsScenarioAndTheAfterHooksStillRun() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        registerCheckout { throw XCTSkip("The card terminal is offline") }

        await Cucumber.shared.run(checkout)

        #expect(ran == ["basket", "after a basket", "card", "after I pay by card", "after scenario"])
        // As CucumberSwift reports it: the step that skipped is skipped, the later steps never start, and
        // the scenario passes.
        #expect(observer.log.filter { !$0.hasPrefix("feature") } == [
            "scenario started S",
            "step started Given a basket",
            "step passed",
            "step started Given I pay by card",
            "step skipped",
            "scenario passed S"
        ])
    }

    @Test func eachCaseAfterAStepThatThrowsXCTSkipIsSkippedWithItsReason() async {
        useOneTestPerScenario(false)
        registerCheckout { throw XCTSkip("The card terminal is offline") }

        let reasons = await skipReasons(of: Cucumber.shared.casesToRun(checkout))

        #expect(ran == ["basket", "after a basket", "card", "after I pay by card", "after scenario"])
        #if compiler(>=6.3)
        // As CucumberSwift skips the tests: the step's with its reason, the later ones saying why.
        #expect(reasons == [nil, "The card terminal is offline", "Skipped: The card terminal is offline"])
        #else
        #expect(reasons == [nil, nil, nil])
        #endif
    }

    @Test func aScenarioThatIsOneTestIsSkippedWhenAStepThrowsXCTSkip() async {
        useOneTestPerScenario(true)
        registerCheckout { throw XCTSkip("The card terminal is offline") }

        let reasons = await skipReasons(of: Cucumber.shared.casesToRun(checkout))

        #expect(ran == ["basket", "after a basket", "card", "after I pay by card", "after scenario"])
        #if compiler(>=6.3)
        #expect(reasons == ["The card terminal is offline"])
        #else
        #expect(reasons == [nil])
        #endif
        useOneTestPerScenario(false)
    }

    #if compiler(>=6.2)
    /// As with CucumberSwift, a step that has failed stays failed when it then throws `XCTSkip`, and so does its
    /// scenario. The runner learns of the failed `#expect` from Swift Testing 6.2's issue handling.
    @Test(.reportedInFeatureFiles)
    func aStepThatFailsAnExpectationAndThenThrowsXCTSkipStaysFailed() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        registerCheckout {
            #expect(Bool(false), "The card was declined")
            throw XCTSkip("The card terminal is offline")
        }

        await withKnownIssue {
            await Cucumber.shared.run(checkout)
        }

        #expect(ran == ["basket", "after a basket", "card", "after I pay by card", "after scenario"])
        #expect(observer.log.contains { $0.hasPrefix("step failed") })
        #expect(observer.log.contains("scenario failed S"))
    }
    #endif
    #endif

    #if compiler(>=6.3)
    /// `Test.cancel` cancels the test case's task. The hooks after it still run on the main actor, in order and
    /// once each, AfterStep before AfterScenario, and one that waits isn't cut short, as its timeout would be in
    /// a cancelled task. The scenario ends only once they have.
    @Test func aStepThatCallsTestCancelSkipsTheRestOfItsScenarioAndTheAfterHooksStillRun() async {
        useOneTestPerScenario(true)
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        registerCheckout { try Test.cancel("The card terminal is offline") }
        AfterStep { [self] step in
            try await Task.sleep(nanoseconds: 1_000_000)
            MainActor.assertIsolated()
            ran.append("after waiting \(step.match)")
        }
        AfterScenario { [self] _ in
            try await Task.sleep(nanoseconds: 1_000_000)
            MainActor.assertIsolated()
            ran.append("after waiting")
        }

        let reasons = await skipReasons(of: Cucumber.shared.casesToRun(checkout))

        #expect(ran == [
            "basket", "after a basket", "after waiting a basket",
            "card", "after I pay by card", "after waiting I pay by card",
            "after scenario", "after waiting"
        ])
        #expect(observer.log.last == "scenario passed S")
        #expect(reasons == ["The card terminal is offline"])
        #expect(observer.log.contains("step skipped"))
        #expect(observer.log.contains("scenario passed S"))
        useOneTestPerScenario(false)
    }

    @Test func eachCaseAfterAStepThatCallsTestCancelIsSkippedWithItsReason() async {
        useOneTestPerScenario(false)
        registerCheckout { try Test.cancel("The card terminal is offline") }

        let reasons = await skipReasons(of: Cucumber.shared.casesToRun(checkout))

        #expect(ran == ["basket", "after a basket", "card", "after I pay by card", "after scenario"])
        #expect(reasons == [nil, "The card terminal is offline", "Skipped: The card terminal is offline"])
    }
    #endif
}
