//
//  SelectorStepDefinitionTests.swift
//  CucumberSwiftTestingTests
//

#if canImport(ObjectiveC)
@testable import CucumberSwiftTesting
import Foundation
import Testing
#if canImport(XCTest)
import XCTest
#endif

/// What the classes these step definitions run record, in the order it happened.
@MainActor
private enum SelectorLog {
    static var calls = [String]()
}

private final class SelectorTarget: NSObject {
    @objc func run() {
        MainActor.assumeIsolated { SelectorLog.calls.append("run") }
    }
}

#if canImport(XCTest)
private final class SelectorTestCase: XCTestCase {
    override func setUp() {
        MainActor.assumeIsolated { SelectorLog.calls.append("setUp") }
    }

    override func tearDown() {
        MainActor.assumeIsolated { SelectorLog.calls.append("tearDown") }
    }

    @objc func unitTestIsExecuted() {
        MainActor.assumeIsolated { SelectorLog.calls.append("test") }
    }
}
#endif

/// The step definitions with a regular expression in a string, a class and a selector.
extension CucumberTests {
    @available(*, deprecated)
    @Test func aMatchingStepCallsTheSelectorOnANewInstanceOfTheClass() async {
        SelectorLog.calls = []
        Given("I point my step to a (\\w+)", class: SelectorTarget.self, selector: #selector(SelectorTarget.run))
        await Cucumber.shared.run(scenario([step(.given, "I point my step to a target", line: 3),
                                            step(.given, "I point my step to a target", line: 4)]))
        #expect(SelectorLog.calls == ["run", "run"])
    }

    @available(*, deprecated)
    @Test func aStepThatDoesNotMatchTheExpressionDoesNotCallTheSelector() async {
        SelectorLog.calls = []
        Given("^exactly this$", class: SelectorTarget.self, selector: #selector(SelectorTarget.run))
        Given("something else") { _, _ in }
        await Cucumber.shared.run(scenario([step(.given, "something else", line: 3)]))
        #expect(SelectorLog.calls.isEmpty)
    }

    @available(*, deprecated)
    @Test func anInstanceThatDoesNotRespondToTheSelectorDoesNothing() async {
        SelectorLog.calls = []
        Given("a step", class: NSObject.self, selector: #selector(SelectorTarget.run))
        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(SelectorLog.calls.isEmpty)
    }

    #if canImport(XCTest)
    @available(*, deprecated)
    @Test func anXCTestCaseIsSetUpBeforeAndTornDownAfterTheSelectorAndBeforeTheAfterStepHooks() async {
        SelectorLog.calls = []
        AfterStep { _ in SelectorLog.calls.append("AfterStep") }
        Given("a unit test", class: SelectorTestCase.self, selector: #selector(SelectorTestCase.unitTestIsExecuted))
        await Cucumber.shared.run(scenario([step(.given, "a unit test", line: 3)]))
        #expect(SelectorLog.calls == ["setUp", "test", "tearDown", "AfterStep"])
    }
    #endif
}
#endif
