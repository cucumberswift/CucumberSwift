//
//  ScenarioDSL.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//
// swiftlint:disable file_types_order

import Foundation

public struct Description: ScenarioDSL {
    // intentionally blank because we do not want Descriptions to be counted as real scenarios
    public var scenarios: [Scenario] { [] }
    public var title: String
    public init(_ title: String) {
        self.title = title
    }
}

extension Scenario: ScenarioDSL {
    @objc public var scenarios: [Scenario] { [self] }
}

public protocol ScenarioDSL {
    var scenarios: [Scenario] { get }
}

extension Scenario {
    public convenience init(_ title: String,
                            description: String = "",
                            tags: [String] = [],
                            line: UInt = #line,
                            column: UInt = #column,
                            @StepBuilder _ content: () -> [StepDSL]) {
        self.init(with: content(),
                  title: title,
                  description: description,
                  tags: tags,
                  position: Lexer.Position(line: line, column: column))
    }
    public convenience init(_ title: String,
                            description: String = "",
                            tags: [String] = [],
                            line: UInt = #line,
                            column: UInt = #column,
                            @StepBuilder _ content: () -> StepDSL) {
        self.init(with: [content()],
                  title: title,
                  description: description,
                  tags: tags,
                  position: Lexer.Position(line: line, column: column))
    }
}
// swiftlint:enable file_types_order
