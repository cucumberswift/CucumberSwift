//
//  StepDSL+RegularExpression.swift
//  CucumberSwiftTesting
//
// CucumberSwift's step definitions with a regular expression in a string, whose closure takes the
// matches as a `[String]`. They are deprecated there too, in favour of regex literals.

import Foundation
import Testing

extension StepDSL {
    /// A step definition with a regular expression in a string, whose closure takes the whole match and
    /// then each capture group, as CucumberSwift's does. The expression matches anywhere in a step's text,
    /// without regard to case, unless you anchor it. A pattern that doesn't compile fails at this line.
    @_disfavoredOverload
    @available(*, deprecated, message: "To use regular expressions with CucumberSwift please migrate to use regex literals.")
    @discardableResult
    public convenience init(_ regex: String,
                            callback: @escaping @MainActor ([String], Step) async throws -> Void,
                            line: Int = #line,
                            file: StaticString = #file) {
        let expression: NSRegularExpression?
        do {
            expression = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
        } catch {
            Issue.record("Invalid regular expression '\(regex)': \(error.localizedDescription)",
                         sourceLocation: SourceLocation(fileID: "\(file)", filePath: "\(file)", line: line, column: 1))
            expression = nil
        }
        self.init(matching: { text in
            guard let expression, let result = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
            let groups = (0..<result.numberOfRanges).compactMap { index in
                Range(result.range(at: index), in: text).map { String(text[$0]) }
            }
            return { step in try await callback(groups, step) }
        }, line: line, file: file)
    }
}
