//
//  CucumberSwiftSwift6ConsumerTests.swift
//  CucumberSwiftSwift6ConsumerTests
//
//  A test target in the Swift 6 language mode that uses CucumberSwift the ways consumers do (#243):
//  steps, hooks, DSL steps and a reporter that use main-actor code, an async step that changes a
//  variable declared in setupSteps(), and values sent to other tasks. If CucumberSwift's API stops
//  compiling in the Swift 6 language mode, this package stops building.
//

import XCTest
import CucumberSwift
import CucumberSwiftExpressions

/// Main-actor state, as a view model or a UI test's app driver would be.
@MainActor final class MainActorModel {
    static let shared = MainActorModel()
    var events = [String]()

    func record(_ event: String) {
        events.append(event)
    }
}

@MainActor func useMainActorCode(_ event: String) {
    MainActorModel.shared.record(event)
}

@MainActor func awaitMainActorCode(_ event: String) async {
    await Task.yield()
    MainActorModel.shared.record(event)
}

/// An async DSL step, passed as a function.
@MainActor func dslAsyncStep() async {
    await awaitMainActorCode("DSL async step")
}

/// A value that must be `Sendable` to cross into a detached task.
func send<T: Sendable>(_ value: T) {
    Task.detached { _ = value }
}

/// Finds the test bundle, where Bazel puts the Features folder.
private final class Swift6BundleFinder {}

/// A custom Cucumber Expression parameter, as in "Matching Steps".
final class Airport: Sendable {
    static let lax = Airport()
}

struct AirportParameter: Parameter {
    struct NotFound: Error { }

    static let name = "airport"
    let regexMatch = #"[A-Z]{3}"#

    func convert(input: String) throws -> Airport {
        guard input == "LAX" else { throw NotFound() }
        return .lax
    }
}

final class MainActorReporter: CucumberTestObserver {
    func testSuiteStarted(at _: Date) { }
    func testSuiteFinished(at _: Date) { }
    func didStart(feature _: Feature, at _: Date) { }
    func didStart(scenario _: Scenario, at _: Date) { }
    func didStart(step _: Step, at _: Date) {
        useMainActorCode("reporter")
    }
    func didFinish(feature _: Feature, result _: Reporter.Result, duration _: Measurement<UnitDuration>) { }
    func didFinish(scenario _: Scenario, result _: Reporter.Result, duration _: Measurement<UnitDuration>) { }
    func didFinish(step _: Step, result: Reporter.Result, duration _: Measurement<UnitDuration>) {
        send(result)
    }
}

extension Match {
    var airport: AirportParameter { AirportParameter() }
}

extension CucumberExpression: @retroactive CustomParameters {
    public static var additionalParameters: [AnyParameter] {
        [AirportParameter().eraseToAnyParameter()]
    }
}

extension Cucumber: @retroactive CucumberTestObservable {
    public var observers: [CucumberTestObserver] { [MainActorReporter()] }
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        // SwiftPM copies the Features folder into a resource bundle of its own; Bazel puts it in
        // the test bundle, as Xcode does.
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: Swift6BundleFinder.self)
        #endif
    }

    public func setupSteps() {
        var changes = 0

        BeforeScenario { _ in useMainActorCode("sync hook") }
        BeforeScenario { _ in await awaitMainActorCode("async hook") }

        Given("a synchronous step that uses main-actor code") { _, _ in
            useMainActorCode("sync step")
        }

        Given("an async step that changes a variable declared in setupSteps") { _, _ in
            await awaitMainActorCode("async step")
            changes += 1
        }

        Given("a synchronous step that sends its step to the main actor") { _, step in
            Task { @MainActor in _ = step.match }
            send(step.keyword)
            send(step.location)
        }

        Given("a step that reads Cucumber.shared") { _, _ in
            XCTAssertNotNil(Cucumber.shared.bundle.url(forResource: "Features", withExtension: nil))
        }

        Given("there are {int} flights from {airport}" as CucumberExpression) { match, _ in
            XCTAssertEqual(match[\.int, index: 0], 3)
            XCTAssertIdentical(try match.first(\.airport), Airport.lax)
            useMainActorCode("typed match")
        }

        Then("the variable was changed once") { _, _ in
            XCTAssertEqual(changes, 1)
        }

        Then("the hooks and the reporter used main-actor code") { _, _ in
            let events = MainActorModel.shared.events
            for event in ["sync hook", "async hook", "sync step", "async step", "typed match", "reporter"] {
                XCTAssert(events.contains(event), "\(event) did not run")
            }
        }

        // Only compiled, not run: no scenario uses these. A UI test's steps drive `XCUIApplication`,
        // which is main-actor isolated.
        When("a synchronous step that drives the app") { _, _ in
            _ = XCUIApplication()
        }
        When("an async step that drives the app") { _, _ in
            await Task.yield()
            _ = XCUIApplication()
        }

        Feature("Swift 6 language mode DSL") {
            Scenario("DSL steps use main-actor code") {
                Given(I: useMainActorCode("DSL sync step"))
                Then(I: dslAsyncStep)
            }
        }
    }
}
