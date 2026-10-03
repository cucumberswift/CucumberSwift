//
//  CharacterExtensions.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/15/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

extension CharacterSet {
    static let docStrings = CharacterSet(charactersIn: "\"`")
}

extension Character {
    static let tableHeaderOpen: Character = "<"
    static let tableHeaderClose: Character = ">"
    static let newLine: Character = "\n"
    static let scopeTerminator: Character = ":"
    static let quote: Character = "\""
    static let tagMarker: Character = "@"
    static let comment: Character = "#"
    static let tableCellDelimiter: Character = "|"
    static let decimal: Character = "."
    static let escapeCharacter: Character = "\\"

    var value: Int32 {
        Int32(scalar.value)
    }
    var scalar: UnicodeScalar! {
        String(self).unicodeScalars.first
    }
    var isSpace: Bool {
        isspace(value) != 0
    }
    var isAlphanumeric: Bool {
        isalnum(value) != 0
    }
    var isTagCharacter: Bool {
        !self.isSpace
            && !isComment
            && !isNewline
            && !isTagMarker
            && !isQuote
            && !isTableCellDelimiter
            && !isHeaderToken
    }
    var isNumeric: Bool {
        isnumber(value) != 0
    }
    var isDecimal: Bool {
        self == Character.decimal
    }
    var isSymbol: Bool {
        isComment ||
        isNewline ||
        isTagMarker ||
        isQuote ||
        isTableCellDelimiter ||
        isHeaderToken ||
        isEscapeCharacter
    }
    var isHeaderToken: Bool {
        isHeaderOpen || isHeaderClosed
    }
    var isHeaderOpen: Bool {
        self == Character.tableHeaderOpen
    }
    var isHeaderClosed: Bool {
        self == Character.tableHeaderClose
    }
    var isQuote: Bool {
        self == Character.quote
    }
    var isTagMarker: Bool {
        self == Character.tagMarker
    }
    var isComment: Bool {
        self == Character.comment
    }
    var isNewline: Bool {
        self == Character.newLine
    }
    var isScopeTerminator: Bool {
        self == Character.scopeTerminator
    }
    var isTableCellDelimiter: Bool {
        self == Character.tableCellDelimiter
    }
    var isEscapeCharacter: Bool {
        self == Character.escapeCharacter
    }
    var isDocStringLiteral: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return CharacterSet.docStrings.contains(scalar)
    }
}
