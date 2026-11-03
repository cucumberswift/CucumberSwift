//
//  CoverageIssues.swift
//  CucumberSwiftTesting
//

import Foundation
import Testing

extension Feature {
    /// Where a coverage issue about the feature goes: its feature file where you edit it, as the step
    /// failures do.
    var coverageIssueFile: URL? {
        URL(fileURLWithPath: sourcePath)
    }
}

extension CoverageIssue {
    /// Prints the issue with its feature file and line, as a compiler prints a warning, and records
    /// nothing: the runner reports a feature's scores after the feature's last scenario, where no test is
    /// running, and Xcode stops the test process when a suite records an issue (#509). An error doesn't
    /// fail a test then.
    ///
    /// With `inSuite`, which ``Cucumber/coverageRecordsIssuesInSuites`` turns on, it records the issue in
    /// the suite instead, and an error fails the suite. A warning doesn't fail it. Swift Testing before
    /// Swift 6.3 can't record a warning, so it prints it.
    func record(inSuite: Bool = false, output: (String) -> Void = { print($0) }) {
        guard inSuite else {
            output("\(file?.path ?? ""):\(max(line, 1)): \(severity == .warning ? "warning" : "error"): \(message)")
            return
        }
        let location = SourceLocation(fileID: "Features/\(file?.lastPathComponent ?? "")",
                                      filePath: file?.path ?? "",
                                      line: max(line, 1),
                                      column: 1)
        #if compiler(>=6.3)
        Issue.record(Comment(rawValue: message), severity: severity == .warning ? .warning : .error, sourceLocation: location)
        #else
        if severity == .error {
            Issue.record(Comment(rawValue: message), sourceLocation: location)
        } else {
            output("\(file?.path ?? ""):\(max(line, 1)): warning: \(message)")
        }
        #endif
    }
}
