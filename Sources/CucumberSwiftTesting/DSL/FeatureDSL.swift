//
//  FeatureDSL.swift
//  CucumberSwiftTesting
//
// swiftlint:disable file_types_order
// Features written in Swift rather than in feature files, named and shaped as in CucumberSwift's DSL:
//
//     Feature("Sign in") {
//         Background { #Given(I: openTheApp()) }
//         Scenario("A returning user") {
//             #Given(I: haveAnAccount())
//             #When(I: signIn)
//             #Then(the: settingsAreShown())
//         }
//     }
//
// Declare them in `setupSteps()`. Each `Feature` hands its scenarios to the runner, which the generated
// "Swift DSL features" test runs, as the tests of a feature file run its scenarios.

import Foundation

/// A part of a feature written in the Swift DSL: a `Scenario`, a `ScenarioOutline`, a `Rule`, a `Background`
/// or a `Description`.
public protocol ScenarioDSL {
    var scenarios: [Scenario] { get }
}

extension Scenario: ScenarioDSL {
    public var scenarios: [Scenario] { [self] }
}

/// The text under a feature's title, in the Swift DSL.
public struct Description: ScenarioDSL {
    // Not counted as a scenario.
    public var scenarios: [Scenario] { [] }
    public var title: String
    public init(_ title: String) {
        self.title = title
    }
}

/// Steps that run before each scenario of the feature or rule, in the Swift DSL.
public struct Background: ScenarioDSL {
    // Not counted as a scenario: its steps are put before each scenario's.
    public var scenarios: [Scenario] { [] }
    let steps: [DSLStep]

    @MainActor
    public init(@StepBuilder _ content: () -> [StepDSL]) {
        steps = Cucumber.shared.dsl.take(content())
    }
    @MainActor
    public init(@StepBuilder _ content: () -> StepDSL) {
        steps = Cucumber.shared.dsl.take([content()])
    }
}

/// A group of scenarios, in the Swift DSL. As in CucumberSwift, its scenarios belong to the feature, and have the
/// rule's tags before their own; its title and position are not used, as with a rule in a feature file.
public struct Rule: ScenarioDSL {
    public let scenarios: [Scenario]
    @MainActor
    public init(_: String,
                tags: [String] = [],
                line _: UInt = #line,
                column _: UInt = #column,
                @ScenarioBuilder _ content: () -> [ScenarioDSL]) {
        scenarios = content().flatMap(\.scenarios)
        scenarios.forEach { $0.tags = tags + $0.tags }
    }
    @MainActor
    public init(_: String,
                tags: [String] = [],
                line _: UInt = #line,
                column _: UInt = #column,
                @ScenarioBuilder _ content: () -> ScenarioDSL) {
        scenarios = content().scenarios
        scenarios.forEach { $0.tags = tags + $0.tags }
    }
}

/// A scenario for each of `examples`, in the Swift DSL: its steps and title are made from each example.
public struct ScenarioOutline: ScenarioDSL {
    public var scenarios: [Scenario] = []

    @MainActor
    @discardableResult public init<T>(_ title: String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers _: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> [StepDSL],
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(dsl: steps($0), title: title, description: description, tags: tags, line: line, column: column)
        }
    }

    @MainActor
    @discardableResult public init<T>(_ title: String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers _: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> StepDSL,
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(dsl: [steps($0)], title: title, description: description, tags: tags, line: line, column: column)
        }
    }

    @MainActor
    @discardableResult public init<T>(_ title: (T) -> String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers _: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> [StepDSL],
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(dsl: steps($0), title: title($0), description: description, tags: tags, line: line, column: column)
        }
    }

    @MainActor
    @discardableResult public init<T>(_ title: (T) -> String,
                                      tags: [String] = [],
                                      description: String = "",
                                      headers _: T.Type,
                                      line: UInt = #line,
                                      column: UInt = #column,
                                      @StepBuilder steps: (T) -> StepDSL,
                                      examples: () -> [T]) {
        scenarios = examples().map {
            Scenario(dsl: [steps($0)], title: title($0), description: description, tags: tags, line: line, column: column)
        }
    }
}

@resultBuilder
public enum StepBuilder {
    public static func buildBlock(_ items: StepDSL?...) -> [StepDSL] {
        items.compactMap { $0 }
    }
}

@resultBuilder
public enum ScenarioBuilder {
    /// The scenarios, each with the Backgrounds' steps first, then the descriptions, as in CucumberSwift.
    public static func buildBlock(_ items: ScenarioDSL...) -> [ScenarioDSL] {
        let backgroundSteps = items.compactMap { $0 as? Background }.flatMap(\.steps)
        let scenarioDSLs = items.filter { !($0 is Background) }
        let scenarios = scenarioDSLs.flatMap(\.scenarios)
        if !backgroundSteps.isEmpty {
            scenarios.forEach { $0.prependDSLSteps(backgroundSteps) }
        }
        return scenarios + scenarioDSLs.compactMap { $0 as? Description }
    }
}

extension Scenario {
    @MainActor
    public convenience init(_ title: String,
                            description: String = "",
                            tags: [String] = [],
                            line: UInt = #line,
                            column: UInt = #column,
                            @StepBuilder _ content: () -> [StepDSL]) {
        self.init(dsl: content(), title: title, description: description, tags: tags, line: line, column: column)
    }

    @MainActor
    public convenience init(_ title: String,
                            description: String = "",
                            tags: [String] = [],
                            line: UInt = #line,
                            column: UInt = #column,
                            @StepBuilder _ content: () -> StepDSL) {
        self.init(dsl: [content()], title: title, description: description, tags: tags, line: line, column: column)
    }

    /// A scenario of the Swift DSL, before its feature is known.
    @MainActor
    convenience init(dsl steps: [StepDSL], title: String, description: String, tags: [String], line: UInt, column: UInt) {
        let dslSteps = Cucumber.shared.dsl.take(steps)
        let gherkin = GherkinScenario(featureTitle: "",
                                      featureTags: [],
                                      title: title,
                                      tags: tags,
                                      file: dslSteps.first?.file ?? "",
                                      line: Int(line),
                                      column: Int(column),
                                      steps: DSLStep.gherkinSteps(dslSteps))
        self.init(gherkin)
        self.dslSteps = dslSteps
        dslDescription = description
    }
}

extension Feature {
    /// A feature written in Swift. Declare it in `setupSteps()`: the generated "Swift DSL features" test runs
    /// its scenarios.
    @MainActor
    @discardableResult public convenience init(_ title: String,
                                               tags: [String] = [],
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath,
                                               @ScenarioBuilder _ content: () -> [ScenarioDSL]) {
        let all = content()
        // As CucumberSwift's DSL names its feature: by the Swift file's path, which is also where issues are reported.
        self.init(title: title,
                  desc: all.compactMap { ($0 as? Description)?.title }.joined(separator: "\n"),
                  tags: tags,
                  uri: "\(file)",
                  sourcePath: "\(file)",
                  location: Location(line: Int(line), column: Int(column)))
        Cucumber.shared.addDSLFeature(self, scenarios: all.flatMap(\.scenarios))
    }

    @MainActor
    @discardableResult public convenience init(_ title: String,
                                               tags: [String] = [],
                                               line: UInt = #line,
                                               column: UInt = #column,
                                               file: StaticString = #filePath,
                                               @ScenarioBuilder _ content: () -> ScenarioDSL) {
        self.init(title: title, tags: tags, uri: "\(file)", sourcePath: "\(file)", location: Location(line: Int(line), column: Int(column)))
        Cucumber.shared.addDSLFeature(self, scenarios: content().scenarios)
    }
}

extension DSLStep {
    /// The steps as the runner sees them, with the keyword that an `And`, `But` or `MatchAll` step continues
    /// added, as CucumberSwift adds it.
    static func gherkinSteps(_ steps: [DSLStep]) -> [GherkinStep] {
        var previous: Step.Keyword?
        return steps.map { step in
            var keyword = step.keyword
            // As CucumberSwift's `continuedKeywords`: a `MatchAll` step's empty keyword counts as a primary one.
            if Step.Keyword.primaryKeywords.contains(keyword) {
                previous = keyword
            } else if let previous {
                keyword.formUnion(previous)
            }
            return GherkinStep(keyword: keyword,
                               keywordName: writtenName(of: step.keyword, continuing: keyword),
                               text: step.text,
                               line: step.line,
                               column: step.column,
                               suggestion: "")
        }
    }

    /// The keyword as CucumberSwift writes a DSL step's: `And` and `But` as themselves, and a `MatchAll` step
    /// as the keyword it continues.
    private static func writtenName(of written: Step.Keyword, continuing keyword: Step.Keyword) -> String {
        if written.contains(.and) { return "And" }
        if written.contains(.but) { return "But" }
        if keyword.contains(.given) { return "Given" }
        if keyword.contains(.when) { return "When" }
        if keyword.contains(.then) { return "Then" }
        return "*"
    }
}
// swiftlint:enable file_types_order
