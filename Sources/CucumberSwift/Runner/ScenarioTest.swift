//
//  ScenarioTest.swift
//  CucumberSwift
//
//  With `Cucumber.oneTestPerScenario`, each scenario is one test of `CucumberScenarioTest`, an Objective-C
//  class in the CucumberSwiftObjC target, rather than a test class with a test for each step. Xcode's
//  test navigator can then run a single scenario: it asks XCTest for `CucumberScenarioTest/<the test's
//  name>`, which XCTest can find, because that class is compiled into the bundle, unlike the classes
//  made for each scenario.
//

import Foundation
import XCTest
#if canImport(CucumberSwiftObjC)
import CucumberSwiftObjC
#endif

/// Only its method's type encoding is read: that of a throwing method that takes no arguments, which is
/// what a scenario's test is.
@objc private protocol ScenarioTestSignature {
    func scenarioTest() throws
}

extension CucumberTest {
    /// How far a scenario's test got, for the teardown that finishes the steps it didn't.
    private final class Progress {
        var finished = 0
    }

    /// A scenario's test is a throwing method, as Swift's `func test() throws` is to Objective-C, so a
    /// step that throws `XCTSkip` can skip the whole test.
    private static let errorSuffix = "AndReturnError:"

    /// The scenario whose test is running.
    private static var scenarioUnderTest: Scenario?

    /// The Objective-C class the scenarios' tests belong to. In the Xcode project it is compiled into this
    /// framework, which can't import it, so it is found by name there.
    static var scenarioTestClass: XCTestCase.Type? {
        #if canImport(CucumberSwiftObjC)
        // Named directly so that the linker keeps it in a SwiftPM consumer's test bundle.
        return CucumberScenarioTest.self
        #else
        return NSClassFromString("CucumberScenarioTest") as? XCTestCase.Type
        #endif
    }

    /// Reads the feature files and sets up the steps, once. Running one scenario from Xcode's test
    /// navigator needs them before XCTest asks for the suite, or without it asking at all.
    static func loadFeaturesIfNeeded() {
        guard !featuresLoaded else { return }
        featuresLoaded = true
        Cucumber.shared.features.removeAll()
        DuplicateStepDefinition.reset()
        if let bundle = (Cucumber.shared as? StepImplementation)?.bundle {
            Cucumber.shared.readFromFeaturesFolder(in: bundle)
        }
        (Cucumber.shared as? StepImplementation)?.setupSteps()
    }

    /// Each scenario that will run, with the name of its test: its feature's and its own, as in
    /// `Checkout|PayWithAGiftCard`, and a number when that would repeat an earlier one's.
    static func scenarioTests() -> [(name: String, scenario: Scenario)] {
        var tests = [(name: String, scenario: Scenario)]()
        var names = Set<String>()
        for feature in Cucumber.shared.features.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
            let prefix = generatedTestName(feature.title) + readFeatureScenarioDelimiter()
            for scenario in feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true) {
                let base = prefix + generatedTestName(scenario.title)
                var name = base
                var count = 1
                while names.contains(name) {
                    count += 1
                    name = "\(base) \(count)"
                }
                names.insert(name)
                tests.append((name, scenario))
            }
        }
        return tests
    }

    static func addScenarioTests(to rootSuite: XCTestSuite) {
        guard let testClass = scenarioTestClass else { return }
        for (name, scenario) in scenarioTests() {
            guard let selector = addScenarioMethod(named: name, running: scenario) else { continue }
            rootSuite.addTest(testClass.init(selector: selector))
        }
    }

    @discardableResult
    static func addScenarioMethod(named name: String, running scenario: Scenario) -> Selector? {
        guard let testClass = scenarioTestClass else { return nil }
        let selector = sel_registerName(name + errorSuffix)
        let body: @convention(block) (XCTestCase, AutoreleasingUnsafeMutablePointer<NSError?>?) -> Bool = { test, error in
            guard let skip = run(scenario, on: test) else { return true }
            error?.pointee = skip as NSError
            return false
        }
        let signature = protocol_getMethodDescription(ScenarioTestSignature.self, #selector(ScenarioTestSignature.scenarioTest), true, true)
        guard class_addMethod(testClass, selector, imp_implementationWithBlock(body), signature.types)
                || testClass.instancesRespond(to: selector) else { return nil }
        return selector
    }

    /// Adds the test for a scenario when XCTest asks for one by name before anything has added it.
    static func resolveScenarioTest(named selectorName: String) -> Bool {
        guard selectorName.hasSuffix(errorSuffix) else { return false }
        // The flag can be set in setupSteps(), so the features and steps are loaded first.
        loadFeaturesIfNeeded()
        guard FeatureFlags.isOneTestPerScenario else { return false }
        let name = String(selectorName.dropLast(errorSuffix.count))
        guard let scenario = scenarioTests().first(where: { $0.name == name })?.scenario else { return false }
        return addScenarioMethod(named: name, running: scenario) != nil
    }

    /// The issue at the running step's line in its feature file, when a scenario's test records it.
    static func locateScenarioIssue(_ issue: XCTIssue) -> XCTIssue {
        guard let scenario = scenarioUnderTest,
              let step = Cucumber.shared.currentStep,
              step.scenario === scenario else { return issue }
        return StepTestCase.issue(issue, locatedAt: step)
    }

    /// Runs the scenario's steps in order, each as an activity, with the same hooks as a test per step.
    /// Once a step fails, has no step definition, or throws `XCTSkip`, the rest don't run, and each shows
    /// as a skipped activity. Returns the skip when a step skipped the scenario and none failed.
    static func run(_ scenario: Scenario, on test: XCTestCase) -> XCTSkip? {
        scenarioUnderTest = scenario
        defer { scenarioUnderTest = nil }
        // As with a test per step: when the StepImplementation says not to continue after a failure,
        // XCTest stops the test at the failed assertion. The teardown then gives the steps that didn't
        // finish their hooks, so After hooks still run.
        test.continueAfterFailure = (Cucumber.shared as? StepImplementation)?.continueTestingAfterFailure ?? true
        let progress = Progress()
        test.addTeardownBlock {
            scenario.steps.dropFirst(progress.finished).forEach(finish)
        }
        for (index, step) in scenario.steps.enumerated() {
            step.testCase = test
            if StepTestCase.skipReason(for: step) != nil {
                XCTContext.runActivity(named: "Skipped: \(step.writtenKeyword) \(step.match)") { _ in
                    // Empty on purpose: the activity only shows in the test report that the step didn't run.
                }
            } else if !step.canExecute && !step.isAmbiguous {
                recordMissingStepDefinition(for: step, on: test)
            } else {
                step.method(at: index, of: scenario.steps.count)?.closure()
            }
            finish(step)
            progress.finished = index + 1
        }
        guard !Cucumber.shared.failedScenarios.contains(where: { $0 === scenario }) else { return nil }
        return StepTestCase.skippedScenarios.first { $0.scenario === scenario }.map { XCTSkip($0.reason) }
    }

    /// A step's hooks and cleanup after it ran or was skipped.
    private static func finish(_ step: Step) {
        (step.executeInstance as? XCTestCase)?.tearDown()
        Cucumber.shared.afterStepHooks.forEach { $0.hook(step) }
        Cucumber.shared.setupAfterHooksFor(step)
        step.endTime = Date()
    }

    /// Fails a step that no step definition matches, at its line in the feature file. A full run reports
    /// it in testGherkin too, but a scenario run on its own from the test navigator doesn't run that.
    private static func recordMissingStepDefinition(for step: Step, on test: XCTestCase) {
        Cucumber.shared.currentStep = step
        let stub = StubGenerator.getStubs(for: Cucumber.shared.features).first { $0.step.match == step.match }?.generatedSwift
        let message = missingStepDefinitionMessage(generatedSwift: stub ?? "",
                                                   invalidRegularExpressions: RegularExpression.errors.snapshot)
        let location = step.location.uri.map { XCTSourceCodeLocation(fileURL: $0, lineNumber: Int(step.location.line)) }
        test.record(XCTIssue(type: .assertionFailure,
                             compactDescription: message,
                             detailedDescription: nil,
                             sourceCodeContext: location.map { XCTSourceCodeContext(location: $0) } ?? XCTSourceCodeContext(),
                             associatedError: nil,
                             attachments: []))
    }
}
