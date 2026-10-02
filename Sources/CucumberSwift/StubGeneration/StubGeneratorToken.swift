//
//  StubGeneratorToken.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 3/12/23.
//  Copyright © 2023 Tyler Thompson. All rights reserved.
//

import Foundation

extension StubGenerator {
    enum Token {
        case match(value: String)
        case string(value: String)
        case int(value: String)
        /// Only in Cucumber Expressions: the lexer reads `5.25` as `5`, `.` and `25`.
        case float(value: String)

        func isString() -> Bool {
            if case .string = self {
                return true
            }
            return false
        }

        func isInteger() -> Bool {
            if case .int = self {
                return true
            }
            return false
        }
    }
}
