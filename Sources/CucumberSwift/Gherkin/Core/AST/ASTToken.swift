//
//  ASTToken.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 12/6/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
extension AST {
    enum Token: Hashable {
        case feature(Lexer.Token? = nil)
        case rule(Lexer.Token? = nil)
        case background(Lexer.Token? = nil)
        case scenario(Lexer.Token? = nil)
        case scenarioOutline(Lexer.Token? = nil)
        case examples(Lexer.Token? = nil)
        case step(Lexer.Token? = nil)
        case description(Lexer.Token? = nil)

        var priority: UInt {
            switch self {
                case .feature: return 0
                case .rule: return 1
                case .background: return 2
                case .scenario: return 2
                case .scenarioOutline: return 2
                case .examples: return 2
                case .step: return 3
                case .description: return 3
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            var lHasher = Hasher()
            lhs.hash(into: &lHasher)
            var rHasher = Hasher()
            rhs.hash(into: &rHasher)
            return lHasher.finalize() == rHasher.finalize()
        }

        func hash(into hasher: inout Hasher) {
            switch self {
                case .feature: hasher.combine(1)
                case .rule: hasher.combine(2)
                case .background: hasher.combine(3)
                case .scenario: hasher.combine(4)
                case .scenarioOutline: hasher.combine(5)
                case .examples: hasher.combine(6)
                case .step: hasher.combine(7)
                case .description: hasher.combine(8)
            }
        }

        var token: Lexer.Token? {
            switch self {
                case .feature(let token): return token
                case .rule(let token): return token
                case .background(let token): return token
                case .scenario(let token): return token
                case .scenarioOutline(let token): return token
                case .examples(let token): return token
                case .step(let token): return token
                case .description(let token): return token
            }
        }

        init?(_ token: Lexer.Token) {
            if case Lexer.Token.keyword = token {
                self = .step(token)
            } else if case Lexer.Token.scope(_, let scope) = token {
                switch scope {
                    case .feature: self = .feature(token)
                    case .rule: self = .rule(token)
                    case .background: self = .background(token)
                    case .scenario: self = .scenario(token)
                    case .scenarioOutline: self = .scenarioOutline(token)
                    case .examples: self = .examples(token)
                    default: return nil
                }
            } else if case Lexer.Token.description = token {
                self = .description(token)
            } else {
                return nil
            }
        }
    }
}
