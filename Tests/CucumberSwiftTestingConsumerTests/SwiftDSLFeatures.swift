//
//  SwiftDSLFeatures.swift
//  CucumberSwiftTestingConsumerTests
//
//  A feature written in the Swift DSL rather than in a feature file: the generated "Swift DSL features"
//  test runs it. The step functions, because the Bazel module builds no DSL step macros. A step function
//  reads its text from this file when the tests run, so the steps don't check it.
//

import CucumberSwiftTesting
import Testing

/// What one scenario of the Swift DSL feature has done: its own, from `Scenario.state`.
@MainActor
private final class Shop {
    static var current: Shop { Scenario.state(Shop.init) }

    var cukes = 0
    var opened = false
}

@MainActor
private func openTheShop() { Shop.current.opened = true }

@MainActor
private func addCukes(_ count: Int) { Shop.current.cukes += count }

@MainActor
private func payAtTheTill() async throws {
    try await Task.sleep(nanoseconds: 1_000_000)
    Shop.current.cukes = 0
}

extension Cucumber {
    func swiftDSLFeatures() {
        Feature("Swift DSL", tags: ["dsl"]) {
            Description("A feature written in Swift, run by Swift Testing as feature files are.")

            Background {
                Given(I: openTheShop())
            }

            Scenario("Buy cukes with the DSL functions") {
                When(I: addCukes(2))
                And(I: addCukes(3))
                Then(I: payAtTheTill)
                // swiftlint:disable:next trailing_closure
                And(the: {
                    #expect(Shop.current.opened)
                    #expect(Shop.current.cukes == 0)
                })
            }

            Scenario("Each scenario has its own state") {
                When(I: addCukes(1))
                // swiftlint:disable:next trailing_closure
                Then(the: {
                    #expect(Shop.current.cukes == 1)
                })
            }
        }
    }
}
