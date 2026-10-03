//
//  StringReader.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/5/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public class StringReader {
    let input: String
    public private(set) var index: String.Index
    public var position: Lexer.Position {
        Lexer.Position(line: line, column: column)
    }

    private var line: UInt = 1
    private var lastLinePosition: UInt = 0 {
        willSet {
            holdLinePosition = lastLinePosition
        }
    }
    private var holdLinePosition: UInt = 0
    private var column: UInt = 0

    init(_ str: String) {
        input = str
        index = input.startIndex
    }

    public var currentChar: Character? {
        (index < input.endIndex && index >= input.startIndex) ? input[index] : nil
    }

    public var nextChar: Character? {
        if let i = input.index(index, offsetBy: 1, limitedBy: input.endIndex) {
            guard i != input.endIndex else { return input.last }
            return input[i]
        }
        return nil
    }

    public var previousChar: Character? {
        if let i = input.index(index, offsetBy: -1, limitedBy: input.startIndex) {
            return input[i]
        }
        return nil
    }

    func advanceIndex() {
        column += 1
        _ = input.formIndex(&index, offsetBy: 1, limitedBy: input.endIndex)
        if index < input.endIndex && input[index].isNewline {
            line += 1
            column = 0
            lastLinePosition = holdLinePosition
        }
    }

    @discardableResult public func lookAheadUntil(_ evaluation: ((Character) -> Bool)) -> String {
        var str = ""
        var indexCopy = index
        let currentCharacter = {
            (indexCopy < self.input.endIndex && indexCopy >= self.input.startIndex) ? self.input[indexCopy] : nil
        }
        while let char = currentCharacter(), !evaluation(char) {
            str.append(char)
            _ = input.formIndex(&indexCopy, offsetBy: 1, limitedBy: input.endIndex)
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
}
