//
//  CoverageIssues.swift
//  CucumberSwift
//

import Foundation
import XCTest

extension Feature {
    /// Where a coverage issue about the feature goes: its feature file, as the step failures do.
    var coverageIssueFile: URL? {
        URL(string: uri)
    }
}

extension CoverageIssue {
    /// The issue as XCTest records it, at its line of the feature file. A warning doesn't fail the test.
    var xcTestIssue: XCTIssue {
        let context = XCTSourceCodeContext(location: file.map { XCTSourceCodeLocation(fileURL: $0, lineNumber: line) })
        #if compiler(>=6.2)
        return XCTIssue(type: .assertionFailure,
                        compactDescription: message,
                        detailedDescription: nil,
                        sourceCodeContext: context,
                        associatedError: nil,
                        attachments: [],
                        severity: severity == .warning ? .warning : .error)
        #else
        return XCTIssue(type: .assertionFailure,
                        compactDescription: message,
                        detailedDescription: nil,
                        sourceCodeContext: context,
                        associatedError: nil,
                        attachments: [])
        #endif
    }

    /// Records the issue in `test`, the feature's last test, and prints a warning too, as the Swift Testing
    /// runner does: `swift test` and `xcodebuild test` print an error that fails a test, but not a warning.
    /// Without a test, as when a parallel worker finishes its features after its last test, or for a warning
    /// that XCTest before Xcode 26 can't record as one, it only prints the issue.
    func record(in test: XCTestCase?, output: (String) -> Void = { print($0) }) {
        #if compiler(>=6.2)
        let canRecord = true
        #else
        let canRecord = severity == .error
        #endif
        if severity == .warning || test == nil {
            output(printedLine)
        }
        guard let test, canRecord else { return }
        test.record(xcTestIssue)
    }
}
