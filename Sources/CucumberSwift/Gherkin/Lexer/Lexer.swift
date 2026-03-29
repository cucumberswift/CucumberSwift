//
//  Lexer.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/15/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

@MainActor
public class Lexer: NSObject {
    private let url: URL?
    private let string: String
    private var line: UInt = 1
    private var column: UInt = 1
    private var index: String.Index
    private var atLineStart = true
    private var lastScope: Scope?
    private var lastKeyword: Step.Keyword?

    private var currentChar: Character? {
        guard index < string.endIndex else { return nil }
        return string[index]
    }

    private var nextChar: Character? {
        let nextIndex = string.index(after: index)
        guard nextIndex < string.endIndex else { return nil }
        return string[nextIndex]
    }

    private var previousChar: Character? {
        let prevIndex = string.index(before: index)
        guard prevIndex >= string.startIndex else { return nil }
        return string[prevIndex]
    }

    public init(_ string: String, uri: String = "") {
        self.string = string
        self.url = URL(string: uri)
        self.index = string.startIndex
    }

    private func advanceIndex() {
        guard index < string.endIndex else { return }
        if currentChar == .newLine {
            line += 1
            column = 1
        } else {
            column += 1
        }
        index = string.index(after: index)
    }

    public var position: Position {
        Position(line: line, column: column, uri: url)
    }

    @discardableResult public func lookAheadUntil(_ evaluation: ((Character) -> Bool)) -> String {
        var str = ""
        var indexCopy = index
        let currentCharacter = {
            (indexCopy < self.string.endIndex && indexCopy >= self.string.startIndex) ? self.string[indexCopy] : nil
        }
        while let char = currentCharacter(), !evaluation(char) {
            str.append(char)
            _ = string.formIndex(&indexCopy, offsetBy: 1, limitedBy: string.endIndex)
        }
        return str
    }

    @discardableResult public func readUntil(_ evaluation: ((Character) -> Bool)) -> String {
        var str = ""
        while let char = currentChar, !evaluation(char) {
            str.append(char)
            advanceIndex()
        }
        return str
    }

    @discardableResult internal func readLineUntil(_ evaluation: ((Character) -> Bool)) -> String {
        readUntil { $0.isNewline || evaluation($0) }
    }

    @discardableResult internal func lookAheadAtLineUntil(_ evaluation: ((Character) -> Bool)) -> String {
        lookAheadUntil { $0.isNewline || evaluation($0) }
    }

    // table cells have weird rules I don't necessarily agree with...
    @discardableResult internal func readCell() -> Token {
        var str = ""
        var isTableHeader = false
        var tableHeaderClosed = false
        while let char = currentChar, !char.isNewline {
            if char.isEscapeCharacter,
               let next = nextChar,
               next.isTableCellDelimiter || next == "n" || next.isEscapeCharacter || next == .tableHeaderOpen || next == .tableHeaderClose {
                if next == "n" {
                    str.append("\n")
                } else {
                    str.append(next)
                }
                advanceIndex()
                advanceIndex()
                continue
            }
            if char == .tableHeaderOpen {
                isTableHeader = true
            }
            if char == .tableHeaderClose {
                tableHeaderClosed = true
            }
            if char.isTableCellDelimiter {
                if isTableHeader && !tableHeaderClosed {
                    isTableHeader = false
                }
                break
            }
            str.append(char)
            advanceIndex()
        }
        if isTableHeader {
            return .tableHeader(position, String(str.trimmingCharacters(in: .whitespaces).dropFirst().dropLast().trimmingCharacters(in: .whitespaces)))
        } else {
            return .match(position, str.trimmingCharacters(in: .whitespaces))
        }
    }

    @discardableResult internal func readDocString(
        _ evaluation: ((Character) -> Bool)
    ) -> (docString: String, rawDocString: String) {
        var str = ""
        var rawStr = ""
        while let char = currentChar {
            if char.isEscapeCharacter,
               let next = nextChar,
               next.isDocStringLiteral {
                str.append(next)
                rawStr.append(char)
                rawStr.append(next)
                advanceIndex()
                advanceIndex()
                continue
            }
            if evaluation(char) {
                break
            }
            str.append(char)
            rawStr.append(char)
            advanceIndex()
        }
        return (str, rawStr)
    }

    @discardableResult internal func stripSpaceIfNecessary() -> Bool {
        if let c = currentChar, c.isSpace {
            readLineUntil { !$0.isSpace }
            return true
        }
        return false
    }

    @discardableResult private func advance<T>(_ t: @autoclosure () -> T) -> T {
        advanceIndex()
        return t()
    }

    internal func advanceToNextToken() -> Token? {
        guard let char = currentChar else { return nil }
        defer {
            if char.isNewline {
                atLineStart = true
                lastScope = nil
                lastKeyword = nil
            } else if char.isSymbol && previousChar?.isNewline != true {
                atLineStart = false
            }
        }

        switch char {
            case .newLine: return advance(.newLine(position))
            case .comment: return readComment()
            case .tagMarker: return advance(.tag(position, readLineUntil({ !$0.isTagCharacter })))
            case .tableCellDelimiter:
                let tableCellContents = advance(readCell())
                if currentChar != Character.tableCellDelimiter {
                    return advanceToNextToken()
                }
                return .tableCell(position, tableCellContents)
            case .tableHeaderOpen:
                let str = advance(readLineUntil { $0.isHeaderClosed })
                return advance(.tableHeader(position, str))
            case _ where atLineStart: return readScope()
            case _ where lastScope != nil:
                let title = readLineUntil { $0.isHeaderOpen }
                if title.isEmpty { // hack to get around potential infinite loop
                    return advance(advanceToNextToken())
                }
                return .title(position, title)
            case .quote: return readString()
            case _ where char.isEscapeCharacter:
                if nextChar == .comment {
                    return advance(advance(.match(position, "\(Character.comment)")))
                } else {
                    return advance(.match(position, "\(char)" + readLineUntil { $0.isSymbol }))
                }
            case _ where lastKeyword != nil: return .match(position, readLineUntil { $0.isSymbol })
            default: return advance(advanceToNextToken())
        }
    }

    private func readString() -> Token? {
        guard let char = currentChar,
              char.isDocStringLiteral else { return nil }
        let position = self.position
        let open = lookAheadAtLineUntil { !$0.isDocStringLiteral }
        if open.isDocStringLiteral() {
            readLineUntil { !$0.isDocStringLiteral }

            let (docString, rawDocString) = readDocString {
                if $0.isDocStringLiteral {
                    let close = lookAheadAtLineUntil { !$0.isDocStringLiteral }
                    if close == open { return true }
                }
                return false
            }

            let docStringValues = docString.components(separatedBy: "\n")
            .enumerated()
            .reduce(into: (whitespaceCount: 0, trimmedLines: [String]())) { res, e in
                let (offset, line) = e
                if offset == 1 {
                    res.whitespaceCount ?= line.map { $0 }.firstIndex { !$0.isWhitespace }
                }
                let str = line.map { $0 }.dropFirst(upTo: res.whitespaceCount) {
                    $0.isWhitespace
                }
                res.trimmedLines.append(String(str))
            }
            .trimmedLines
            .dropLast { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            readLineUntil { !$0.isDocStringLiteral }
            return advance(.docString(
                position,
                DocString(
                    rawLiteral: rawDocString,
                    literal: docStringValues.dropFirst().joined(separator: "\n"),
                    contentType: docStringValues.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            ))
        } else if char == .quote {
            return advance(.match(position, "\(Character.quote)"))
        }
        return nil
    }

    private func readComment() -> Token? {
        let str = advance(readLineUntil { _ in false })
        let matches = str.matches(for: "^(?:\\s*)language(?:\\s*):(?:\\s*)(.*?)(?:\\s*)$")
        if !matches.isEmpty {
            if let language = Language(matches[1]) {
                Scope.language = language
            } else {
                Gherkin.errors.append("File: \(url?.lastPathComponent ?? "") declares an unsupported language")
            }
        }
        return advance(advanceToNextToken())
    }

    // Feature, Scenario, Step etc...
    private func readScope() -> Token? {
        if stripSpaceIfNecessary() {
            return advanceToNextToken()
        }
        if let stringToken = readString() {
            return stringToken
        }
        atLineStart = false
        let position = self.position
        let scope = Scope.scopeFor(str: lookAheadAtLineUntil { $0.isScopeTerminator })
        if scope != .unknown && !scope.isStep() {
            lastScope = scope
            readUntil { $0.isScopeTerminator }
            advance(stripSpaceIfNecessary())
            return .scope(position, scope)
        } else if case .step(let keyword) = scope {
            readLineUntil { $0.isSpace }
            lastKeyword = keyword
            stripSpaceIfNecessary()
            return .keyword(position, keyword)
        } else {
            return .description(position, readLineUntil { $0.isNewline }.trimmingCharacters(in: .whitespaces))
        }
    }

    internal func lex() -> [Token] {
        Scope.language = Language.default
        var toks = [Token]()
        while let tok = advanceToNextToken() {
            toks.append(tok)
        }
        if (!toks.contains(where: { !$0.isDescription() && !$0.isNewline() })) {
            Gherkin.errors.append("File: \(url?.lastPathComponent ?? "") does not contain any valid gherkin")
        }
        return toks
    }
}
