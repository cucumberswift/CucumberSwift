//
//  DSLScenarioOutline.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation

public struct ScenarioOutline: ScenarioDSL {
    public var scenarios: [Scenario] = []

    @discardableResult public init<T>(_ title: String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> [StepDSL],
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(with: steps($0),
                     title: title,
                     description: description,
                     tags: tags,
                     position: Lexer.Position(line: line, column: column))
        }
    }

    @discardableResult public init<T>(_ title: String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> StepDSL,
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(with: [steps($0)],
                     title: title,
                     description: description,
                     tags: tags,
                     position: Lexer.Position(line: line, column: column))
        }
    }

    @discardableResult public init<T>(_ title: (T) -> String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> [StepDSL],
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(with: steps($0),
                     title: title($0),
                     description: description,
                     tags: tags,
                     position: Lexer.Position(line: line, column: column))
        }
    }

    @discardableResult public init<T>(_ title: (T) -> String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> StepDSL,
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(with: [steps($0)],
                     title: title($0),
                     description: description,
                     tags: tags,
                     position: Lexer.Position(line: line, column: column))
        }
    }
}
