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

    /// Records the issue in `test`, the feature's last test. Without a test, as when a parallel worker
    /// finishes its features after its last test, or for a warning that XCTest before Xcode 26 can't record
    /// as one, it prints it instead.
    func record(in test: XCTestCase?, output: (String) -> Void = { print($0) }) {
        #if compiler(>=6.2)
        let canRecord = true
        #else
        let canRecord = severity == .error
        #endif
        guard let test, canRecord else {
            output("\(file?.path ?? ""):\(line): \(severity == .warning ? "warning" : "error"): \(message)")
            return
        }
        test.record(xcTestIssue)
    }
}
