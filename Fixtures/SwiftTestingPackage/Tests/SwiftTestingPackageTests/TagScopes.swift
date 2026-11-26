//
//  TagScopes.swift
//  SwiftTestingPackageTests
//
//  The "Tag scopes" feature: Cucumber.mapTags turns a scenario's tags into a Swift Testing scoping trait,
//  whose task-local value the steps read.
//

import CucumberSwiftTestingMacros
import Foundation
import Testing

/// A basket that the `@fixtures:basket` tag sets up for one scenario.
struct Basket: Sendable {
    @TaskLocal static var current: Basket?
    let id = UUID()
}

/// Sets up a basket for the scenario it wraps, and checks that the scenario used it.
struct BasketTrait: TestTrait, TestScoping {
    func provideScope(for _: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        try await Basket.$current.withValue(Basket()) {
            try await function()
        }
    }
}

extension TestScoping where Self == BasketTrait {
    static var basket: Self { Self() }
}

extension Cucumber {
    func tagScopeSteps() {
        Cucumber.mapTags { tags in
            tags.contains("@fixtures:basket") ? [.basket] : []
        }
        // Each scenario of the feature sees one basket in all of its steps, and no other scenario sees it.
        BeforeScenario { _ in World.basket = Basket.current?.id }
        #Then("the test's tags are {string}") { (tags: String) in
            let trait = Test.current?.traits.compactMap { $0 as? GherkinTagsTrait }.first
            #expect(trait?.tags.joined(separator: " ") == tags)
        }
        #Then("the basket is set up for this scenario") {
            #expect(Basket.current != nil)
            #expect(Basket.current?.id == World.basket)
        }
        #Then("the basket is not set up for this scenario") {
            #expect(Basket.current == nil)
        }
    }
}
