//
//  CoverageIssues.swift
//  CucumberSwiftTesting
//

import Foundation

extension Feature {
    /// Where a coverage issue about the feature goes: its feature file where you edit it, as the step
    /// failures do.
    var coverageIssueFile: URL? {
        URL(fileURLWithPath: sourcePath)
    }
}

extension CoverageIssue {
    /// Prints the issue with its feature file and line, as a compiler prints a warning. It records nothing:
    /// the runner reports a feature's scores after the feature's last scenario, where no test is running,
    /// and Xcode stops the test process when a suite records an issue (#509). An error doesn't fail a test
    /// with this runner.
    func record(output: (String) -> Void = { print($0) }) {
        output("\(file?.path ?? ""):\(max(line, 1)): \(severity == .warning ? "warning" : "error"): \(message)")
    }
}
