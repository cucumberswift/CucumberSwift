//
//  CoverageIssuesTests.swift
//  CucumberSwiftTests
//
//  The XCTest runner records a coverage score past its level as a test issue at its line of the feature
//  file: a warning that doesn't fail the test, or an error that does (#502).
//

import Foundation
import XCTest
@testable import CucumberSwift

final class CoverageIssuesTests: XCTestCase {
    private let file = FileManager.default.temporaryDirectory.appendingPathComponent("Arithmetic.feature")

    func testAnIssueIsAtItsLineOfTheFeatureFile() {
        let issue = CoverageIssue(severity: .warning, message: "Feature coverage 71%", file: file, line: 3).xcTestIssue
        XCTAssertEqual(issue.compactDescription, "Feature coverage 71%")
        XCTAssertEqual(issue.sourceCodeContext.location?.fileURL, file)
        XCTAssertEqual(issue.sourceCodeContext.location?.lineNumber, 3)
    }

    func testAWarningDoesNotFailTheTest() {
        let warning = CoverageIssue(severity: .warning, message: "Feature coverage 71%", file: file, line: 1)
        #if compiler(>=6.2)
        XCTAssertEqual(warning.xcTestIssue.severity, .warning)
        #endif
        warning.record(in: self)
    }

    func testAnErrorFailsTheTest() {
        let error = CoverageIssue(severity: .error, message: "Feature coverage 44%", file: file, line: 1)
        XCTAssertEqual(error.xcTestIssue.type, .assertionFailure)
        XCTExpectFailure("A coverage error fails the test.") {
            error.record(in: self)
        }
    }

    func testWithoutATestTheIssueIsPrinted() {
        // Nothing to record it in, as when a parallel worker finishes its features after its last test.
        var printed = [String]()
        CoverageIssue(severity: .error, message: "Feature coverage 44%", file: file, line: 1).record(in: nil) { printed.append($0) }
        XCTAssertEqual(printed, ["\(file.path):1: error: Feature coverage 44%"])
    }

    func testAFeatureFilesIssuesGoToItsURI() throws {
        let cucumber = Cucumber(withString: "Feature: Arithmetic")
        let feature = try XCTUnwrap(cucumber.features.first)
        XCTAssertNil(feature.coverageIssueFile)
    }
}
