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

    private static var hasBeenBuilt = false

    #if DEBUG
    static func resetSetUp() {
        hasBeenBuilt = false
    }
    #endif

    override public class var defaultTestSuite: XCTestSuite {
        Cucumber.shared.reporters.forEach { $0.testSuiteStarted(at: Date()) }

        // XCTest discovers CucumberTest in both the test bundle and the framework,
        // calling defaultTestSuite for each. Only the first call should return a
        // populated suite. Subsequent calls return an empty suite to prevent double
        // execution of scenarios and hooks, and to avoid "Invalid attempt to start
        // a test run that has already been started".
        guard !hasBeenBuilt else {
            return XCTestSuite(name: String(describing: CucumberTest.self))
        }

        Cucumber.shared.features.removeAll()
        DuplicateStepDefinition.reset()
        let bundle = (Cucumber.shared as? StepImplementation)?.bundle
        if let bundle = bundle {
            Cucumber.shared.readFromFeaturesFolder(in: bundle)
        }
        (Cucumber.shared as? StepImplementation)?.setupSteps()

        hasBeenBuilt = true
        // Report a missing Features folder as a failing test rather than stopping the
        // process, so every other test in the bundle still runs and the reason is shown.
        guard !Cucumber.shared.features.isEmpty else {
            return noFeaturesSuite(bundle: bundle)
        }

        let suite = XCTestSuite(forTestCaseClass: CucumberTest.self)
        generateAlltests(suite)
        return suite
    }

    static func noFeaturesSuite(bundle: Bundle?, reportFailure: @escaping (String) -> Void = { XCTFail($0) }) -> XCTestSuite {
        let suite = XCTestSuite(name: String(describing: CucumberTest.self))
        let message = noFeaturesMessage(bundle: bundle)
        if let (testCaseClass, methodSelector) = TestCaseGenerator.initWith(className: "CucumberSwift",
                                                                            method: TestCaseMethod(withName: "FoundNoFeatures", closure: { reportFailure(message) })) {
            objc_registerClassPair(testCaseClass)
            suite.addTest(testCaseClass.init(selector: methodSelector))
        }
        return suite
    }

    static func noFeaturesMessage(bundle: Bundle?) -> String {
        guard let bundle = bundle else {
            return "CucumberSwift found no features to run, because Cucumber does not conform to StepImplementation in this test bundle. "
                + "Add `extension Cucumber: StepImplementation` with a `bundle` and a `setupSteps()`."
        }
        return "CucumberSwift found no features to run. It looks for a folder named Features (case sensitive) in \(bundle.bundleURL.path), "
            + "the bundle your StepImplementation's `bundle` returns. "
            + "With Swift Package Manager, add `resources: [.copy(\"Features\")]` to your test target and return `Bundle.module`. "
            + "If you use the DSL, define your features in `setupSteps()`."
    }

    static func generateAlltests(_ rootSuite: XCTestSuite) {
        let stubsSuite = XCTestSuite(name: "GeneratedSteps")
        var stubTests = [XCTestCase]()
        createTestCaseForStubs(&stubTests)
        stubTests.forEach { stubsSuite.addTest($0) }
        rootSuite.addTest(stubsSuite)

        for feature in Cucumber.shared.features.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
            let className = generatedTestName(feature.title) + readFeatureScenarioDelimiter()

            for scenario in feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true) {
                let childSuite = XCTestSuite(name: className + generatedTestName(scenario.title))
                var tests = [XCTestCase]()
                createTestCaseFor(className: className, scenario: scenario, tests: &tests)
                tests.forEach { childSuite.addTest($0) }
                rootSuite.addTest(childSuite)
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
        let testCase = TestCaseGenerator.makeClass(className: className.appending(generatedTestName(scenario.title)),
                                                   superclass: StepTestCase.superclass)
        if let testCase = testCase {
            objc_registerClassPair(testCase)
        }
        scenario
            .steps
            .enumerated()
            .lazy
            .compactMap { index, step -> (step: Step, XCTestCase.Type, Selector)? in // swiftlint:disable:this large_tuple
                if let testCase = testCase,
                   let methodSelector = TestCaseGenerator.addTestMethod(testCase: testCase, method: step.method(at: index, of: scenario.steps.count)) {
                    return (step, testCase, methodSelector)
                }
                return nil
            }
            .map { step, testCaseClass, methodSelector -> (Step, XCTestCase) in
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
                StepTestCase.setStep(step, of: testCase)
                testCase.continueAfterFailure = step.continueAfterFailure
                tests.append(testCase)
            }
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
        let gherkinErrors = Gherkin.errors.snapshot
        XCTAssert(gherkinErrors.isEmpty, "Gherkin language errors found:\n\(gherkinErrors.joined(separator: "\n"))")

        gherkinErrors.forEach {
            XCTFail($0)
        }

        let invalidRegularExpressions = RegularExpression.errors.snapshot
        Self.reportInvalidRegularExpressions(invalidRegularExpressions) { [self] in failStep($0) }
        Self.reportInvalidRegularExpressions(DuplicateStepDefinition.errors) { [self] in failStep($0) }

        StubGenerator.getStubs(for: Cucumber.shared.features).forEach { [self] in
            guard let sourceFile = $0.step.location.uri else { return }
            let attachment = XCTAttachment(uniformTypeIdentifier: "swift",
                                           name: "\(sourceFile):\($0.step.location.line)",
                                           payload: $0.generatedSwift.data(using: .utf8),
                                           userInfo: nil)

            failStep(XCTIssue(type: .assertionFailure,
                              compactDescription: Self.missingStepDefinitionMessage(generatedSwift: $0.generatedSwift,
                                                                                    invalidRegularExpressions: invalidRegularExpressions),
                              detailedDescription: nil,
                              sourceCodeContext: .init(location: .init(fileURL: sourceFile, lineNumber: Int($0.step.location.line))),
                              associatedError: nil,
                              attachments: [attachment]))
        }
    }

    /// The failure for a step that no step definition matches. A step definition whose regular expression
    /// will not compile is never attached, so its steps land here too; when there are any, say where they
    /// are, so the consumer does not write a second definition for a step they already defined.
    static func missingStepDefinitionMessage(generatedSwift: String,
                                             invalidRegularExpressions: [RegularExpression.Problem]) -> String {
        let locations = invalidRegularExpressions.compactMap { problem -> String? in
            guard let file = problem.file, let line = problem.line else { return nil }
            return "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        }
        let suggestion = "the following Swift code to your step implementation file: \n\(generatedSwift)"
        guard let last = locations.last else {
            return "No CucumberSwift expression found that matches this step. Try adding \(suggestion)"
        }
        let list = locations.count == 1 ? last : locations.dropLast().joined(separator: ", ") + " and " + last
        return "No CucumberSwift expression found that matches this step. If you already wrote a step definition for it, its regular expression may not compile: see \(list). Otherwise, try adding \(suggestion)" // swiftlint:disable:this line_length
    }

    /// The failure for a step that more than one step definition matches. None of them runs, because
    /// CucumberSwift cannot tell which one the step means; the message says where each one is.
    static func ambiguousStepMessage(for step: Step) -> String {
        ambiguousStepMessage(step: "\(step.keyword.toString()) \(step.match)", definitions: step.matchingDefinitions)
    }

    static func ambiguousStepMessage(step: String, definitions: [Step.Definition]) -> String {
        let locations = definitions.map { "\(URL(fileURLWithPath: String($0.file)).lastPathComponent):\($0.line)" }
        let list = locations.count < 2 ? locations.joined() : locations.dropLast().joined(separator: ", ") + " and " + (locations.last ?? "")
        return "Ambiguous step '\(step)': it matches \(locations.count) step definitions, at \(list). Remove all but one of them, or make their patterns more specific." // swiftlint:disable:this line_length
    }

    /// Records an ambiguous step's failure at the step in its feature file, as for a step with no step definition.
    static func ambiguousStepIssue(for step: Step) -> XCTIssue {
        let location = step.location.uri.map { XCTSourceCodeLocation(fileURL: $0, lineNumber: Int(step.location.line)) }
        return XCTIssue(type: .assertionFailure,
                        compactDescription: ambiguousStepMessage(for: step),
                        detailedDescription: nil,
                        sourceCodeContext: location.map { XCTSourceCodeContext(location: $0) } ?? XCTSourceCodeContext(),
                        associatedError: nil,
                        attachments: [])
    }

    /// Fails an ambiguous step on the test XCTest is running, at the step in its feature file. With no
    /// running test known, it fails whatever test is current, without the feature-file location.
    static func recordAmbiguousStep(_ step: Step, on runningTestCase: XCTestCase?) {
        guard let runningTestCase = runningTestCase else {
            XCTFail(ambiguousStepMessage(for: step))
            return
        }
        runningTestCase.record(ambiguousStepIssue(for: step))
    }

    /// Records one failure for each problem found in the step definitions, such as a regular expression
    /// that will not compile or a duplicate step definition. A problem from a step definition fails at
    /// that step definition, so Xcode marks the consumer's own line. One with no step definition, such
    /// as a `CUCUMBER_TAGS` filter, fails here.
    static func reportInvalidRegularExpressions(_ problems: [RegularExpression.Problem],
                                                file: StaticString = #filePath,
                                                line: Int = #line,
                                                record: (XCTIssue) -> Void) {
        problems.forEach { problem in
            let description: String
            let location: XCTSourceCodeLocation
            if let problemFile = problem.file, let problemLine = problem.line {
                description = problem.message
                location = XCTSourceCodeLocation(fileURL: URL(fileURLWithPath: problemFile), lineNumber: problemLine)
            } else {
                description = "\(problem.message) (in CUCUMBER_TAGS or a pattern CucumberSwift could not trace to a step definition)"
                location = XCTSourceCodeLocation(filePath: String(file), lineNumber: line)
            }
            record(XCTIssue(type: .assertionFailure,
                            compactDescription: description,
                            detailedDescription: nil,
                            sourceCodeContext: .init(location: location),
                            associatedError: nil,
                            attachments: []))
        }
    }

    public dynamic func failStep(_ issue: XCTIssue) {
        record(issue)
    }
}

extension Step {
    func method(at index: Int, of count: Int) -> TestCaseMethod? {
        let readable = (Cucumber.shared as? StepImplementation)?.readableTestNames ?? false
        // Readable names show the keyword as written; camel-case names keep the ones tests already have.
        let text = "\(readable ? writtenKeyword : keyword.toString()) \(match)"
        return TestCaseMethod(withName: Self.methodName(for: text, at: index, of: count, readable: readable)) {
            guard !Cucumber.shared.failedScenarios.contains(where: { $0 === self.scenario }),
                  !StepTestCase.skippedScenarios.contains(where: { $0.scenario === self.scenario }) else { return }
            let startTime = Date()
            self.startTime = startTime
            Cucumber.shared.currentStep = self
            Cucumber.shared.setupBeforeHooksFor(self)
            Cucumber.shared.beforeStepHooks.forEach { $0.hook(self) }

            func runAndReport() {
                Cucumber.shared.reporters.forEach { $0.didStart(step: self, at: startTime) }
                self.runSkippingScenarioOnXCTSkip()
                self.endTime = Date()
                Cucumber.shared.reporters.forEach { $0.didFinish(step: self, result: self.result, duration: self.executionDuration) }
            }

            #if compiler(>=5)
            XCTContext.runActivity(named: "\(self.writtenKeyword) \(self.match)") { _ in
                runAndReport()
            }
            #else
            _ = XCTContext.runActivity(named: "\(self.writtenKeyword) \(self.match)") { _ in
                runAndReport()
            }
            #endif
        }
    }

    /// Runs the step. One that throws `XCTSkip` skips its scenario: it and the steps after it don't run.
    fileprivate func runSkippingScenarioOnXCTSkip() {
        var skip: XCTSkip?
        XCTAssertNoThrow(try {
            do {
                try self.run()
            } catch let thrown as XCTSkip {
                skip = thrown
            }
        }())
        if let skip = skip {
            recordSkip(skip)
        }
    }

    /// Records that the step threw `XCTSkip`, so the rest of its scenario doesn't run. A step that
    /// already failed stays failed, so the scenario is still reported as failed.
    func recordSkip(_ skip: XCTSkip) {
        if result != .failed && result != .ambiguous {
            result = .skipped
        }
        if let scenario = scenario {
            StepTestCase.skippedScenarios.append((scenario, skip.message ?? "Skipped"))
        }
    }

    fileprivate func run() throws {
        if isAmbiguous {
            // Record first: a recorded failure sets the step's result to failed, and this one is ambiguous.
            CucumberTest.recordAmbiguousStep(self, on: Cucumber.shared.runningTestCase)
            errorMessage = CucumberTest.ambiguousStepMessage(for: self)
            result = .ambiguous
            return
        }
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
