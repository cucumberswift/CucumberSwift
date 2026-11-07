//
//  StepDefinitions.swift
//  CarthageXCFrameworkTests
//
//  Step definitions with Cucumber expressions and typed parameters. They only compile when the
//  CucumberSwiftExpressions module ships inside CucumberSwift.framework and `import CucumberSwift`
//  re-exports it.
//

import CucumberSwift
import Foundation
import XCTest

final class Basket {
    static let shared = Basket()
    var cukes = 0
}

extension Cucumber: StepImplementation {
    public var bundle: Bundle { Bundle(for: Basket.self) }

    public func setupSteps() {
        Given("I have {int} cukes in my {string}") { match, _ in
            XCTAssertEqual(try match.first(\.string), "basket")
            Basket.shared.cukes = try match.first(\.int)
        }

        When("I eat {int} cukes") { match, _ in
            Basket.shared.cukes -= try match.first(\.int)
        }

        Then("the basket holds {int} cuke(s)") { (match: CucumberSwiftExpressions.Match, _) in
            XCTAssertEqual(Basket.shared.cukes, try match.first(\.int))
        }

        // Without the CucumberSwiftLint plugin, which a Carthage project can't use, CucumberSwift finds the
        // feature file in the project from this file's path, and reports a step's failure there, not at its copy
        // in the test bundle (#535). The failure is expected only there; anywhere else, it fails the test.
        Then("a failure is reported at this feature file in the project") { _, _ in
            let featureFile = URL(fileURLWithPath: "\(#filePath)")
                .deletingLastPathComponent()
                .appendingPathComponent("Features/Basket.feature")
                .resolvingSymlinksInPath()
            let options = XCTExpectedFailure.Options()
            options.issueMatcher = { $0.sourceCodeContext.location?.fileURL.resolvingSymlinksInPath() == featureFile }
            XCTExpectFailure("A failure on purpose, to show where CucumberSwift reports it", options: options) {
                XCTFail("Reported at \(featureFile.path)")
            }
        }
    }
}
