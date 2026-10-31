//
//  ScenarioRule.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink.
//

import Foundation

/// The Rule a scenario is in. The coverage scores score a Rule's scenarios on their own, and report
/// on the Rule's line.
struct ScenarioRule: Hashable, Sendable {
    let title: String
    let line: Int
}
