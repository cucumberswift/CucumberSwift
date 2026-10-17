//
//  ClassNameString.swift
//  CucumberSwift
//
// A title as a Swift type name, which names the camel-case tests of both runners. This folder is compiled by
// CucumberSwift and, through symlinks, by CucumberSwiftGherkin and CucumberSwiftTesting.

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    func lowercasingFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }

    func tokenize(locale: CFLocale) -> [String] {
        let inputRange = CFRange(location: 0, length: count)
        let flag = UInt(kCFStringTokenizerUnitWord)
        let tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, self as CFString, inputRange, flag, locale)
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        var tokens = [String]()

        while !tokenType.isEmpty {
            let currentTokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let substring = self[index(startIndex, offsetBy: currentTokenRange.location)..<index(startIndex, offsetBy: currentTokenRange.location + currentTokenRange.length)]
            tokens.append(String(substring))
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }

        return tokens
    }

    func camelCasingString(locale: CFLocale = CFLocaleCopyCurrent()) -> String {
        var str = ""
        for (i, word) in tokenize(locale: locale).enumerated() {
            if i == 0 {
                str += word.lowercasingFirstLetter()
                continue
            }
            str += word.capitalizingFirstLetter()
        }
        return str
    }

    /// The text as a Swift type name, as CucumberSwift names the classes of the tests it generates:
    /// `Pay with a gift card` is `PayWithAGiftCard`.
    func toClassString() -> String {
        camelCasingString()
            .lazy
            .drop { !$0.isLetter }
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .map(String.init)
            .joined()
            .capitalizingFirstLetter()
    }
}
