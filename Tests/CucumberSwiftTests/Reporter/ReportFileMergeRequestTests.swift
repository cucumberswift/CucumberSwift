//
//  ReportFileMergeRequestTests.swift
//  CucumberSwiftTests
//
//  A run can ask every process that writes the report to merge into it, as parallel workers do (#518).
//

import Foundation
import XCTest

extension ReportFileTests {
    /// The mutation testing tool asks the XCTest and the Swift Testing process of one `swift test` to merge.
    func testTheReporterMergesIntoAnOldReportWhenTheRunAsksForIt() throws {
        setenv("CUCUMBERSWIFT_MERGE_REPORT", "YES", 1)
        addTeardownBlock { unsetenv("CUCUMBERSWIFT_MERGE_REPORT") }
        let names = try featureNamesAfterARunBesideAnotherWorker {
            try FileManager.default.setAttributes([.modificationDate: Date.distantPast], ofItemAtPath: self.url.path)
        }
        XCTAssertEqual(names.sorted(), ["F1", "Other"])
    }
}
