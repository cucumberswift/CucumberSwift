//
//  Taggable.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 5/13/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation



@MainActor

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
    @MainActor
    func taggedElements(with environment: [String: String] = ProcessInfo.processInfo.environment, askImplementor: Bool) -> [Element] {
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
