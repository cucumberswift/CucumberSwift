//
//  CucumberTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/21/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

extension Collection where Element == Lexer.Token {
    public var text: String {
        return compactMap { (token) -> String? in
            switch token {
                case .match(_, let t):
                    return t
                case .tableHeader(_, let t):
                    return "<\(t)>"
                default: return nil
            }
        }.joined()
    }
}

@available(iOS 16.0, *)
class CucumberTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    typealias TestType = (feature: String, ast: String)

    private func getTests(atPath path: String) -> [String: TestType] {
        var tests: [String: TestType] = [:]
        let testDataDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(path)

        let enumerator: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(at: testDataDir, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {
            if url.absoluteString.hasSuffix(".feature") {
                if let string = try? String(contentsOf: url, encoding: .utf8) {
                    let name = url.absoluteString.components(separatedBy: ".feature").first!
                    var test: TestType = tests[name] ?? ("", "")
                    test.feature = string
                    tests[name] = test
                }
            } else if url.absoluteString.hasSuffix(".feature.ast.ndjson") {
                if let string = try? String(contentsOf: url, encoding: .utf8) {
                    let name = url.absoluteString.components(separatedBy: ".feature.ast.ndjson").first!
                    var test: TestType = tests[name] ?? ("", "")
                    test.ast = string
                    tests[name] = test
                }
            }
        }
        return tests
    }

    private func testSteps(scope: [String: Any], stepObjects: [Step], fileName: String) {
        if let steps = scope["steps"] as? [[String: Any]] {
            XCTAssertEqual(steps.count, stepObjects.count, "Step count is not the same")
            for (stepIndex, step) in steps.enumerated() {
                let stepObject = stepObjects[safe: stepIndex]
                if let keyword = step["keyword"] as? String {
                    if keyword.trimmingCharacters(in: .whitespaces) == "*" { return }
                    XCTAssertEqual(keyword.trimmingCharacters(in: .whitespaces), stepObject?.keyword.toString())
                }
                if let text = step["text"] as? String {
                    XCTAssertEqual(text, stepObject?.tokens.text, "Text does not match in: \(fileName)")
                }
                if let location = step["location"] as? [String: Any],
                    let line = location["line"] as? UInt,
                    let column = location["column"] as? UInt {
                    XCTAssertEqual(Lexer.Position(line: line, column: column), stepObject?.location)
                }
                if let docString = step["docString"] as? [String: Any],
                    let content = docString["content"] as? String {
                    XCTAssertEqual(content, stepObject?.docString?.literal)
                    if let contentType = docString["contentType"] as? String {
                        XCTAssertEqual(contentType, stepObject?.docString?.contentType)
                    }
                }
                if let dataTable = step["dataTable"] as? [String: Any],
                    let rows = dataTable["rows"] as? [[String: Any]] {
                    guard let dataTable = stepObject?.dataTable else { XCTFail("Step does not have a datatable"); return }
                    XCTAssertEqual(dataTable.rows.count, rows.count, "Rows don't match in: \(fileName)")
                    for (rowIndex, row) in rows.enumerated() {
                        let dRow = dataTable.rows[safe: rowIndex]
                        if let cells = row["cells"] as? [[String: Any]] {
                            XCTAssertEqual(dRow?.count, cells.count, "Row on DataTable doesn't have correct cells in: \(fileName)")
                            for (cellIndex, cell) in cells.enumerated() {
                                if let value = cell["value"] as? String {
                                    XCTAssertEqual(String(value), dRow?[safe: cellIndex], fileName)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func testFeature(_ feature: [String: Any], featureNodes: [AST.FeatureNode], fileName: String) {
        guard let featureNode = featureNodes.first else { XCTFail("Should have been a feature in \(fileName)");return }
        let featureObj = Feature(with: featureNode)
        if let name = feature["name"] as? String {
            XCTAssertEqual(name, featureObj.title)
        }
        if let tags = (feature["tags"] as? [[String: Any]])?.compactMap({ $0["name"] as? String}) {
            tags.map { String($0.dropFirst()) }.forEach {
                XCTAssert(featureObj.tags.contains($0), "expected \(featureObj.tags) to contain \($0)")
            }
        }
        if let children = feature["children"] as? [[String: Any]] {
            XCTAssertEqual(featureNode.children.count, children.count, "Wrong number of children in \(featureObj.title), fileName:\(fileName)")
            for (childIndex, child) in children.enumerated() {
                let node = featureNode.children[safe: childIndex]
                if let tags = (child["tags"] as? [[String: Any]])?.compactMap({ $0["name"] as? String}) {
                    tags.map { String($0.dropFirst()) }.forEach {
                        let tags: [String] = node?.tokens.compactMap {
                            if case .tag(_, let tagName) = $0 {
                                return tagName
                            }
                            return nil
                        } ?? []
                        XCTAssert(tags.contains($0), "expected \(tags) to contain \($0)")
                    }
                }
                if let background = child["background"] as? [String: Any] {
                    guard let backgroundNode = node as? AST.BackgroundNode else { XCTFail("No background node found");return }
                    let backgroundSteps: [Step] = backgroundNode.children.compactMap { $0 as? AST.StepNode }.map { Step(with: $0) }
                    testSteps(scope: background, stepObjects: backgroundSteps, fileName: name)
                }
                if let scenario = child["scenario"] as? [String: Any] {
                    guard let scenarioType = scenario["keyword"] as? String else { return }
                    if scenarioType == "Scenario" {
                        guard let scenarioNode = node as? AST.ScenarioNode else { XCTFail("No scenario node found in file: \(fileName)");return }
                        let scenarioSteps: [Step] = scenarioNode.children.compactMap { $0 as? AST.StepNode }.map { Step(with: $0) }
                        testSteps(scope: scenario, stepObjects: scenarioSteps, fileName: name)
                    } else if scenarioType == "Scenario Outline" {
                        testScenarioOutline(scenario, node: node, fileName: fileName)
                    }
                }
            }
        }
    }

    private func testScenarioOutline(_ scenarioOutline: [String: Any], node: AST.Node?, fileName: String) {
        guard let scenarioNode = node as? AST.ScenarioOutlineNode else { XCTFail("No scenario node found in file: \(fileName)");return }
        let parsedScenarios = ScenarioOutlineParser.parse(scenarioNode, featureTags: [], backgroundStepNodes: [])
        let examplesTokens = ScenarioOutlineParser.getExamplesFrom(scenarioNode)
        if let examples = scenarioOutline["examples"] as? [[String: Any]] {
            for (i, example) in examples.enumerated() {
                let lines = examplesTokens[safe: i]?.filter { $0.isTableCell() || $0.isNewline() }.groupedByLine()
                if let header = (example["tableHeader"] as? [String: Any])?["cells"] as? [[String: Any]] {
                    let headerTokens = lines?.first
                    XCTAssertEqual(header.count, headerTokens?.count, "Wrong number of cells in header in file: \(fileName)")
                    for (cellIndex, cell) in header.enumerated() {
                        let headerToken = headerTokens?[safe: cellIndex]
                        if let token = headerToken, case .tableCell(_, let value) = token {
                            XCTAssertEqual(cell["value"] as? String, value.valueDescription)
                        }
                    }
                }
                if let tableBody = (example["tableBody"] as? [[String: Any]]) {
                    let scenario = parsedScenarios[safe: i]
                    XCTAssertNotNil(scenario, "Expected example \(example) to be found, but there was none in file: \(fileName)")
                    for (rowIndex, row) in tableBody.enumerated() {
                        if let cells = row["cells"] as? [[String: Any]] {
                            let lineTokens = Array(lines?.dropFirst() ?? [])[safe: rowIndex]
                            XCTAssertEqual(cells.count, lineTokens?.count, "Wrong number of cells in table body in file: \(fileName)")
                            for (cellIndex, cell) in cells.enumerated() {
                                let cellToken = lineTokens?[safe: cellIndex]
                                if let token = cellToken, case .tableCell(_, let value) = token {
                                    XCTAssertEqual(cell["value"] as? String, value.valueDescription, "Wrong cell value in file: \(fileName)")
                                }
                            }
                        }
                    }
                }
            }
        }
        testSteps(scope: scenarioOutline, stepObjects: scenarioNode.children.compactMap { $0 as? AST.StepNode }.map { Step(with: $0) }, fileName: fileName)
    }

    func testGoodExamples() {
        let tests: [String: TestType] = getTests(atPath: "testdata/good")

        tests.forEach { (name, test) in
            let tokens = Lexer(test.feature, uri: "test.feature").lex()
            if  let data = test.ast.data(using: .utf8),
                let expectedAST = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let document = expectedAST["gherkinDocument"] as? [String: Any] {
                if let feature = document["feature"] as? [String: Any] {
                    testFeature(feature, featureNodes: AST.standard.parse(tokens), fileName: name)
                }
            }
        }
    }

    func testDefaultTestSuiteInvalidatesCacheAfterSuiteHasRun() {
        CucumberTest.resetSuiteCache()
        let firstSuite = CucumberTest.defaultTestSuite

        // Actually run the suite so XCTest sets its testRun with start/stop dates
        firstSuite.run()
        XCTAssertNotNil(firstSuite.testRun?.stopDate, "Suite should have a completed test run")

        // After the suite has been run, requesting defaultTestSuite again
        // should return a NEW suite, not the stale one whose testRun already completed
        let secondSuite = CucumberTest.defaultTestSuite
        XCTAssertFalse(firstSuite === secondSuite,
                        "defaultTestSuite must not return a suite whose test run has already completed")
    }

    func testFeatureScenarioDelimiter() {
        let featureName = "SomeTerseYetDescriptiveTextOfWhatIsDesired"

        // Tests default delimiter "|"
        CucumberTest.resetSuiteCache()
        let defaultSuite = CucumberTest.defaultTestSuite
        XCTAssertTrue(CucumberTest.defaultTestSuite === defaultSuite, "Suite should be cached on repeated calls")
        defaultSuite
            .tests
            .map { $0.name }
            .filter { $0.contains(featureName) }
            .forEach { testName in
                XCTAssertTrue(testName.contains("\(featureName)|"), "Test name does not contain default delimiter")
            }

        // Sets custom delimiter "_"
        Bundle.swizzleInfoDictionary()

        // Tests custom delimiter "_"
        CucumberTest.resetSuiteCache()
        CucumberTest.defaultTestSuite
            .tests
            .map { $0.name }
            .filter { $0.contains(featureName) }
            .forEach { testName in
                XCTAssertFalse(testName.contains("\(featureName)|"), "Test name contains default delimiter but there should be the custom")
                XCTAssertTrue(testName.contains("\(featureName)_"), "Test name does not contain custom delimiter")
            }
    }
}

extension Bundle {
    @objc fileprivate func swizzledInfoDictionary() -> [String: Any]? {
        ["FeatureScenarioDelimiter": "_"]
    }
    /// Sets `FeatureScenarioDelimiter: "_"`
    fileprivate static func swizzleInfoDictionary() {
        let instance = Bundle()
        let aClass: AnyClass! = object_getClass(instance)
        let originalMethod = class_getInstanceMethod(aClass, #selector(getter: infoDictionary))
        let swizzledMethod = class_getInstanceMethod(aClass, #selector(swizzledInfoDictionary))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            // switch implementation..
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
