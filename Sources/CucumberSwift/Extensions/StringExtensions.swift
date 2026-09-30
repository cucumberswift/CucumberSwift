//
//  StringExtensions.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
/// Regular expressions that would not compile. They come from a step definition's pattern or from
/// `CUCUMBER_TAGS`, not from a .feature file, so `CucumberTest.testGherkin()` reports them apart
/// from `Gherkin.errors`.
enum RegularExpression {
    struct Problem: Equatable {
        let message: String
        /// Where the pattern was written, when it came from a step definition. `testGherkin()`
        /// reports the problem there, so Xcode marks the consumer's own line.
        let file: String?
        let line: Int?
    }

    static var errors = [Problem]()

    /// Records `pattern` with the step definition's location if it will not compile.
    /// - Returns: whether it compiles, so a caller can skip a pattern that never can match.
    static func validate(_ pattern: String, file: StaticString, line: Int) -> Bool {
        do {
            _ = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            return true
        } catch {
            errors.append(Problem(message: message(for: pattern, error), file: String(file), line: line))
            return false
        }
    }

    static func message(for pattern: String, _ error: Error) -> String {
        "Invalid regular expression '\(pattern)': \(reason(for: pattern) ?? error.localizedDescription)"
    }

    /// What is wrong with `pattern`, such as "expected ')'". `NSRegularExpression` only says that the
    /// value is invalid, so ask Swift's own parser where the platform has one.
    private static func reason(for pattern: String) -> String? {
#if compiler(>=5.7) && canImport(_StringProcessing)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            do {
                _ = try Regex(pattern)
            } catch {
                return "\(error)"
            }
        }
#endif
        return nil
    }
}

extension String {
    init(_ staticString: StaticString) {
        self = staticString.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let results = regex.matches(in: self,
                                        range: NSRange(startIndex..., in: self))
            guard let firstResult = results.first else { return [] }
            var matches = [String]()
            for i in 0..<firstResult.numberOfRanges {
                if let range = Range(firstResult.range(at: i), in: self) {
                    matches.append(String(self[range]))
                }
            }
            return matches
        } catch let error {
            // A pattern that will not compile is a programming error, not a non-match. Surface it
            // the way every other setup problem is - `CucumberTest.testGherkin()` turns
            // `RegularExpression.errors` into an XCTFail - rather than printing into console noise
            // nobody reads.
            // A tag filter is matched against every feature and scenario, so record each pattern once.
            let problem = RegularExpression.Problem(message: RegularExpression.message(for: regex, error), file: nil, line: nil)
            if !RegularExpression.errors.contains(problem) {
                RegularExpression.errors.append(problem)
            }
            return []
        }
    }

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

    func isDocStringLiteral() -> Bool {
        guard count == 3 else { return false }
        return !compactMap { $0.unicodeScalars.first }
                .contains { !CharacterSet.docStrings.contains($0) }
    }
}
