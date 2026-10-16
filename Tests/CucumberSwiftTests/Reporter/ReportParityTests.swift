//
//  ReportParityTests.swift
//  CucumberSwiftTests
//
//  CucumberSwift and CucumberSwiftTesting write one Cucumber JSON report for the same feature files (#420).
//  This is CucumberSwift's side: it writes ParityReport.json's report for ParityFeature below. The
//  Swift Testing runner's tests (CucumberSwiftTestingTests/ReportTests.swift) check that the runner writes
//  the same report for the same feature, from the same file.
//

import Foundation
import JSONSchema
import XCTest
@testable import CucumberSwift

@MainActor
final class ReportParityTests: XCTestCase {
    /// The feature both runners write ParityReport.json for. The Swift Testing test builds the same
    /// scenarios by hand: keep them in step.
    static let feature = """
    @shop
    Feature: Checkout
      Collect payment for the basket.

      Background:
        Given a basket

      @fast
      Scenario: Pay by card
        When I pay by card
        Then the order is paid

      Scenario Outline: Pay <amount>
        When I pay <amount>
        Then the order is paid

        Examples:
          | amount |
          | 5      |
          | 10     |
    """

    static let uri = "file:///Features/Checkout.feature"

    private var folder: URL!

    /// The report with each duration replaced by 0, as text with its keys in order: durations differ
    /// from one run to the next.
    static func withoutDurations(_ data: Data) throws -> String {
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        return text.replacingOccurrences(of: #""duration" : [0-9.e+-]+"#, with: #""duration" : 0"#, options: .regularExpression)
    }

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("ReportParityTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { [folder] in folder.map { try? FileManager.default.removeItem(at: $0) } }
        Cucumber.shared.reset()
    }

    private func directory(of file: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: "\(file)").deletingLastPathComponent()
    }

    func testTheReportIsTheOneBothRunnersWrite() throws {
        let path = folder.appendingPathComponent("report.json")
        Cucumber.reportPath = path.path
        addTeardownBlock { Cucumber.reportPath = nil }
        let reporter = try XCTUnwrap(Cucumber.shared.reporters.compactMap { $0 as? CucumberJSONReporter }.first)
        Cucumber.shared.parseIntoFeatures(Self.feature, uri: Self.uri)
        Given("a basket") { _, _ in }
        When("I pay by card") { _, _ in }
        When("I pay {int}") { _, _ in }
        Then("the order is paid") { _, _ in }

        reporter.testSuiteStarted(at: Date())
        Cucumber.shared.executeFeatures()
        reporter.testSuiteFinished(at: Date())

        let written = try Data(contentsOf: path)
        let expected = try Data(contentsOf: directory().appendingPathComponent("ParityReport.json"))
        XCTAssertEqual(try Self.withoutDurations(written), try Self.withoutDurations(expected))

        let schema = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: directory().appendingPathComponent("Schema.json"))) as? [String: Any])
        let result = try JSONSchema.validate(JSONSerialization.jsonObject(with: written), schema: schema)
        XCTAssertEqual(result.errors?.count ?? 0, 0, "\(String(describing: result.errors))")
    }
}
