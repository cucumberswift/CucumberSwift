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
    /// Whether the runner prints each feature, scenario and step, with its result and duration, as it
    /// runs. Defaults to `false`. Setting the `CUCUMBER_VERBOSE` environment variable to `1` or `true`
    /// turns it on without a code change.
    var verbose: Bool { get }
    /// What happens after an assertion fails in a step: whether an `async` step's task goes on running
    /// (`true`, the default) or is cancelled at the first failure. A synchronous step can't be stopped
    /// part way, because Swift Testing's `#expect` doesn't throw. Either way, once a step has failed
    /// the rest of its scenario's steps don't run.
    var continueTestingAfterFailure: Bool { get }
    /// Whether the `AfterScenario` and `AfterStep` hooks run in the reverse of the order that
    /// `BeforeScenario` and `BeforeStep` hooks do. Defaults to `false`.
    var reverseOrderForAfterHooks: Bool { get }
    /// How many seconds a step or a hook may run before it fails. Defaults to 60.
    var asyncStepTimeout: TimeInterval { get }
    /// How the step definitions the runner suggests for undefined steps write their regex literals, when
    /// ``Cucumber/generateRegexLiterals`` asks for regex literals rather than Cucumber Expressions. The
    /// default, ``RegexLiteralStyle/extendedDelimiter``, compiles in any test target.
    var regexLiteralStyle: RegexLiteralStyle { get }
    func setupSteps()
    /// Whether a scenario runs, asked once for each scenario or example, as it is about to run. Defaults
    /// to `true`. `CUCUMBER_TAGS` takes over when it is set, and the runner then doesn't ask. A scenario that
    /// this leaves out is reported as skipped, and an example of a Scenario Outline is not run as a test
    /// case. It is asked after `setupSteps()`.
    func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool
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

    /// The step, when this is a step of a feature written in the Swift DSL, such as `Given(I: logIn())`, rather
    /// than a step definition.
    var dslStep: DSLStep?
    /// Where this step definition is written, when it is one, so that one written among a scenario's steps is
    /// reported there.
    var definitionSite: (file: String, line: Int)?

    /// A step of a feature written in the Swift DSL. It registers no step definition: the runner runs `body`.
    init(dslText text: String?, line: UInt, column: UInt, file: StaticString, body: @escaping @MainActor () async throws -> Void) {
        dslStep = DSLStep(keyword: Self.keyword, text: text ?? "", line: Int(line), column: Int(column), file: "\(file)", body: body)
        // Reported when the suite ends unless a scenario takes it.
        Cucumber.shared.dsl.unplacedSteps[ObjectIdentifier(self)] = self
    }

    /// Registers a step definition that decides for itself whether a step's text matches. The initializers
    /// that take an expression, a regex literal or a regular expression string all end here.
    init(matching match: @escaping @MainActor (String) -> (@MainActor (Step) async throws -> Void)?,
         line: Int,
         file: StaticString) {
        definitionSite = ("\(file)", line)
        Cucumber.shared.register(keyword: Self.keyword, file: file, line: line, body: match)
    }

    /// A step definition with a Cucumber Expression, or with a regular expression if the string starts
    /// with `^` or ends with `$`. A closure runs on the main actor, and the next step starts only once
    /// it has finished.
    @discardableResult
    public init(_ expression: CucumberExpression,
                callback: @escaping @MainActor (CucumberSwiftExpressions.Match, Step) async throws -> Void,
                line: Int = #line,
                file: StaticString = #file) {
        definitionSite = ("\(file)", line)
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
        definitionSite = ("\(file)", line)
        Cucumber.shared.register(keyword: Self.keyword, file: file, line: line) { text in
            guard let match = try? regex.wholeMatch(in: text) else { return nil }
            return { step in try await callback(match, step) }
        }
    }
}

extension StepImplementation {
    public var verbose: Bool { false }
    public var continueTestingAfterFailure: Bool { true }
    public var reverseOrderForAfterHooks: Bool { false }
    public var asyncStepTimeout: TimeInterval { 60 }
    public var regexLiteralStyle: RegexLiteralStyle { .extendedDelimiter }
    public func shouldRunWith(scenario _: Scenario?, tags _: [String]) -> Bool { true }
}
