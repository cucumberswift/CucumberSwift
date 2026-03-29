//
//  FeatureDSL.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation
extension Feature {
    @MainActor
    @discardableResult public convenience init(_ title: String,
                                               tags: [String] = [],
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #file,
                                               @ScenarioBuilder _ content: () -> [ScenarioDSL]) {
        let all = content()
        self.init(with: all.flatMap { $0.scenarios },
                  title: title,
                  description: all.compactMap { ($0 as? Description)?.title }.joined(separator: "\n"),
                  tags: tags,
                  position: Lexer.Position(line: line, column: column),
                  file: file)
        Cucumber.shared.features.append(self)
    }
    @MainActor
    @discardableResult public convenience init(_ title: String,
                                               tags: [String] = [],
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #file,
                                               @ScenarioBuilder _ content: () -> ScenarioDSL) {
        self.init(with: content().scenarios, title: title, tags: tags, position: Lexer.Position(line: line, column: column), file: file)
        Cucumber.shared.features.append(self)
    }
}
