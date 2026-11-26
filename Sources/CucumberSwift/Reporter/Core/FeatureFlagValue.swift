//
//  FeatureFlagValue.swift
//  CucumberSwift
//
// How a feature flag's environment variable is read. This folder is compiled by CucumberSwift and, through
// a symlink, by CucumberSwiftTesting, so both runners accept the same values.

import Foundation

enum FeatureFlagValue {
    /// `YES`, `TRUE` or `1`, and `NO`, `FALSE` or `0`, in any case, with spaces and tabs around them
    /// ignored. Any other value is not a setting.
    static func bool(_ value: String?) -> Bool? {
        switch value?.trimmingCharacters(in: .whitespaces).uppercased() {
            case "YES", "TRUE", "1": return true
            case "NO", "FALSE", "0": return false
            default: return nil
        }
    }

    /// A number of seconds above 0, with spaces and tabs around it ignored. Any other value is not a setting.
    static func seconds(_ value: String?) -> TimeInterval? {
        guard let text = value?.trimmingCharacters(in: .whitespaces),
              let seconds = TimeInterval(text),
              seconds.isFinite,
              seconds > 0 else { return nil }
        return seconds
    }
}
