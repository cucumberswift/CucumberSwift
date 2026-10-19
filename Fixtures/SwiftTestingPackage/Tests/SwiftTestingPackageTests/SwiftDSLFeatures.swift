//
//  SwiftDSLFeatures.swift
//  SwiftTestingPackageTests
//
//  A feature written in the Swift DSL rather than in a feature file: the generated "Swift DSL features" test
//  runs it. Its steps are the DSL step macros, whose text is captured when the tests compile.
//

import CucumberSwiftTestingMacros
import Testing

/// What the steps of the Swift DSL feature did, in the order they ran.
@MainActor
private var dslRan = [String]()

@MainActor
private func openTheShop() { dslRan.append("open") }

@MainActor
private func addCukes(_ count: Int) { World.cukes += count }

@MainActor
private func payAtTheTill() async throws {
    try await Task.sleep(nanoseconds: 1_000_000)
    dslRan.append("paid")
}

extension Cucumber {
    func swiftDSLFeatures() {
        #AfterStep { step in
            guard step.scenario?.feature?.title == "Swift DSL" else { return }
            dslRan.append(step.match)
        }

        Feature("Swift DSL", tags: ["dsl"]) {
            Description("A feature written in Swift, run by Swift Testing as feature files are.")

            Background {
                #Given(I: openTheShop())
            }

            Scenario("Buy cukes with the DSL step macros") {
                #When(I: addCukes(2))
                #And(I:
                        addCukes(3))
                #Then(I: payAtTheTill)
                #And(the: {
                    #expect(World.cukes == 5)
                    #expect(dslRan == ["open", "I: openTheShop()", "I: addCukes(2)", "I: addCukes(3)", "paid", "I: payAtTheTill"])
                })
            }

            // swiftlint:disable:next multiline_arguments
            ScenarioOutline({ "Buy \($0) cukes" }, headers: Int.self, steps: { count in
                #When(I: addCukes(count))
                #Then(the: #expect(World.cukes == count))
            }, examples: { [1, 4] })
        }
    }
}
