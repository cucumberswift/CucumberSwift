//
//  Token.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/15/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

extension Sequence where Element == Lexer.Token {
    func groupedByLine() -> [[Lexer.Token]] {
        var lines = [[Lexer.Token]]()
        var line = [Lexer.Token]()
        for token in self {
            if token.isNewline() && !line.isEmpty {
                lines.append(line)
                line.removeAll()
            } else if !token.isNewline() {
                line.append(token)
            }
        }
        if !line.isEmpty {
            lines.append(line)
        }
        return lines
    }
}

extension Lexer {
    indirect enum Token: Equatable, Hashable {
        case newLine(Lexer.Position)
        case docString(Lexer.Position, DocString)
        case match(Lexer.Position, String)
        case title(Lexer.Position, String)
        case description(Lexer.Position, String)
        case tag(Lexer.Position, String)
        case tableHeader(Lexer.Position, String)
        case tableCell(Lexer.Position, Token)
        case scope(Lexer.Position, Scope)
        case keyword(Lexer.Position, Step.Keyword)

        var position: Lexer.Position {
            switch self {
                case .newLine(let pos): return pos
                case .docString(let pos, _): return pos
                case .match(let pos, _): return pos
                case .title(let pos, _): return pos
                case .description(let pos, _): return pos
                case .tag(let pos, _): return pos
                case .tableHeader(let pos, _): return pos
                case .tableCell(let pos, _): return pos
                case .scope(let pos, _): return pos
                case .keyword(let pos, _): return pos
            }
        }

        static func == (lhs: Token, rhs: Token) -> Bool {
            switch (lhs, rhs) {
                case (.newLine, .newLine):
                    return true
                case let (.match(_, match1), .match(_, match2)):
                    return match1 == match2
                case let (.title(_, title1), .title(_, title2)):
                    return title1 == title2
                case let (.description(_, description1), .description(_, description2)):
                    return description1 == description2
                case let (.tag(_, tag1), .tag(_, tag2)):
                    return tag1 == tag2
                case let (.docString(_, string1), .docString(_, string2)):
                    return string1.literal == string2.literal
                case let (.tableHeader(_, tableHeader1), .tableHeader(_, tableHeader2)):
                    return tableHeader1 == tableHeader2
                case let (.tableCell(_, tableCell1), .tableCell(_, tableCell2)):
                    return tableCell1 == tableCell2
                default:
                    return false
            }
        }

        var valueDescription: String {
            switch self {
                case .newLine: return "\n"
                case .docString(_, let val): return "\(val)"
                case .match(_, let val): return "\(val)"
                case .title(_, let val): return "\(val)"
                case .description(_, let val): return "\(val)"
                case .tag(_, let val): return "\(val)"
                case .tableHeader(_, let val): return "\(val)"
                case .tableCell(_, let val): return val.valueDescription
                case .scope(_, let val): return "\(val)"
                case .keyword(_, let val): return "\(val)"
            }
        }

        func isNewline() -> Bool {
            if case .newLine = self {
                return true
            }
            return false
        }

        func isTableCell() -> Bool {
            if case .tableCell = self {
                return true
            }
            return false
        }
        func isKeyword() -> Bool {
            if case .keyword = self {
                return true
            }
            return false
        }
        func isDescription() -> Bool {
            if case .description = self {
                return true
            }
            return false
        }

        func isExampleScope() -> Bool {
            if case .scope(_, let scope) = self,
               scope == .examples {
                return true
            }
            return false
        }
    }
}
