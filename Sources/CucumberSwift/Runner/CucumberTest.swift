//
//  CucumberTestCase.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

open class CucumberTest: XCTestCase {
    static var didRun = false

    private static var suiteInstance: XCTestSuite?

    override public class var defaultTestSuite: XCTestSuite {
        // notify reporters every time
        Cucumber.shared.reporters.forEach { $0.testSuiteStarted(at: Date()) }

        // create default test suite only once
        if let existingSuite = suiteInstance {
            return existingSuite
        }

        let suite = XCTestSuite(forTestCaseClass: CucumberTest.self)
        suiteInstance = suite

        Cucumber.shared.features.removeAll()
        if let bundle = (Cucumber.shared as? StepImplementation)?.bundle {
            Cucumber.shared.readFromFeaturesFolder(in: bundle)
        }
        (Cucumber.shared as? StepImplementation)?.setupSteps()
        assert(!Cucumber.shared.features.isEmpty, "CucumberSwift found no features to run. Check out our documentation for instructions on including you Features folder. Be aware it's a case sensitive search. If you're using the DSL, make sure your features are defined in the `setupSteps()` method.") // swiftlint:disable:this line_length
        generateAlltests(suite)
        return suite
    }

    static func generateAlltests(_ rootSuite: XCTestSuite) {
        let stubsSuite = XCTestSuite(name: "GeneratedSteps")
        var stubTests = [XCTestCase]()
        createTestCaseForStubs(&stubTests)
        stubTests.forEach { stubsSuite.addTest($0) }
        rootSuite.addTest(stubsSuite)

        let configuration = CucumberTestConfiguration.fromEnvironment()
        print("🔧 CucumberSwift Configuration: \(configuration)")
        switch configuration {
        case .stepBased:
            // Original behavior: each step is a separate test
            print("▶️ Using \(configuration) mode")
            for feature in Cucumber.shared.features.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
                let className = feature.title.toClassString() + readFeatureScenarioDelimiter()

                for scenario in feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true) {
                    let childSuite = XCTestSuite(name: scenario.title.toClassString())
                    var tests = [XCTestCase]()
                    createTestCaseFor(className: className, scenario: scenario, tests: &tests)
                    tests.forEach { childSuite.addTest($0) }
                    rootSuite.addTest(childSuite)
                }
            }
        case .scenarioBased:
            // New behavior: each scenario is a single test
            print("▶️ Using \(configuration) mode")
            print("📊 Total features found: \(Cucumber.shared.features.count)")
            for feature in Cucumber.shared.features.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
                print("🎯 Processing feature: \(feature.title) with \(feature.scenarios.count) scenarios")

                // Create a feature-level suite for better organization
                let featureSuite = XCTestSuite(name: feature.title.toClassString())
                let className = feature.title.toClassString()

                // Create one test class per feature
                guard let testCaseClass = TestCaseGenerator.makeClass(className: className) else {
                    print("❌ Failed to create test case class for feature: \(feature.title)")
                    continue
                }

                // Create a test case for each scenario
                let scenarios = feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true)

                for (index, scenario) in scenarios.enumerated() {
                    if let testCase = createTestCaseForScenario(testCaseClass: testCaseClass, scenario: scenario, scenarioIndex: index, totalScenarios: scenarios.count, feature: feature) {
                        featureSuite.addTest(testCase)
                    }
                }

                // Register the class only once after all methods are added
                objc_registerClassPair(testCaseClass)
                print("✅ Finished processing feature: \(feature.title) with \(feature.scenarios.count) scenarios")
                rootSuite.addTest(featureSuite)
            }
        }
    }

    private static func createTestCaseForStubs(_ tests: inout [XCTestCase]) {
        let stubs = StubGenerator.getStubs(for: Cucumber.shared.features)
        let generatedSwift = stubs.map(\.generatedSwift).joined(separator: "\n")

        guard !stubs.isEmpty else { return }
        if let (testCaseClass, methodSelector) = TestCaseGenerator.initWith(className: "Generated Steps", method: TestCaseMethod(withName: "GenerateStepsStubsIfNecessary", closure: {
            XCTContext.runActivity(named: "Pending Steps") { activity in
                let attachment = XCTAttachment(uniformTypeIdentifier: "swift",
                                               name: "GENERATED_Unimplemented_Step_Definitions.swift",
                                               payload: generatedSwift.data(using: .utf8),
                                               userInfo: nil)
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
        })) {
            objc_registerClassPair(testCaseClass)
            tests.append(testCaseClass.init(selector: methodSelector))
        }
    }

    private static func createTestCaseFor(className: String, scenario: Scenario, tests: inout [XCTestCase]) {
        let testCase = TestCaseGenerator.makeClass(className: className.appending(scenario.title.toClassString()))
        scenario
            .steps
            .lazy
            .compactMap { step -> (step: Step, XCTestCase.Type, Selector)? in // swiftlint:disable:this large_tuple
                if let testCase = testCase,
                   let methodSelector = TestCaseGenerator.addTestMethod(testCase: testCase, method: step.method) {
                    return (step, testCase, methodSelector)
                }
                return nil
            }
            .map { step, testCaseClass, methodSelector -> (Step, XCTestCase) in
                objc_registerClassPair(testCaseClass)
                return (step, testCaseClass.init(selector: methodSelector))
            }
            .forEach { step, testCase in
                testCase.addTeardownBlock {
                    (step.executeInstance as? XCTestCase)?.tearDown()
                    Cucumber.shared.afterStepHooks.forEach { $0.hook(step) }
                    Cucumber.shared.setupAfterHooksFor(step)
                    step.endTime = Date()
                }
                step.continueAfterFailure ?= (Cucumber.shared as? StepImplementation)?.continueTestingAfterFailure ?? testCase.continueAfterFailure
                step.testCase = testCase
                testCase.continueAfterFailure = step.continueAfterFailure
                tests.append(testCase)
            }
    }

    private static func createTestCaseForScenario(testCaseClass: XCTestCase.Type, scenario: Scenario, scenarioIndex: Int, totalScenarios: Int, feature: Feature) -> XCTestCase? {
        guard let methodSelector = TestCaseGenerator.addTestMethod(testCase: testCaseClass, method: scenario.method) else {
            return nil
        }

        let testCase = testCaseClass.init(selector: methodSelector)
        let isLastScenario = scenarioIndex == totalScenarios - 1

        testCase.addTeardownBlock {
            // Execute after scenario hooks
            Cucumber.shared.afterScenarioHooks.forEach { $0.hook(scenario) }
            // Notify all reporters
            let scenarioResult: Reporter.Result =
                (scenario.steps.contains { $0.result == .failed }) ? .failed : .passed
            Cucumber.shared.reporters.forEach {
                $0.didFinish(scenario: scenario,
                             result: scenarioResult,
                             duration: Measurement(value: Date().timeIntervalSince(scenario.startDate), unit: .seconds))
            }
            // Execute after feature hooks if this is the last scenario
            if isLastScenario {
                // Execute after feature hooks
                Cucumber.shared.afterFeatureHooks.forEach { $0.hook(feature) }
                // Notify all reporters
                let featureResult: Reporter.Result =
                    (feature.scenarios.contains { $0.steps.contains { $0.result == .failed } }) ? .failed : .passed
                Cucumber.shared.reporters.forEach {
                    $0.didFinish(feature: feature,
                                 result: featureResult,
                                 duration: Measurement(value: Date().timeIntervalSince(feature.startDate), unit: .seconds))
                }
            }
        }

        // Set continueAfterFailure based on any step's setting or default
        let continueAfterFailure = scenario.steps.first?.continueAfterFailure
            ?? (Cucumber.shared as? StepImplementation)?.continueTestingAfterFailure
            ?? testCase.continueAfterFailure
        testCase.continueAfterFailure = continueAfterFailure

        return testCase
    }

    override open func invokeTest() {
        guard !Self.didRun else {
            return
        }
        Self.didRun = true
        super.invokeTest()
    }

    // A test case needs at least one test to trigger the observer
    final func testGherkin() {
        XCTAssert(Gherkin.errors.isEmpty, "Gherkin language errors found:\n\(Gherkin.errors.joined(separator: "\n"))")

        Gherkin.errors.forEach {
            XCTFail($0)
        }

        StubGenerator.getStubs(for: Cucumber.shared.features).forEach { [self] in
            guard let sourceFile = $0.step.location.uri else { return }
            let attachment = XCTAttachment(uniformTypeIdentifier: "swift",
                                           name: "\(sourceFile):\($0.step.location.line)",
                                           payload: $0.generatedSwift.data(using: .utf8),
                                           userInfo: nil)

            failStep(XCTIssue(type: .assertionFailure,
                              compactDescription: "No CucumberSwift expression found that matches this step. Try adding the following Swift code to your step implementation file: \n\($0.generatedSwift)", // swiftlint:disable:this line_length
                              detailedDescription: nil,
                              sourceCodeContext: .init(location: .init(fileURL: sourceFile, lineNumber: Int($0.step.location.line))),
                              associatedError: nil,
                              attachments: [attachment]))
        }
    }

    public dynamic func failStep(_ issue: XCTIssue) {
        record(issue)
    }
}

extension CucumberTest {
    private static let defaultDelimiter = "|"

    private static func readFeatureScenarioDelimiter() -> String {
        guard let testBundle = (Cucumber.shared as? StepImplementation)?.bundle else { return defaultDelimiter }
        return (testBundle.infoDictionary?["FeatureScenarioDelimiter"] as? String) ?? defaultDelimiter
    }
}

extension Step {
    fileprivate var method: TestCaseMethod? {
        TestCaseMethod(withName: "\(keyword.toString()) \(match)".toClassString()) {
            guard !Cucumber.shared.failedScenarios.contains(where: { $0 === self.scenario }) else { return }
            let startTime = Date()
            self.startTime = startTime
            Cucumber.shared.currentStep = self
            Cucumber.shared.setupBeforeHooksFor(self)
            Cucumber.shared.beforeStepHooks.forEach { $0.hook(self) }

            func runAndReport() {
                Cucumber.shared.reporters.forEach { $0.didStart(step: self, at: startTime) }
                XCTAssertNoThrow(try self.run())
                self.endTime = Date()
                Cucumber.shared.reporters.forEach { $0.didFinish(step: self, result: self.result, duration: self.executionDuration) }
            }

#if compiler(>=5)
            XCTContext.runActivity(named: "\(self.keyword.toString()) \(self.match)") { _ in
                runAndReport()
            }
#else
            _ = XCTContext.runActivity(named: "\(self.keyword.toString()) \(self.match)") { _ in
                runAndReport()
            }
#endif
        }
    }

    fileprivate func run() throws {
        if let `class` = executeClass, let selector = executeSelector {
            executeInstance = (`class` as? NSObject.Type)?.init()
            if let instance = executeInstance,
               instance.responds(to: selector) {
                (executeInstance as? XCTestCase)?.setUp()
                instance.perform(selector)
            }
        } else {
            try execute?(self.match, self)
        }
        if execute != nil && result != .failed {
            result = .passed
        }
    }
}

extension Scenario {
    fileprivate var method: TestCaseMethod? {
        TestCaseMethod(withName: self.title.toClassString()) {
            guard !Cucumber.shared.failedScenarios.contains(where: { $0 === self }) else { return }

            // Execute before feature hooks and notify reporters if this is the first scenario in the feature
            if let feature = self.feature,
               let firstScenario = feature.scenarios.first,
               firstScenario === self {
                // Mark feature as started, execute before hooks and notify reporters
                feature.startDate = Date()
                Cucumber.shared.reporters.forEach { $0.didStart(feature: feature, at: feature.startDate) }
                Cucumber.shared.beforeFeatureHooks.forEach { $0.hook(feature) }
            }

            // Notify reporters and execute before scenario hooks
            self.startDate = Date()
            Cucumber.shared.reporters.forEach { $0.didStart(scenario: self, at: self.startDate) }
            Cucumber.shared.beforeScenarioHooks.forEach { $0.hook(self) }

            for step in self.steps {
                let startTime = Date()
                step.startTime = startTime
                Cucumber.shared.currentStep = step
                Cucumber.shared.reporters.forEach { $0.didStart(step: step, at: startTime) }
                Cucumber.shared.beforeStepHooks.forEach { $0.hook(step) }

                func runStep() {
                    XCTAssertNoThrow(try step.run())
                    step.endTime = Date()
                }

                #if compiler(>=5)
                XCTContext.runActivity(named: "\(step.keyword.toString()) \(step.match)") { _ in
                    runStep()
                }
                #else
                _ = XCTContext.runActivity(named: "\(step.keyword.toString()) \(step.match)") { _ in
                    runStep()
                }
                #endif

                // Run step teardown
                (step.executeInstance as? XCTestCase)?.tearDown()
                Cucumber.shared.afterStepHooks.forEach { $0.hook(step) }
                Cucumber.shared.reporters.forEach { $0.didFinish(step: step, result: step.result, duration: step.executionDuration) }
            }
        }
    }
}

extension String {
    fileprivate func toClassString() -> String {
        camelCasingString()
            .lazy
            .drop { !$0.isLetter }
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .map(String.init)
            .joined()
            .capitalizingFirstLetter()
    }
}
