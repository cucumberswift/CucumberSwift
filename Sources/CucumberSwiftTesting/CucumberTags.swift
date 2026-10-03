//
//  CucumberTags.swift
//  CucumberSwiftTesting
//

import Foundation

/// CucumberSwift's `CUCUMBER_TAGS` filter. The generated tests ask it whether each scenario runs.
public enum CucumberTags {
    /// Whether a scenario with `tags` runs. `CUCUMBER_TAGS` is a comma-separated list of regular
    /// expressions, matched without regard to case, and a scenario runs when any of its tags (the
    /// feature's, its own, and an outline's Examples blocks') matches any of them. Without the
    /// variable, every scenario runs.
    public static func shouldRun(_ tags: [String],
                                 environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard let filter = environment["CUCUMBER_TAGS"] else { return true }
        let patterns = filter.components(separatedBy: ",")
        return tags.contains { tag in
            patterns.contains { pattern in
                guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
                return regex.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)) != nil
            }
        }
    }
}
