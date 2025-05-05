//
//  ReporterTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 3/10/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift
import JSONSchema

class ReporterTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }
    
    func getCurrentFilePath(file: StaticString = #file) -> String { String(file) }
    
    func testFeaturesAreWrittenToFile() throws {
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        Feature("F1") {
            Description("A test feature")
            Scenario("S1") {
                Given(I: print(""))
            }
        }
        reporter.testSuiteStarted(at: Date())
        Cucumber.shared.executeFeatures()
        
        let actual = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
        XCTAssertEqual(actual.count, 1)
        XCTAssertEqual(actual.first?["uri"] as? String, getCurrentFilePath())
        XCTAssertEqual(actual.first?["id"] as? String, "f1")
        XCTAssertEqual(actual.first?["name"] as? String, "F1")
        XCTAssertEqual(actual.first?["description"] as? String, "A test feature")
        XCTAssertEqual(actual.first?["keyword"] as? String, "Feature")
    }
    
    func testScenariosAreWrittenToFile() throws {
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        Feature("F1") {
            Description("A test feature")
            Scenario("S1") {
                Given(I: print(""))
            }
        }
        reporter.testSuiteStarted(at: Date())
        Cucumber.shared.executeFeatures()
        
        let actual = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
        XCTAssertEqual(actual.count, 1)
        let scenarios = actual.first?["elements"] as? [[AnyHashable: Any]]
        XCTAssertEqual(scenarios?.count, 1)
        XCTAssertEqual(scenarios?.first?["id"] as? String, "s1")
        XCTAssertEqual(scenarios?.first?["keyword"] as? String, "Scenario")
        XCTAssertEqual(scenarios?.first?["type"] as? String, "scenario")
        XCTAssertEqual(scenarios?.first?["name"] as? String, "S1")
        XCTAssertEqual(scenarios?.first?["description"] as? String, "")
    }

    func testStepsAreWrittenToFile() throws {
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        Feature("F1") {
            Description("A test feature")
            Scenario("S1") {
                Given(I: print(""))
            }
        }
        reporter.testSuiteStarted(at: Date())
        Cucumber.shared.executeFeatures()

        let actual = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
        XCTAssertEqual(actual.count, 1)
        let scenarios = actual.first?["elements"] as? [[AnyHashable: Any]]
        XCTAssertEqual(scenarios?.count, 1)
        let steps = scenarios?.first?["steps"] as? [[AnyHashable: Any]]
        XCTAssertEqual(steps?.count, 1)
        XCTAssertEqual(steps?.first?["name"] as? String, "I: print(\"\")")
        XCTAssertEqual(steps?.first?["keyword"] as? String, "Given")
        let result = steps?.first?["result"] as? [AnyHashable: Any]
        XCTAssertEqual(result?["status"] as? String, "passed")
    }

    func testFailingStepsAreWrittenToFile() throws {
        enum Err: Error { case e1 }
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        let step = Given(I: print(""))
        let scenario = Scenario("S1") { step }
        let feature = Feature("F1") { scenario }
        reporter.testSuiteStarted(at: Date())
        reporter.didStart(feature: feature, at: Date())
        reporter.didStart(scenario: scenario, at: Date())
        reporter.didStart(step: step, at: Date())
        reporter.didFinish(step: step, result: .failed(Err.e1.localizedDescription), duration: .init(value: 1, unit: .seconds))

        let actual = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
        XCTAssertEqual(actual.count, 1)
        let scenarios = actual.first?["elements"] as? [[AnyHashable: Any]]
        XCTAssertEqual(scenarios?.count, 1)
        let steps = scenarios?.first?["steps"] as? [[AnyHashable: Any]]
        XCTAssertEqual(steps?.count, 1)
        XCTAssertEqual(steps?.first?["name"] as? String, "I: print(\"\")")
        XCTAssertEqual(steps?.first?["keyword"] as? String, "Given")
        let result = steps?.first?["result"] as? [AnyHashable: Any]
        XCTAssertEqual(result?["status"] as? String, "failed")
        XCTAssertEqual(result?["error_message"] as? String, Err.e1.localizedDescription)
        let actualDuration = try XCTUnwrap(result?["duration"] as? Double)
        XCTAssertEqual(actualDuration, 1_000_000_000, accuracy: 0.9)
    }

    func testPendingStepsAreWrittenToFile() throws {
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)

        let step = Given(I: print(""))
        let scenario = Scenario("S1") { step }
        let feature = Feature("F1") { scenario }

        reporter.testSuiteStarted(at: Date())
        reporter.didStart(feature: feature, at: Date())
        reporter.didStart(scenario: scenario, at: Date())
        reporter.didStart(step: step, at: Date())

        let actual = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
        XCTAssertEqual(actual.count, 1)
        let scenarios = actual.first?["elements"] as? [[AnyHashable: Any]]
        XCTAssertEqual(scenarios?.count, 1)
        let steps = scenarios?.first?["steps"] as? [[AnyHashable: Any]]
        XCTAssertEqual(steps?.count, 1)
        XCTAssertEqual(steps?.first?["name"] as? String, "I: print(\"\")")
        XCTAssertEqual(steps?.first?["keyword"] as? String, "Given")
        let result = steps?.first?["result"] as? [AnyHashable: Any]
        XCTAssertEqual(result?["status"] as? String, "pending")
    }

    func testReporterJsonConformsToCucumberJsonSchema() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Schema.json")
        let data = try Data(contentsOf: path, options: .mappedIfSafe)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let schema = json as? [String: Any] {
            // access dictionary values
            let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
            let feature = Feature("F1") {
                Description("A test feature")
                Scenario("S1") {
                    Given(I: print(""))
                }
            }
            feature.tags = ["@tag1", "@tag2"]
            if !feature.scenarios.isEmpty {
                feature.scenarios[0].tags = ["@tag3", "@tag4"]
            }
            reporter.testSuiteStarted(at: Date())
            Cucumber.shared.executeFeatures()
            let actual = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reporter.features)) as? [[AnyHashable: Any]])
            let result = try JSONSchema.validate(actual, schema: schema)
            if let errors = result.errors {
                if !errors.isEmpty {
                    XCTFail("Should validate the JOSN with the Schema, got \(errors) instead")
                }
                XCTAssertEqual(errors.count, 0)
            }
        } else {
            XCTFail("Failure by encode of json schema")
        }
    }
}

extension Feature {
    convenience init(uri: String) {
        self.init(with: AST.FeatureNode(node: AST.Node()), uri: uri)
    }
}
