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
    /// Records the issue in the running test, at its line of the feature file. A warning doesn't fail the
    /// test. Swift Testing before Swift 6.3 can't record a warning, so it prints it instead.
    func record() {
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
            print("\(file?.path ?? ""):\(line): warning: \(message)")
        }
        #endif
    }
}
