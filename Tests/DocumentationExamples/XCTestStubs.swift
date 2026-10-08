//
//  XCTestStubs.swift
//  DocumentationExamples
//
//  The reader's own code that the documentation's examples for CucumberSwift and XCTest use,
//  such as `basket`. .github/scripts/docs_examples.py compiles each example with this module.
//  An example's own declaration of a name takes precedence over the one here.
//

import CucumberSwiftMacros
import Foundation
import XCTest

public final class Basket {
    public init() {}
    public func add(_ count: Int, to container: String) {}
    public func eat(_ count: Int) {}
    public func waitForCount(_ count: Int?) async throws {}
}

// "Checking Step Definitions When They Compile", in Spanish.
public final class Cesta {
    public init() {}
    public func añadir(_ cantidad: Int) {}
}

public final class Server {
    public init() {}
    public func reset() async throws {}
}

public final class Session {
    public enum User { case testUser }
    public init() {}
    public func signIn(as user: User) async throws {}
}

@MainActor public let basket = Basket()
@MainActor public let cesta = Cesta()
@MainActor public let server = Server()
@MainActor public let session = Session()

public enum Screen { case settings }

public func open(_ screen: Screen) async throws {}

public func settingsAreShown() {}

// "Matching Steps" declares these in one example and uses them in the one before it.
// swiftlint:disable:next convenience_type
public final class Airport {
    public static let lax = Airport()
}

public struct AirportParameter: Parameter {
    public static let name = "airport"
    public let regexMatch = #"[A-Z]{3}"#
    public init() {}
    public func convert(input: String) throws -> Airport { .lax }
}

// A test case class whose bundle holds the feature files.
open class MyFeatureTests: XCTestCase {}

// "Generating Reports" declares this in one example and uses it in a later one.
public final class MyTestObserver: CucumberTestObserver {
    public init() {}
    public func testSuiteStarted(at date: Date) {}
    public func testSuiteFinished(at date: Date) {}
    public func didStart(feature: Feature, at date: Date) {}
    public func didStart(scenario: Scenario, at date: Date) {}
    public func didStart(step: Step, at date: Date) {}
    public func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
    public func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
    public func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {}
}

extension Match {
    public var airport: AirportParameter { AirportParameter() }
}

// The `duration` a reporter's method is given, in "Generating Reports".
extension Cucumber {
    public var duration: Measurement<UnitDuration> { Measurement(value: 1, unit: .seconds) }
}
