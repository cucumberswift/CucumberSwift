//
//  ScenarioDSL.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation

public extension Scenario {
    convenience init(_ title:String, tags:[String] = [],
                     line:UInt = #line, column:UInt = #column,
                     @StepBuilder _ content: () -> [DSLStep]) {
        self.init(with: content(), title: title, tags: tags, position: Lexer.Position(line: line, column: column))
    }
    convenience init(_ title:String, tags:[String] = [],
                     line:UInt = #line, column:UInt = #column,
                     @StepBuilder _ content: () -> DSLStep) {
        self.init(with: [content()], title: title, tags: tags, position: Lexer.Position(line: line, column: column))
    }
}

public class Description: ScenarioDSL {
    public var scenarios: [Scenario] { [] }
    public init(_ title:String) { }
}

extension Scenario: ScenarioDSL {
    @objc public var scenarios: [Scenario] { [self] }
}

public protocol ScenarioDSL {
    var scenarios:[Scenario] { get }
}
