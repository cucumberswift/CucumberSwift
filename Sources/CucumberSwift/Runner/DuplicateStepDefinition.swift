//
//  DuplicateStepDefinition.swift
//  CucumberSwift
//

import Foundation

/// Finds step definitions that repeat an earlier one: the same pattern, registered with keywords that can
/// match the same steps. Like cucumber-jvm's `DuplicateStepDefinitionException`, this is an error whether
/// or not a step uses the pattern. A step that two definitions match also fails as ambiguous when it runs.
enum DuplicateStepDefinition {
    private struct Registration {
        let pattern: String
        let keyword: Step.Keyword?
        let file: StaticString
        let line: Int
    }

    private static var registrations = [Registration]()
    /// One problem per duplicate, at the duplicate's own line. `testGherkin()` fails each one there.
    static var errors = [RegularExpression.Problem]()

    /// Records a step definition, and a problem if it repeats an earlier one.
    /// - Parameters:
    ///   - pattern: the regular expression the step definition matches with, as written or as generated
    ///     from its Cucumber expression. Regex literals cannot be compared, so they are not registered.
    ///   - keyword: the keyword it was registered with; `nil` for `MatchAll`.
    static func register(pattern: String, keyword: Step.Keyword?, file: StaticString, line: Int) {
        if let earlier = registrations.first(where: { $0.pattern == pattern && canCompete($0.keyword, keyword) }) {
            errors.append(.init(message: message(earlier: (earlier.file, earlier.line), duplicate: (file, line)),
                                file: String(file),
                                line: line))
        }
        registrations.append(.init(pattern: pattern, keyword: keyword, file: file, line: line))
    }

    static func reset() {
        registrations.removeAll()
        errors.removeAll()
    }

    /// Whether step definitions registered with these keywords can match the same step. `MatchAll` matches
    /// every step. An `And` or `But` step takes the keyword of the step before it, so `And` and `But`
    /// definitions compete with `Given`, `When` and `Then`, but not with each other, and two different
    /// primary keywords never compete.
    static func canCompete(_ lhs: Step.Keyword?, _ rhs: Step.Keyword?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else { return true }
        let conjunctions: Step.Keyword = [.and, .but]
        return lhs == rhs || conjunctions.contains(lhs) != conjunctions.contains(rhs)
    }

    private static func message(earlier: (file: StaticString, line: Int), duplicate: (file: StaticString, line: Int)) -> String {
        func location(_ file: StaticString, _ line: Int) -> String {
            "\(URL(fileURLWithPath: String(file)).lastPathComponent):\(line)"
        }
        return "Duplicate step definitions at \(location(earlier.file, earlier.line)) and \(location(duplicate.file, duplicate.line)): they have the same pattern and can match the same steps. Remove one of them." // swiftlint:disable:this line_length
    }
}
