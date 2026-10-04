//
//  StepTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/22/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

class StepTest: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testAsteriskMatchesToGiven() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.given) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var givenCalled = false
        Given("a user with half a clue") { _, _ in
            givenCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(givenCalled)
    }

    func testAsteriskMatchesToWhen() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.when) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var whenCalled = false
        When("a user with half a clue") { _, _ in
            whenCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(whenCalled)
    }

    func testAsteriskMatchesToThen() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.then) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var thenCalled = false
        Then("a user with half a clue") { _, _ in
            thenCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(thenCalled)
    }

    func testAsteriskMatchesToAnd() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.and) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var andCalled = false
        And("a user with half a clue") { _, _ in
            andCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(andCalled)
    }

    func testAsteriskMatchesToBut() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.but) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var butCalled = false
        But("a user with half a clue") { _, _ in
            butCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(butCalled)
    }

    func testAsteriskMatchesToMatchAll() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var matchAllCalled = false
        MatchAll("a user with half a clue") { _, _ in
            matchAllCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(matchAllCalled)
    }

    func testKeywordHasMultipleValues() {
        XCTAssertFalse(Step.Keyword.given.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.when.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.then.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.and.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.but.hasMultipleValues())
        var kw: Step.Keyword = []
        XCTAssertFalse(kw.hasMultipleValues())

        kw = [.given, .when]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.given, .then]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.given, .and]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.given, .but]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.when, .then]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.when, .and]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.then, .and]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.then, .but]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.and, .but]
        XCTAssertTrue(kw.hasMultipleValues())
    }

    func testAKeywordIsNamedInTheLanguageItIsGiven() throws {
        let spanish = try XCTUnwrap(Language("es"))
        XCTAssertEqual(Step.Keyword.given.toString(in: spanish), "Dadas")
        XCTAssertEqual(Step.Keyword.when.toString(in: spanish), "Cuando")
        XCTAssertEqual(Step.Keyword.then.toString(in: spanish), "Entonces")
        XCTAssertEqual(Step.Keyword.and.toString(in: spanish), "E")
        XCTAssertEqual(Step.Keyword.but.toString(in: spanish), "Pero")
        let noKeyword: Step.Keyword = []
        XCTAssertEqual(noKeyword.toString(in: spanish), "UNKNOWN")
    }

    // A step describes itself in its own feature file's language, not the last parsed file's (#290).
    func testAStepsDescriptionUsesItsFeatureFilesLanguage() throws {
        let cucumber = Cucumber(withString: """
        Feature: Basket
            Scenario: Eating cukes
                Given I have 3 cukes
        """)
        cucumber.parseIntoFeatures("""
        # language: es
        Característica: Pepinos
            Escenario: Comer pepinos
                Cuando como 2 pepinos
        """)
        let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }

        XCTAssertEqual(steps.map(\.description), ["TAGS:[]\nGiven: I have 3 cukes", "TAGS:[]\nCuando: como 2 pepinos"])
    }

    // A step's keyword names itself as written in its own feature file, not in the last parsed file's language (#311).
    func testAStepsKeywordIsNamedAsWrittenInItsFeatureFile() throws {
        defer { Scope.language = .default }
        let cucumber = Cucumber(withString: """
        Feature: Basket
            Scenario: Eating cukes
                Given I have 3 cukes
                And I am hungry
                When I eat 2 cukes
        """)
        cucumber.parseIntoFeatures("""
        # language: es
        Característica: Pepinos
            Escenario: Comer pepinos
                Dado que tengo 3 pepinos
                Y tengo hambre
        """)
        let steps = cucumber.features.flatMap { $0.scenarios.flatMap(\.steps) }

        XCTAssertEqual(steps.map { $0.keyword.toString() }, ["Given", "And", "When", "Dado", "Y"])
        XCTAssert(steps[1].keyword.contains(.given), "An And step still continues the keyword before it")
    }

    // A keyword that was not read from a feature file is named in the last parsed file's language.
    func testAKeywordNotReadFromAFeatureFileIsNamedInTheLastParsedFilesLanguage() throws {
        defer { Scope.language = .default }
        let cucumber = Cucumber(withString: """
        # language: es
        Característica: Pepinos
            Escenario: Comer pepinos
                Dado que tengo 3 pepinos
        """)
        let step = try XCTUnwrap(cucumber.features.first?.scenarios.first?.steps.first)

        XCTAssertEqual(Step.Keyword.given.toString(), "Dadas")
        XCTAssertEqual(step.keyword.primaryKeywords.toString(), "Dadas")
        XCTAssertEqual(step.keyword, .given, "How a keyword is written does not change which keyword it is")
    }

    /// Regression test for #135: a step built by the Swift DSL used to compile the empty pattern
    /// `""` on every execution, which always throws. An uncompilable pattern is now recorded in
    /// `RegularExpression.errors`, so that is where the bug would show if it came back.
    func testExecutingADSLStepDoesNotCompileARegex() throws {
        var handlerCalled = false
        let step = GivenStep(line: 1,
                             column: 1,
                             match: "a step defined with the Swift DSL",
                             handler: { handlerCalled = true },
                             file: #file)

        let execute = try XCTUnwrap(step.execute)
        try execute(step.match, step)

        XCTAssert(handlerCalled)
        XCTAssert(RegularExpression.errors.snapshot.isEmpty,
                  "Executing a DSL step should not compile a regex. Errors:\n\(RegularExpression.errors.snapshot.map(\.message).joined(separator: "\n"))")
    }

    /// #218: a step definition's regex that will not compile is reported at the step definition,
    /// so Xcode marks the consumer's own line rather than a line inside CucumberSwift.
    func testAStringRegexThatWillNotCompileIsRecordedAtItsStepDefinition() {
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         When a broken step runs
    """)
        let pattern: String = "^a broken (step runs$"

        When(pattern, callback: { _, _ in }, line: 42, file: "StepDefinitions.swift")

        XCTAssertEqual(RegularExpression.errors.snapshot.count, 1, "The pattern should be recorded once, with its location")
        let problem = RegularExpression.errors.snapshot.first
        XCTAssertEqual(problem?.file, "StepDefinitions.swift")
        XCTAssertEqual(problem?.line, 42)
        XCTAssert(problem?.message.contains(pattern) ?? false)
#if compiler(>=5.7) && canImport(_StringProcessing)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            XCTAssert(problem?.message.hasSuffix("expected ')'") ?? false,
                      "The message should say what is wrong with the pattern: \(problem?.message ?? "")")
        }
#endif
        XCTAssertNil(Cucumber.shared.features.first?.scenarios.first?.steps.first?.execute,
                     "A pattern that will not compile can never match, so it should not be attached")
    }

    /// `testGherkin()` reports each pattern that will not compile as a failure: at its step
    /// definition when it has one, so Xcode marks the consumer's line, and otherwise from CucumberSwift.
    func testInvalidRegularExpressionsAreReportedAtTheirStepDefinitions() throws {
        let problems = [
            RegularExpression.Problem(message: "Invalid regular expression '^(': expected ')'",
                                      file: "/tmp/StepDefinitions.swift",
                                      line: 42),
            RegularExpression.Problem(message: "Invalid regular expression '@(': expected ')'", file: nil, line: nil)
        ]
        var issues = [XCTIssue]()

        CucumberTest.reportInvalidRegularExpressions(problems, file: "/tmp/CucumberTest.swift", line: 7) { issues.append($0) }

        XCTAssertEqual(issues.count, 2)
        let located = try XCTUnwrap(issues.first)
        XCTAssertEqual(located.type, .assertionFailure)
        XCTAssertEqual(located.compactDescription, "Invalid regular expression '^(': expected ')'")
        XCTAssertEqual(located.sourceCodeContext.location?.fileURL, URL(fileURLWithPath: "/tmp/StepDefinitions.swift"))
        XCTAssertEqual(located.sourceCodeContext.location?.lineNumber, 42)
        let unlocated = try XCTUnwrap(issues.last)
        XCTAssert(unlocated.compactDescription.hasPrefix("Invalid regular expression '@(': expected ')' (in CUCUMBER_TAGS"),
                  unlocated.compactDescription)
        XCTAssertEqual(unlocated.sourceCodeContext.location?.fileURL, URL(fileURLWithPath: "/tmp/CucumberTest.swift"))
        XCTAssertEqual(unlocated.sourceCodeContext.location?.lineNumber, 7)
    }

    func testAMissingStepDefinitionPointsAtStepDefinitionsThatWillNotCompile() {
        let problems = [
            RegularExpression.Problem(message: "Invalid regular expression '^(': expected ')'",
                                      file: "/tmp/StepDefinitions.swift",
                                      line: 12),
            RegularExpression.Problem(message: "Invalid regular expression '@(': expected ')'", file: nil, line: nil),
            RegularExpression.Problem(message: "Invalid regular expression '^[': expected ']'",
                                      file: "/tmp/MoreSteps.swift",
                                      line: 16)
        ]

        let message = CucumberTest.missingStepDefinitionMessage(generatedSwift: "When(\"a step\") { _, _ in }",
                                                                invalidRegularExpressions: problems)

        XCTAssertEqual(message, """
        No CucumberSwift expression found that matches this step. If you already wrote a step definition for it, \
        its regular expression may not compile: see StepDefinitions.swift:12 and MoreSteps.swift:16. \
        Otherwise, try adding the following Swift code to your step implementation file: \n\
        When("a step") { _, _ in }
        """)
    }

    func testAMissingStepDefinitionSuggestsCodeWhenEveryStepDefinitionCompiles() {
        let problems = [RegularExpression.Problem(message: "Invalid regular expression '@(': expected ')'", file: nil, line: nil)]

        let message = CucumberTest.missingStepDefinitionMessage(generatedSwift: "When(\"a step\") { _, _ in }",
                                                                invalidRegularExpressions: problems)

        XCTAssertEqual(message, """
        No CucumberSwift expression found that matches this step. \
        Try adding the following Swift code to your step implementation file: \n\
        When("a step") { _, _ in }
        """)
    }

    /// #100: Xcode saves an attachment as a file named after it, so a deep feature file path must not be in the name.
    func testAStubAttachmentIsNamedAfterTheFeatureFileNotItsFullPath() {
        let deepDirectory = (0..<30).reduce(FileManager.default.temporaryDirectory) { url, _ in
            url.appendingPathComponent("deeply", isDirectory: true)
        }
        let deepFile = deepDirectory.appendingPathComponent("Login.feature")

        let name = CucumberTest.stubAttachmentName(sourceFile: deepFile, line: 7)

        XCTAssertEqual(name, "Login.feature:7")
    }

    func testAStubAttachmentNameNeverExceedsTheFileNameLimit() {
        let fits = String(repeating: "a", count: 253)
        let tooLong = String(repeating: "a", count: 254)
        let multibyte = String(repeating: "é", count: 200)

        let fitting = CucumberTest.stubAttachmentName(sourceFile: URL(fileURLWithPath: fits), line: 7)
        let capped = CucumberTest.stubAttachmentName(sourceFile: URL(fileURLWithPath: tooLong), line: 7)
        let cappedMultibyte = CucumberTest.stubAttachmentName(sourceFile: URL(fileURLWithPath: multibyte), line: 7)

        XCTAssertEqual(fitting, fits + ":7")
        XCTAssertEqual(capped, fits + ":7")
        XCTAssertEqual(capped.utf8.count, 255)
        XCTAssertLessThanOrEqual(cappedMultibyte.utf8.count, 255)
        XCTAssertTrue(cappedMultibyte.hasSuffix(":7"))
    }

    /// #100: Xcode can only preview and open a stub attachment whose type is Swift source.
    func testAStubAttachmentIsSwiftSourceWithItsNameAndCode() throws {
        let attachment = CucumberTest.stubAttachment(named: "Login.feature:3", generatedSwift: "Given(\"a step\") { _, _ in }")

        XCTAssertEqual(attachment.uniformTypeIdentifier, "public.swift-source")
        XCTAssertEqual(attachment.name, "Login.feature:3")
    }

    /// #220: a Cucumber Expression that is treated as a regular expression but will not compile is
    /// reported at the step definition too, instead of crashing the run.
    func testAnExpressionRegexThatWillNotCompileIsRecordedAtItsStepDefinition() {
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         When a broken step runs
    """)

        When("^a broken (step runs$", callback: { _, _ in }, line: 42, file: "StepDefinitions.swift")

        XCTAssertEqual(RegularExpression.errors.snapshot.count, 1, "The expression should be recorded once, with its location")
        let problem = RegularExpression.errors.snapshot.first
        XCTAssertEqual(problem?.file, "StepDefinitions.swift")
        XCTAssertEqual(problem?.line, 42)
        XCTAssert(problem?.message.hasPrefix(#"CucumberExpression: "^a broken (step runs$""#) ?? false,
                  problem?.message ?? "")
        XCTAssertNil(Cucumber.shared.features.first?.scenarios.first?.steps.first?.execute,
                     "An expression that will not compile can never match, so it should not be attached")
    }
}
