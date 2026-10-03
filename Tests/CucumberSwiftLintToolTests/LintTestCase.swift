@testable import CucumberSwiftLintTool
import XCTest

/// Writes a feature file, and optionally a Swift file of step definitions, and checks them.
class LintTestCase: XCTestCase {
    var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    /// The diagnostics for `feature` as "line:column message".
    func lint(_ feature: String, steps: String? = nil) throws -> [String] {
        try check(feature, steps: steps).map { "\($0.line):\($0.column) \($0.message)" }
    }

    func check(_ feature: String, steps: String?) throws -> [Diagnostic] {
        let featureFile = directory.appendingPathComponent("Test.feature")
        try feature.write(to: featureFile, atomically: true, encoding: .utf8)
        var swiftFiles = [String]()
        if let steps = steps {
            let stepsFile = directory.appendingPathComponent("Steps.swift")
            try steps.write(to: stepsFile, atomically: true, encoding: .utf8)
            swiftFiles.append(stepsFile.path)
        }
        return Linter.check(features: [featureFile.path], stepDefinitionFiles: swiftFiles)
    }
}
