//
//  SwiftDSLFeatures.swift
//  SwiftTestingPackageTests
//
//  A feature written in the Swift DSL rather than in a feature file: the generated "Swift DSL features" test
//  runs it, written in the macro style throughout: `#Feature`, `#Scenario` and the rest, and the DSL step macros,
//  whose text is captured when the tests compile.
//

import CucumberSwiftTestingMacros
import Testing

/// What one scenario of the Swift DSL feature has done: its own, from `Scenario.state`, so that scenarios that
/// run at the same time, with parallel testing, don't share it.
@MainActor
private final class Shop {
    static var current: Shop { Scenario.state(Shop.init) }

    var cukes = 0
    /// What the steps did, and the text of each step that finished, in order.
    var ran = [String]()
}

@MainActor
private func openTheShop() { Shop.current.ran.append("open") }

@MainActor
private func addCukes(_ count: Int) { Shop.current.cukes += count }

@MainActor
private func payAtTheTill() async throws {
    try await Task.sleep(nanoseconds: 1_000_000)
    Shop.current.ran.append("paid")
}

extension Cucumber {
    func swiftDSLFeatures() {
        #AfterStep { step in
            guard step.scenario?.feature?.title == "Swift DSL" else { return }
            Shop.current.ran.append(step.match)
        }

        #Feature("Swift DSL", tags: ["dsl"]) {
            #Description("A feature written in Swift, run by Swift Testing as feature files are.")

            #Background {
                #Given(I: openTheShop())
            }

            #Scenario("Buy cukes with the DSL macros") {
                #When(I: addCukes(2))
                #And(I:
                        addCukes(3))
                #Then(I: payAtTheTill)
                #And(the: {
                    #expect(Shop.current.cukes == 5)
                    #expect(Shop.current.ran == ["open", "I: openTheShop()", "I: addCukes(2)", "I: addCukes(3)", "paid", "I: payAtTheTill"])
                })
            }

            // swiftlint:disable:next multiline_arguments
            #ScenarioOutline({ "Buy \($0) cukes" }, headers: Int.self, steps: { count in
                #When(I: addCukes(count))
                #Then(the: #expect(Shop.current.cukes == count))
            }, examples: { [1, 4] })
        }
    }
}
