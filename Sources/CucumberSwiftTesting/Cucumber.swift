//
//  Cucumber.swift
//  CucumberSwiftTesting
//

import Foundation
import Testing

/// Holds the step definitions and hooks, and runs the scenarios the generated tests pass it.
@MainActor
public final class Cucumber {
    struct Definition {
        let keyword: Step.Keyword
        let file: String
        let line: Int
        /// The step definition's body for a step with this text, or `nil` if it doesn't match.
        let body: @MainActor (String) -> (@MainActor (Step) async throws -> Void)?
    }

    public static let shared = Cucumber()

    var definitions = [Definition]()
    var beforeScenarioHooks = [Hook<Scenario>]()
    var afterScenarioHooks = [Hook<Scenario>]()
    var beforeStepHooks = [Hook<Step>]()
    var afterStepHooks = [Hook<Step>]()
    private var isSetUp = false

    private init() {}

    /// CucumberSwift's message for a step that no step definition matches.
    static func missingStepDefinitionMessage(suggestion: String) -> String {
        "No CucumberSwift expression found that matches this step. Try adding the following Swift code to your step implementation file: \n\(suggestion)"
    }

    /// CucumberSwift's message for a step that more than one step definition matches.
    static func ambiguousStepMessage(step: String, definitions: [Definition]) -> String {
        let locations = definitions.map { "\(URL(fileURLWithPath: $0.file).lastPathComponent):\($0.line)" }
        let list = locations.count < 2 ? locations.joined() : locations.dropLast().joined(separator: ", ") + " and " + (locations.last ?? "")
        return "Ambiguous step '\(step)': it matches \(locations.count) step definitions, at \(list). Remove all but one of them, or make their patterns more specific." // swiftlint:disable:this line_length
    }

    private static func sourceLocation(_ file: String, _ location: Location) -> SourceLocation {
        let name = URL(fileURLWithPath: file).lastPathComponent
        return SourceLocation(fileID: "Features/\(name)", filePath: file, line: max(location.line, 1), column: max(location.column, 1))
    }

    func register(
        keyword: Step.Keyword,
        file: StaticString,
        line: Int,
        body: @escaping @MainActor (String) -> (@MainActor (Step) async throws -> Void)?
    ) {
        definitions.append(Definition(keyword: keyword, file: "\(file)", line: line, body: body))
    }

    /// Runs a scenario's steps in order, between its hooks. A step that no step definition matches, that
    /// more than one matches, or whose step definition throws, fails at its line in the feature file, and
    /// the scenario's later steps don't run. A failed `#expect` fails where it is written, and the
    /// scenario goes on, as a failed XCTest assertion does with CucumberSwift.
    public func run(_ gherkinScenario: GherkinScenario) async {
        let scenario = Scenario(gherkinScenario)
        let file = gherkinScenario.file
        setUpIfNeeded(at: Self.sourceLocation(file, scenario.location))
        if await runHooks(beforeScenarioHooks, with: scenario, at: scenario.location, in: file) {
            for step in scenario.steps {
                guard await run(step, in: file) else { break }
            }
        }
        await runHooks(afterScenarioHooks, with: scenario, at: scenario.location, in: file)
        RunningLocation.shared.current = nil
    }

    /// Calls `setupSteps()` once, before the first scenario. Without step definitions, fails at the first
    /// scenario in its feature file.
    private func setUpIfNeeded(at location: SourceLocation) {
        guard !isSetUp else { return }
        isSetUp = true
        guard let implementation = self as Any as? StepImplementation else {
            Issue.record("No step definitions: add `extension Cucumber: StepImplementation` with a `setupSteps()` to the test target.",
                         sourceLocation: location)
            return
        }
        implementation.setupSteps()
    }

    /// Runs one step. Returns whether the scenario can go on.
    private func run(_ step: Step, in file: String) async -> Bool {
        let location = Self.sourceLocation(file, step.location)
        let matches = definitions.compactMap { definition -> (definition: Definition, body: @MainActor (Step) async throws -> Void)? in
            guard step.keyword.isSuperset(of: definition.keyword), let body = definition.body(step.match) else { return nil }
            return (definition, body)
        }
        guard let match = matches.first else {
            Issue.record(Comment(rawValue: Self.missingStepDefinitionMessage(suggestion: step.suggestion)), sourceLocation: location)
            return false
        }
        guard matches.count == 1 else {
            let message = Self.ambiguousStepMessage(step: "\(step.keywordName) \(step.match)", definitions: matches.map(\.definition))
            Issue.record(Comment(rawValue: message), sourceLocation: location)
            return false
        }
        guard await runHooks(beforeStepHooks, with: step, at: step.location, in: file) else { return false }
        var passed = true
        RunningLocation.shared.current = location
        do {
            try await match.body(step)
        } catch {
            Issue.record(error, Comment(rawValue: "\(step.keywordName) \(step.match)"), sourceLocation: location)
            passed = false
        }
        let afterHooksPassed = await runHooks(afterStepHooks, with: step, at: step.location, in: file)
        return passed && afterHooksPassed
    }

    /// Runs each hook in order. Returns whether none threw.
    @discardableResult
    private func runHooks<Argument>(
        _ hooks: [Hook<Argument>],
        with argument: Argument,
        at location: Location,
        in file: String
    ) async -> Bool {
        for hook in hooks.inPriorityOrder() {
            RunningLocation.shared.current = Self.sourceLocation(file, location)
            do {
                try await hook.body(argument)
            } catch {
                Issue.record(error, sourceLocation: Self.sourceLocation(file, location))
                return false
            }
        }
        return true
    }
}
