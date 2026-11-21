//
//  StepDSL+RegularExpression.swift
//  CucumberSwiftTesting
//
// CucumberSwift's step definitions with a regular expression in a string, whose closure takes the
// matches as a `[String]`. They are deprecated there too, in favour of regex literals.

import Foundation
import Testing

extension StepDSL {
    /// What is wrong with `pattern`, such as "expected ')'". `NSRegularExpression` only says that the value is
    /// invalid, so ask Swift's own parser where the platform has one, as CucumberSwift does.
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

    /// The whole match and then each capture group that took part in it, or `nil` if the text doesn't match.
    private static func groups(of expression: NSRegularExpression?, in text: String) -> [String]? {
        guard let expression, let result = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (0..<result.numberOfRanges).compactMap { index in
            Range(result.range(at: index), in: text).map { String(text[$0]) }
        }
    }

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
            let message = "Invalid regular expression '\(regex)': \(Self.reason(for: regex) ?? error.localizedDescription)"
            Cucumber.shared.invalidDefinitions.append(.init(message: message, file: "\(file)", line: line))
            expression = nil
        }
        let match: @MainActor (String) -> (@MainActor (Step) async throws -> Void)? = { text in
            guard let groups = Self.groups(of: expression, in: text) else { return nil }
            return { step in try await callback(groups, step) }
        }
        self.init(matching: match, line: line, file: file)
    }
}
