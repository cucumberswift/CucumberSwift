//
//  UnitTestSteps.swift
//  ParallelFixtures
//
//  The step definitions of the unit test fixtures, both the one without a host app and the one that runs in
//  the app. The cart is a variable here; the UI test fixture drives the app's cart instead.
//

import Foundation
import XCTest
import CucumberSwift

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        // A subclass of CucumberTest, as consumers write it.
        class TestDiscovery: CucumberTest {
            // Empty on purpose: XCTest hands this subclass to a worker of its own, which must not run the scenarios again.
        }
        return Bundle(for: TestDiscovery.self)
    }

    public func setupSteps() {
        ParallelFixtureSupport.setUp()

        var items = 0
        BeforeScenario { _ in
            items = 0
        }

        Given("a fresh cart") { _, _ in
            XCTAssertEqual(items, 0)
        }
        When("I add {int} items") { match, _ in
            items += try match.first(\.int)
        }
        Then("the cart holds {int} items") { match, _ in
            XCTAssertEqual(items, try match.first(\.int))
        }
        // Temporary (#491): 10 seconds, so the run outlasts the Simulator clones' start-up.
        Then("the scenario takes a moment") { _, _ in
            Thread.sleep(forTimeInterval: 10)
        }
        // Long enough that the two scenarios that share a name run at the same time in two workers.
        Then("the scenario takes a while") { _, _ in
            Thread.sleep(forTimeInterval: 4)
        }
    }
}
