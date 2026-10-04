//
//  StubGeneratorLexer.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 3/12/23.
//  Copyright © 2023 Tyler Thompson. All rights reserved.
//

import Foundation
extension StubGenerator {
    public class Lexer: StringReader {
        override internal init(_ str: String) {
            super.init(str)
        }

        @discardableResult private func advance<T>(_ t: @autoclosure () -> T) -> T {
            advanceIndex()
            return t()
        }

        internal func advanceToNextToken() -> Token? {
            guard let char = currentChar else { return nil }

            switch char {
                case .quote:
                    let str = advance(readUntil { $0.isQuote })
                    return advance(.string(value: str))
                case _ where char.isNumeric:
                    let allIntegerValues = readUntil { !$0.isNumeric }
                    return .int(value: allIntegerValues)
                default: return .match(value: readUntil { $0.isQuote || $0.isNumeric })
            }
        }

        internal func lex() -> [Token] {
            var toks = [Token]()
            while let tok = advanceToNextToken() {
                toks.append(tok)
            }
            return toks
        }
    }
}
