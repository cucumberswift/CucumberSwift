//
//  DSLRuleTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/25/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//
// swiftlint:disable type_body_length

import Foundation
import XCTest
import CucumberSwift

class DSLRuleTests: XCTestCase {
    func testSingleRuleWithOneScenarioAndNoBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 1)

        let scenario = feature.scenarios.first
        XCTAssertEqual(scenario?.title, "SC1")
        XCTAssertEqual(scenario?.steps.count, 1)

        let step = scenario?.steps.first
        XCTAssertEqual(step?.match, "I: print(\"S1\")")
    }

    func testARulesTagsComeBeforeItsScenariosTags() {
        let feature =
        Feature("F1") {
            Rule("R1", tags: ["rule"]) {
                Scenario("SC1", tags: ["scenario"]) {
                    Given(I: print("S1"))
                }
            }
            Rule("R2", tags: ["other"]) {
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.map(\.tags), [["rule", "scenario"], ["other"]])
        XCTAssert(feature.scenarios.first?.containsTags(["rule"]) ?? false)
    }

    func testSingleRuleWithMultipleScenariosAndNoBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 2)

        let sc1 = feature.scenarios.first
        XCTAssertEqual(sc1?.title, "SC1")
        XCTAssertEqual(sc1?.steps.count, 1)
        XCTAssertEqual(sc1?.steps.first?.match, "I: print(\"S1\")")

        let sc2 = feature.scenarios.last
        XCTAssertEqual(sc2?.title, "SC2")
        XCTAssertEqual(sc2?.steps.count, 1)
        XCTAssertEqual(sc2?.steps.first?.match, "I: print(\"S2\")")
    }

    func testSingleRuleWithOneScenarioAndARuleBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Background {
                    Given(I: print("B1"))
                }
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 1)

        let scenario = feature.scenarios.first
        XCTAssertEqual(scenario?.title, "SC1")
        XCTAssertEqual(scenario?.steps.count, 2)
        XCTAssertEqual(scenario?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(scenario?.steps.last?.match, "I: print(\"S1\")")
    }

    func testSingleRuleWithMultipleScenariosAndARuleBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Background {
                    Given(I: print("B1"))
                }
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 2)

        let sc1 = feature.scenarios.first
        XCTAssertEqual(sc1?.title, "SC1")
        XCTAssertEqual(sc1?.steps.count, 2)
        XCTAssertEqual(sc1?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(sc1?.steps.last?.match, "I: print(\"S1\")")

        let sc2 = feature.scenarios.last
        XCTAssertEqual(sc2?.title, "SC2")
        XCTAssertEqual(sc2?.steps.count, 2)
        XCTAssertEqual(sc2?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(sc2?.steps.last?.match, "I: print(\"S2\")")
    }

    func testMultipleRulesWithOneScenarioAndNoBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
            }
            Rule("R2") {
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 2)

        XCTAssertEqual(feature.scenarios.first?.title, "SC1")
        XCTAssertEqual(feature.scenarios.first?.steps.count, 1)
        XCTAssertEqual(feature.scenarios.first?.steps.first?.match, "I: print(\"S1\")")

        XCTAssertEqual(feature.scenarios.last?.title, "SC2")
        XCTAssertEqual(feature.scenarios.last?.steps.count, 1)
        XCTAssertEqual(feature.scenarios.last?.steps.first?.match, "I: print(\"S2\")")
    }

    func testMultipleRulesWithMultipleScenariosAndNoBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
            Rule("R2") {
                Scenario("SC3") {
                    Given(I: print("S3"))
                }
                Scenario("SC4") {
                    Given(I: print("S4"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 4)

        let sc1 = feature.scenarios.first
        XCTAssertEqual(sc1?.title, "SC1")
        XCTAssertEqual(sc1?.steps.count, 1)
        XCTAssertEqual(sc1?.steps.first?.match, "I: print(\"S1\")")

        guard feature.scenarios.count == 4 else { return }

        let sc2 = feature.scenarios[1]
        XCTAssertEqual(sc2.title, "SC2")
        XCTAssertEqual(sc2.steps.count, 1)
        XCTAssertEqual(sc2.steps.first?.match, "I: print(\"S2\")")

        let sc3 = feature.scenarios[2]
        XCTAssertEqual(sc3.title, "SC3")
        XCTAssertEqual(sc3.steps.count, 1)
        XCTAssertEqual(sc3.steps.first?.match, "I: print(\"S3\")")

        let sc4 = feature.scenarios[3]
        XCTAssertEqual(sc4.title, "SC4")
        XCTAssertEqual(sc4.steps.count, 1)
        XCTAssertEqual(sc4.steps.first?.match, "I: print(\"S4\")")
    }

    func testMultipleRulesWithOneScenarioAndARuleBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Background {
                    Given(I: print("B1"))
                }
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
            }
            Rule("R2") {
                Background {
                    Given(I: print("B2"))
                }
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 2)

        XCTAssertEqual(feature.scenarios.first?.title, "SC1")
        XCTAssertEqual(feature.scenarios.first?.steps.count, 2)
        XCTAssertEqual(feature.scenarios.first?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(feature.scenarios.first?.steps.last?.match, "I: print(\"S1\")")

        XCTAssertEqual(feature.scenarios.last?.title, "SC2")
        XCTAssertEqual(feature.scenarios.last?.steps.count, 2)
        XCTAssertEqual(feature.scenarios.last?.steps.first?.match, "I: print(\"B2\")")
        XCTAssertEqual(feature.scenarios.last?.steps.last?.match, "I: print(\"S2\")")
    }

    func testMultipleRulesWithMultipleScenariosAndARuleBackground() {
        let feature =
        Feature("F1") {
            Rule("R1") {
                Background {
                    Given(I: print("B1"))
                }
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
                Scenario("SC2") {
                    Given(I: print("S2"))
                }
            }
            Rule("R2") {
                Background {
                    Given(I: print("B2"))
                }
                Scenario("SC3") {
                    Given(I: print("S3"))
                }
                Scenario("SC4") {
                    Given(I: print("S4"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 4)

        let sc1 = feature.scenarios.first
        XCTAssertEqual(sc1?.title, "SC1")
        XCTAssertEqual(sc1?.steps.count, 2)
        XCTAssertEqual(sc1?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(sc1?.steps.last?.match, "I: print(\"S1\")")

        guard feature.scenarios.count == 4 else { return }

        let sc2 = feature.scenarios[1]
        XCTAssertEqual(sc2.title, "SC2")
        XCTAssertEqual(sc2.steps.count, 2)
        XCTAssertEqual(sc2.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(sc2.steps.last?.match, "I: print(\"S2\")")

        let sc3 = feature.scenarios[2]
        XCTAssertEqual(sc3.title, "SC3")
        XCTAssertEqual(sc3.steps.count, 2)
        XCTAssertEqual(sc3.steps.first?.match, "I: print(\"B2\")")
        XCTAssertEqual(sc3.steps.last?.match, "I: print(\"S3\")")

        let sc4 = feature.scenarios[3]
        XCTAssertEqual(sc4.title, "SC4")
        XCTAssertEqual(sc4.steps.count, 2)
        XCTAssertEqual(sc4.steps.first?.match, "I: print(\"B2\")")
        XCTAssertEqual(sc4.steps.last?.match, "I: print(\"S4\")")
    }

    func testFeatureWithBackground_PropogatesDownToRules() {
        let feature =
        Feature("F1") {
            Background {
                Given(I: print("B1"))
            }
            Rule("R1") {
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
            }
        }

        XCTAssertEqual(feature.scenarios.count, 1)

        let scenario = feature.scenarios.first
        XCTAssertEqual(scenario?.steps.count, 2)

        XCTAssertEqual(scenario?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(scenario?.steps.last?.match, "I: print(\"S1\")")
    }

    func testFeatureWithBackground_PropogatesDownToRulesThatAlsoHaveBackgrounds() {
        let feature =
        Feature("F1") {
            Background {
                Given(I: print("B1"))
            }
            Rule("R1") {
                Background {
                    Given(I: print("B2"))
                }
                Scenario("SC1") {
                    Given(I: print("S1"))
                }
            }
            Scenario("SC2") {
                Given(I: print("S2"))
            }
        }

        XCTAssertEqual(feature.scenarios.count, 2)

        XCTAssertEqual(feature.scenarios.first?.steps.count, 3)
        XCTAssertEqual(feature.scenarios.last?.steps.count, 2)

        guard feature.scenarios.first?.steps.count == 3 else { return }
        XCTAssertEqual(feature.scenarios.first?.steps[0].match, "I: print(\"B1\")")
        XCTAssertEqual(feature.scenarios.first?.steps[1].match, "I: print(\"B2\")")
        XCTAssertEqual(feature.scenarios.first?.steps[2].match, "I: print(\"S1\")")

        XCTAssertEqual(feature.scenarios.last?.steps.first?.match, "I: print(\"B1\")")
        XCTAssertEqual(feature.scenarios.last?.steps.last?.match, "I: print(\"S2\")")
    }
}
