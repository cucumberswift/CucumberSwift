//
//  ReportStaleAfter.swift
//  CucumberSwift
//
// Its own file, not part of FeatureFlagValue.swift, because cucumberswift coverage merge compiles that file
// through a symlink, without ReportFile. This folder is compiled by CucumberSwift and, through a symlink, by
// CucumberSwiftTesting.

import Foundation

extension FeatureFlagValue {
    /// How long a report can go unwritten before a worker takes it for an earlier run's: the static variable
    /// when it is a number of seconds above 0, then the environment variable, then
    /// ``ReportFile/staleAfter``. Both runners read the setting through it.
    static func reportStaleAfter(setting: TimeInterval?, environment: String?) -> TimeInterval {
        if let setting, setting.isFinite, setting > 0 { return setting }
        return seconds(environment) ?? ReportFile.staleAfter
    }
}
