//
//  GeneratedStepDefinitionTests.swift
//  CucumberSwiftTests
//

import Foundation
import XCTest
@testable import CucumberSwift

/// Checks that the step definitions CucumberSwift generates compile and work, in both regex
/// literal styles, by comparing the generator's output with copies that are compiled:
/// `GeneratedStepDefinitions.swift` here (`#/…/#`) and `GeneratedBareSlashStepDefinitions.swift` in
/// CucumberSwiftConsumerTests (`/…/`), a target with bare slash regex literals turned on.
class GeneratedStepDefinitionTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testCompiledExtendedDelimiterStepDefinitionsMatchTheGenerator() throws {
        let file = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("GeneratedStepDefinitions.swift")
        try assertGeneratedSection(of: file, equalsGeneratorOutputFor: .extendedDelimiter)
    }

    func testCompiledBareSlashStepDefinitionsMatchTheGenerator() throws {
        let file = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CucumberSwiftConsumerTests/GeneratedBareSlashStepDefinitions.swift")
        try assertGeneratedSection(of: file, equalsGeneratorOutputFor: .bareSlash)
    }

    func testGeneratedStepDefinitionsMatchEveryStep() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) else {
            throw XCTSkip("Regex literals need iOS 16, macOS 13 or tvOS 16")
        }
        Cucumber.shared.parseIntoFeatures(GeneratedStepDefinitions.feature)
        GeneratedStepDefinitions.register()

        XCTAssertEqual(StubGenerator.getStubs(for: Cucumber.shared.features).map(\.generatedSwift), [],
                       "Every step should have a step definition")

        // The steps are not executed: every generated step fails until it is filled in.
        let steps = Cucumber.shared.features.flatMap(\.scenarios).flatMap(\.steps)
        XCTAssertEqual(steps.count, 10)
        steps.forEach { XCTAssertTrue($0.canExecute, "\($0.keyword) \($0.match)") }
    }

    private func assertGeneratedSection(of file: URL,
                                        equalsGeneratorOutputFor style: RegexLiteralStyle,
                                        line: UInt = #line) throws {
        let generated = StubGenerator.getStubs(for: Cucumber(withString: GeneratedStepDefinitions.feature).features,
                                               regexLiteralStyle: style)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
        guard let begin = lines.firstIndex(where: { $0.hasSuffix("// BEGIN GENERATED") }),
              let end = lines.firstIndex(where: { $0.hasSuffix("// END GENERATED") }),
              begin < end else {
            return XCTFail("\(file.lastPathComponent) has no BEGIN GENERATED and END GENERATED lines", line: line)
        }
        let indentation = String(lines[begin].prefix { $0 == " " })
        let compiled = lines[(begin + 1)..<end]
            .map { $0.hasPrefix(indentation) ? String($0.dropFirst(indentation.count)) : $0 }
            .joined(separator: "\n")
        XCTAssertEqual(compiled, generated,
                       "\(file.lastPathComponent) no longer matches the generator. Replace its generated section with:\n\(generated)",
                       line: line)
    }
}
