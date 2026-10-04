//
//  StepDSL.swift
//  CucumberSwiftTesting
//
// The step definition DSL, named and shaped as in CucumberSwift: `Given("…") { match, step in }`. The
// step definition macros expand to it too.

@_exported import CucumberSwiftExpressions
import Foundation

/// Where step definitions are registered: `extension Cucumber: StepImplementation`, as in CucumberSwift.
/// There is no `bundle`: the build tool plugin reads the feature files when the tests build.
@MainActor
public protocol StepImplementation {
    func setupSteps()
}

public final class GivenStep: StepDSL { override static var keyword: Step.Keyword { .given } }
public final class WhenStep: StepDSL { override static var keyword: Step.Keyword { .when } }
public final class ThenStep: StepDSL { override static var keyword: Step.Keyword { .then } }
/// Matches the steps written with `And`, whichever keyword they continue.
public final class AndStep: StepDSL { override static var keyword: Step.Keyword { .and } }
/// Matches the steps written with `But`, whichever keyword they continue.
public final class ButStep: StepDSL { override static var keyword: Step.Keyword { .but } }
/// Matches a step with any keyword.
public final class MatchAllStep: StepDSL {}

public typealias Given = GivenStep
public typealias When = WhenStep
public typealias Then = ThenStep
public typealias And = AndStep
public typealias But = ButStep
public typealias MatchAll = MatchAllStep

/// A step definition. Create one with `Given`, `When`, `Then`, `And`, `But` or `MatchAll`.
@MainActor
public class StepDSL {
    /// The keyword a step needs for this step definition to match it. Empty for `MatchAll`.
    class var keyword: Step.Keyword { [] }

    /// A step definition with a Cucumber Expression, or with a regular expression if the string starts
    /// with `^` or ends with `$`. A closure runs on the main actor, and the next step starts only once
    /// it has finished.
    @discardableResult
    public init(_ expression: CucumberExpression,
                callback: @escaping @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void,
                line: Int = #line,
                file: StaticString = #file) {
        Cucumber.shared.register(keyword: Self.keyword, file: file, line: line) { text in
            guard let match = expression.match(in: text) else { return nil }
            return { step in try await callback(match, step) }
        }
    }

    /// A step definition with a regex literal, such as `#/^I have (\d+) cukes$/#`. It matches a step
    /// whose whole text it matches.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @discardableResult
    public init<Output>(_ regex: Regex<Output>,
                        callback: @escaping @MainActor (Regex<Output>.Match, Step) async throws -> Void,
                        line: Int = #line,
                        file: StaticString = #file) {
        Cucumber.shared.register(keyword: Self.keyword, file: file, line: line) { text in
            guard let match = try? regex.wholeMatch(in: text) else { return nil }
            return { step in try await callback(match, step) }
        }
    }
}
