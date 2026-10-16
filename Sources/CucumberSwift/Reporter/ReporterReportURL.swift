//
//  ReporterReportURL.swift
//  CucumberSwift
//

import Foundation

extension Reporter {
    /// Where the Cucumber JSON report is: ``Cucumber/reportPath``, or `_cucumberReport.json` in the documents
    /// folder.
    static var reportURL: URL? {
        if let path = FeatureFlags.reportPath { return URL(fileURLWithPath: path) }
        return CucumberJSONReport.defaultURL
    }
}
