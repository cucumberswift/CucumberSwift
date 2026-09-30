//
//  Cucumber.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
import CucumberSwiftExpressions

@objc public class Cucumber: NSObject { // swiftlint:disable:this type_body_length
    @objc public static let shared = Cucumber()

    var features = [Feature]()
    var currentStep: Step?
    let runningTestCaseObserver = RunningTestCaseObserver()
    /// The test XCTest is running, so a failure can be recorded on it with a location of our choosing.
    var runningTestCase: XCTestCase? { runningTestCaseObserver.testCase }
    var reportName: String = "CucumberTestResultsFor"
    var environment: [String: String] = ProcessInfo.processInfo.environment

    private var reverseOrderForAfterHooks: Bool {
        (Cucumber.shared as? StepImplementation)?.reverseOrderForAfterHooks ?? false
    }

    private var _beforeFeatureHooks = [FeatureHook]()
    var beforeFeatureHooks: [FeatureHook] {
        get {
            _beforeFeatureHooks.sorted()
        } set {
            _beforeFeatureHooks = newValue
        }
    }
    private var _afterFeatureHooks = [FeatureHook]()
    var afterFeatureHooks: [FeatureHook] {
        get {
            reverseOrderForAfterHooks ? _afterFeatureHooks.sorted().reversed() : _afterFeatureHooks.sorted()
        } set {
            _afterFeatureHooks = newValue
        }
    }
    private var _beforeScenarioHooks = [ScenarioHook]()
    var beforeScenarioHooks: [ScenarioHook] {
        get {
            _beforeScenarioHooks.sorted()
        } set {
            _beforeScenarioHooks = newValue
        }
    }
    private var _afterScenarioHooks = [ScenarioHook]()
    var afterScenarioHooks: [ScenarioHook] {
        get {
            reverseOrderForAfterHooks ? _afterScenarioHooks.sorted().reversed() : _afterScenarioHooks.sorted()
        } set {
            _afterScenarioHooks = newValue
        }
    }
    private var _beforeStepHooks = [StepHook]()
    var beforeStepHooks: [StepHook] {
        get {
            _beforeStepHooks.sorted()
        } set {
            _beforeStepHooks = newValue
        }
    }
    private var _afterStepHooks = [StepHook]()
    var afterStepHooks: [StepHook] {
        get {
            reverseOrderForAfterHooks ? _afterStepHooks.sorted().reversed() : _afterStepHooks.sorted()
        } set {
            _afterStepHooks = newValue
        }
    }

    var hookedFeatures       = [Feature]()
    var hookedScenarios      = [Scenario]()
    var failedScenarios      = [Scenario]()
    lazy var reporters: [CucumberTestObserver] = {
        ([CucumberJSONReporter()] + ((self as? CucumberTestObservable)?.observers ?? [])).compactMap { $0 }
    }()

    override public init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
        XCTestObservationCenter.shared.addTestObserver(runningTestCaseObserver)
    }

    init(withString string: String) {
        super.init()
        parseIntoFeatures(string)
    }

    @objc public static func Load() {
        guard let testSuiteInit = class_getClassMethod(XCTestSuite.self, #selector(XCTestSuite.init(forTestCaseWithName:))),
              let swizzledInit = class_getClassMethod(self, #selector(Cucumber.testCaseWith(name:))) else {
            return
        }
        method_exchangeImplementations(testSuiteInit, swizzledInit)
    }

    @objc static func testCaseWith(name: String) -> XCTestSuite? {
        if name == "CucumberTest" {
            return CucumberTest.defaultTestSuite
        }

        guard let className = name.components(separatedBy: "/").first,
              let testCaseClass = Bundle.allBundles.compactMap({
                  $0.classNamed(className)
              }).first else { return nil }

        return XCTestSuite(forTestCaseClass: testCaseClass)
    }

    func readFromFeaturesFolder(in testBundle: Bundle) {
        let featuresURL = { () -> URL in
            if let relativePath = (testBundle.infoDictionary?["FeaturesPath"] as? String) {
                return testBundle.bundleURL.appendingPathComponent(relativePath)
            } else if let featuresPath = testBundle.url(forResource: "Features", withExtension: nil) {
                return featuresPath
            } else {
                return testBundle.bundleURL.appendingPathComponent("Features")
            }
        }()
        featureFiles(at: featuresURL).forEach { url in
            if let string = try? String(contentsOf: url, encoding: .utf8) {
                Cucumber.shared.parseIntoFeatures(string, uri: url.absoluteString)
            }
        }
    }

    private func featureFiles(at featuresURL: URL) -> [URL] {
        let enumerator: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(at: featuresURL, includingPropertiesForKeys: nil)
        var fileList = [URL]()
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == "feature" {
                fileList.append(url)
            }
        }
        return fileList.sorted { $0.absoluteString < $1.absoluteString }
    }

    func setupBeforeHooksFor(_ step: Step) {
        if let feature = step.scenario?.feature,
           !hookedFeatures.contains(where: { $0 === feature }) {
            hookedFeatures.append(feature)
            beforeFeatureHooks.forEach { $0.hook(feature) }
            reporters.forEach { $0.didStart(feature: feature, at: Date()) }
        }
        if let scenario = step.scenario,
           !hookedScenarios.contains(where: { $0 === scenario }) {
            hookedScenarios.append(scenario)
            beforeScenarioHooks.forEach { $0.hook(scenario) }
            scenario.startDate = Date()
            reporters.forEach { $0.didStart(scenario: scenario, at: scenario.startDate) }
        }
    }

    func setupAfterHooksFor(_ step: Step) {
        if let scenario = step.scenario,
           let lastScenarioStep = scenario.steps.last,
           lastScenarioStep === step {
            Cucumber.shared.afterScenarioHooks.forEach { $0.hook(scenario) }
            let result: Reporter.Result = (scenario.steps.contains { $0.result == .failed || $0.result == .ambiguous }) ? .failed : .passed
            reporters.forEach { $0.didFinish(scenario: scenario,
                                             result: result,
                                             duration: Measurement(value: Date().timeIntervalSince(scenario.startDate),
                                                                   unit: .seconds))
            }
        }
        if let feature = step.scenario?.feature,
           let lastStep = feature.scenarios.last(where: { !$0.steps.isEmpty })?.steps.last,
           lastStep === step {
            Cucumber.shared.afterFeatureHooks.forEach { $0.hook(feature) }
            let result: Reporter.Result = (feature.scenarios.contains { $0.steps.contains { $0.result == .failed || $0.result == .ambiguous } }) ? .failed : .passed
            reporters.forEach { $0.didFinish(feature: feature,
                                             result: result,
                                             duration: Measurement(value: Date().timeIntervalSince(feature.startDate),
                                                                   unit: .seconds))
            }
        }
    }

    func parseIntoFeatures(_ string: String, uri: String = "") {
        let tokens = Lexer(string, uri: uri).lex()
        features.append(contentsOf: AST.standard.parse(tokens, inFile: uri)
            .map { Feature(with: $0, uri: uri) })
    }

    /// Every step definition that matches the text, from every step it could run on, each counted once,
    /// with the first such step.
    private func matchingDefinitions(keyword: Step.Keyword?, matching: String) -> [(definition: Step.Definition, step: Step)] {
        var matches = [(definition: Step.Definition, step: Step)]()
        let steps = features.flatMap { $0.scenarios.flatMap { $0.steps } }
        for step in steps where keyword.map({ step.keyword.contains($0) }) ?? true {
            for definition in step.matchingDefinitions where definition.matches(matching) {
                if !matches.contains(where: { $0.definition === definition }) {
                    matches.append((definition: definition, step: step))
                }
            }
        }
        return matches
    }

    func executeFirstStep(keyword: Step.Keyword? = nil, matching: String) {
        let matches = matchingDefinitions(keyword: keyword, matching: matching)
        guard let (definition, step) = matches.first else {
            XCTFail("No CucumberSwift expression found that matches step '\(matching)'")
            return
        }
        if matches.count > 1 {
            XCTFail(CucumberTest.ambiguousStepMessage(step: matching, definitions: matches.map(\.definition)))
        } else {
            XCTAssertNoThrow(try definition.execute?(matching, step))
        }
    }

    /// From inside an async step or hook, runs the first matching step definition and waits for it.
    @MainActor
    func executeFirstStep(keyword: Step.Keyword? = nil, matching: String) async {
        let matches = matchingDefinitions(keyword: keyword, matching: matching)
        guard let (definition, step) = matches.first else {
            XCTFail("No CucumberSwift expression found that matches step '\(matching)'")
            return
        }
        guard matches.count == 1 else {
            XCTFail(CucumberTest.ambiguousStepMessage(step: matching, definitions: matches.map(\.definition)))
            return
        }
        do {
            if let executeAsync = definition.executeAsync {
                try await executeAsync(matching, step)
            } else {
                try definition.execute?(matching, step)
            }
        } catch {
            XCTFail("ExecuteFirstStep threw error \"\(error)\"")
        }
    }

    /// A step definition's body: synchronous, or async and run to completion by `AsyncStepRunner`.
    private enum StepBody {
        case sync(Step.Execute)
        case async(Step.AsyncExecute)
    }

    private func attachClosureToSteps(keyword: Step.Keyword?,
                                      body: StepBody? = nil,
                                      matchesExpression: @escaping Step.MatchesExpression,
                                      line: Int,
                                      file: StaticString,
                                      executeSelector: Selector? = nil,
                                      executeClass: AnyClass? = nil) {
        let execute: Step.Execute?
        let executeAsync: Step.AsyncExecute?
        switch body {
            case .sync(let body)?:
                execute = body
                executeAsync = nil
            case .async(let body)?:
                execute = AsyncStepRunner.blockingStep(body)
                executeAsync = body
            case nil:
                execute = nil
                executeAsync = nil
        }
        let definition = Step.Definition(file: file, line: line, matches: matchesExpression, execute: execute, executeAsync: executeAsync)
        features
            .flatMap { $0.scenarios.flatMap { $0.steps } }
            .filter { step -> Bool in
                if  let k = keyword,
                    step.keyword.contains(k) {
                    return matchesExpression(step.match)
                } else if keyword == nil {
                    return matchesExpression(step.match)
                }
                return false
            }
            .forEach { step in
                step.matchingDefinitions.append(definition)
                step.result = .undefined
                step.execute = execute
                step.executeAsync = executeAsync
                step.matchesExpression = matchesExpression
                step.sourceLine = line
                step.sourceFile = file
                step.executeSelector = executeSelector
                step.executeClass = executeClass
            }
    }

    func attachClosureToSteps(keyword: Step.Keyword? = nil,
                              regex: String,
                              callback: @escaping (([String], Step) throws -> Void),
                              line: Int,
                              file: StaticString) {
        guard RegularExpression.validate(regex, file: file, line: line) else { return }
        DuplicateStepDefinition.register(pattern: regex, keyword: keyword, file: file, line: line)
        attachClosureToSteps(keyword: keyword,
                             body: .sync { match, step in try callback(match.matches(for: regex), step) },
                             matchesExpression: { str in !str.matches(for: regex).isEmpty },
                             line: line,
                             file: file)
    }

    func attachClosureToSteps(keyword: Step.Keyword? = nil,
                              regex: String,
                              asyncCallback: @escaping @MainActor ([String], Step) async throws -> Void,
                              line: Int,
                              file: StaticString) {
        guard RegularExpression.validate(regex, file: file, line: line) else { return }
        DuplicateStepDefinition.register(pattern: regex, keyword: keyword, file: file, line: line)
        attachClosureToSteps(keyword: keyword,
                             body: .async { match, step in try await asyncCallback(match.matches(for: regex), step) },
                             matchesExpression: { str in !str.matches(for: regex).isEmpty },
                             line: line,
                             file: file)
    }

    func attachClosureToSteps(keyword: Step.Keyword? = nil,
                              expression: CucumberExpression,
                              callback: @escaping ((CucumberSwiftExpressions.Match, Step) throws -> Void),
                              line: Int,
                              file: StaticString) {
        // An anchored or slash-delimited expression is a regular expression. If it will not compile it
        // can never match, and matching it would trap, so report it at the step definition instead.
        if let invalid = expression.invalidRegularExpression {
            RegularExpression.errors.append(.init(message: invalid.description, file: String(file), line: line))
            return
        }
        DuplicateStepDefinition.register(pattern: expression.regex, keyword: keyword, file: file, line: line)
        attachClosureToSteps(keyword: keyword,
                             body: .sync { match, step in try callback(try XCTUnwrap(expression.match(in: match)), step) },
                             matchesExpression: { str in expression.match(in: str) != nil },
                             line: line,
                             file: file)
    }

    func attachClosureToSteps(keyword: Step.Keyword? = nil,
                              expression: CucumberExpression,
                              asyncCallback: @escaping @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void,
                              line: Int,
                              file: StaticString) {
        if let invalid = expression.invalidRegularExpression {
            RegularExpression.errors.append(.init(message: invalid.description, file: String(file), line: line))
            return
        }
        DuplicateStepDefinition.register(pattern: expression.regex, keyword: keyword, file: file, line: line)
        attachClosureToSteps(keyword: keyword,
                             body: .async { match, step in try await asyncCallback(try XCTUnwrap(expression.match(in: match)), step) },
                             matchesExpression: { str in expression.match(in: str) != nil },
                             line: line,
                             file: file)
    }

#if compiler(>=5.7) && canImport(_StringProcessing)
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func attachClosureToSteps<Output>(keyword: Step.Keyword? = nil,
                                      regex: Regex<Output>,
                                      callback: @escaping ((Regex<Output>.Match, Step) throws -> Void),
                                      line: Int,
                                      file: StaticString) {
        attachClosureToSteps(keyword: keyword,
                             body: .sync { match, step in try callback(try XCTUnwrap(regex.wholeMatch(in: match)), step) },
                             matchesExpression: { str in (try? regex.wholeMatch(in: str)) != nil },
                             line: line,
                             file: file)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func attachClosureToSteps<Output>(keyword: Step.Keyword? = nil,
                                      regex: Regex<Output>,
                                      asyncCallback: @escaping @MainActor (Regex<Output>.Match, Step) async throws -> Void,
                                      line: Int,
                                      file: StaticString) {
        attachClosureToSteps(keyword: keyword,
                             body: .async { match, step in try await asyncCallback(try XCTUnwrap(regex.wholeMatch(in: match)), step) },
                             matchesExpression: { str in (try? regex.wholeMatch(in: str)) != nil },
                             line: line,
                             file: file)
    }
#endif

    func attachClosureToSteps(keyword: Step.Keyword? = nil,
                              regex: String,
                              class: AnyClass,
                              selector: Selector,
                              line: Int,
                              file: StaticString) {
        guard RegularExpression.validate(regex, file: file, line: line) else { return }
        DuplicateStepDefinition.register(pattern: regex, keyword: keyword, file: file, line: line)
        attachClosureToSteps(keyword: keyword,
                             matchesExpression: { str in !str.matches(for: regex).isEmpty },
                             line: line,
                             file: file,
                             executeSelector: selector,
                             executeClass: `class`)
    }
}
