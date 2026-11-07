//
//  Taggable.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 5/13/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public protocol Taggable {
    var tags: [String] { get }
    func containsTags(_ tags: [String]) -> Bool
}
extension Taggable {
    func containsTag(_ tag: String) -> Bool {
        tags.contains { !$0.matches(for: tag).isEmpty }
    }
}

extension Array where Element: Taggable {
    func taggedElements(with environment: [String: String] = ProcessInfo.processInfo.environment, askImplementor: Bool) -> [Element] {
        let tagged = tagged(with: environment, askImplementor: askImplementor)
        // `CUCUMBER_SCENARIOS` names the scenarios to run, and applies to scenarios only, not to features.
        guard environment[ScenarioList.variable] != nil else { return tagged }
        return tagged.filter { element in
            guard let scenario = element as? Scenario else { return true }
            return ScenarioList.runs(feature: scenario.feature?.uri ?? "", line: Int(scenario.location.line), environment: environment)
        }
    }

    private func tagged(with environment: [String: String], askImplementor: Bool) -> [Element] {
        if let tagNames = environment["CUCUMBER_TAGS"] {
            let tags = tagNames.components(separatedBy: ",")
            return filter { $0.containsTags(tags) }
        } else if let shouldRunWith = (Cucumber.shared as? StepImplementation)?.shouldRunWith,
            askImplementor {
            return filter { shouldRunWith($0 as? Scenario, $0.tags) }
        }
        return self
    }
}
