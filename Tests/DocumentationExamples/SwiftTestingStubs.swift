//
//  SwiftTestingStubs.swift
//  DocumentationExamples
//
//  The reader's own code that the documentation's examples for CucumberSwiftTesting use, such
//  as `Basket.shared`. .github/scripts/docs_examples.py compiles each example with this module.
//  An example's own declaration of a name takes precedence over the one here.
//

import CucumberSwiftTestingMacros
import Foundation
import Testing

@MainActor
public final class Basket {
    public static let shared = Basket()
    public private(set) var count = 0
    public func empty() { count = 0 }
    public func add(_ count: Int) { self.count += count }
}

/// The test data that `Cucumber.mapTags` sets up from the tag `@fixtures:exampleWorld`.
public struct ExampleWorld: Sendable {
    @TaskLocal public static var current: ExampleWorld?
    public var cukes = 10
    public init() {}
}

/// Runs a scenario with an example world as its test data.
public struct FixturesTrait: TestTrait, TestScoping {
    public let world: ExampleWorld

    public func provideScope(for _: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        try await ExampleWorld.$current.withValue(world) {
            try await function()
        }
    }
}

extension TestScoping where Self == FixturesTrait {
    public static func fixtures(_ world: ExampleWorld) -> Self { Self(world: world) }
}
