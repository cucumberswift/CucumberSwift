//
//  ExecuteFirstStep.swift
//  CucumberSwiftTesting
//
// CucumberSwift's `ExecuteFirstStep(keyword:matching:)`: from a step or a hook, run the step definition
// that matches some text.

import Foundation
import Testing

/// The scenario that is running, for ``ExecuteFirstStep(keyword:matching:line:file:)``. Task-local, so that
/// scenarios running side by side each see their own.
enum ScenarioContext {
    @TaskLocal static var gherkinScenario: GherkinScenario?
}

/// From inside a step or a hook, runs the first step definition that matches `matching` and waits for it.
///
/// With a `keyword`, only the step definitions that a step with that keyword would match are considered:
/// those for the keyword, and `MatchAll`. The step definition gets a `Step` with that text and keyword, in
/// the running scenario. A step that no step definition matches, or that more than one matches, or whose
/// step definition throws, fails at the line of the step or hook that called this, and the caller goes on.
///
/// CucumberSwift's synchronous `ExecuteFirstStep(matching:)` has no counterpart: this runner's steps are
/// all `async`, so `await` this one.
@available(*, deprecated, message: "Move the code both steps need into a function, and call it from each step definition, instead of running one step from another.")
@MainActor
public func ExecuteFirstStep(keyword: Step.Keyword? = nil, matching: String) async {
    await Cucumber.shared.executeFirstStep(keyword: keyword, matching: matching)
}

extension Cucumber {
    func executeFirstStep(keyword: Step.Keyword?, matching: String) async {
        let running = RunningLocation.shared.current
        guard let running, let gherkinScenario = ScenarioContext.gherkinScenario else {
            Issue.record("ExecuteFirstStep runs a step definition from inside a step or a hook, and nothing is running.")
            return
        }
        let matches = definitions.compactMap { definition -> (definition: Definition, body: @MainActor (Step) async throws -> Void)? in
            guard keyword.map({ $0.isSuperset(of: definition.keyword) }) ?? true, let body = definition.body(matching) else { return nil }
            return (definition, body)
        }
        guard let match = matches.first else {
            Issue.record(Comment(rawValue: "No CucumberSwift expression found that matches step '\(matching)'"), sourceLocation: running.location)
            return
        }
        guard matches.count == 1 else {
            Issue.record(Comment(rawValue: Self.ambiguousStepMessage(step: matching, definitions: matches.map(\.definition))),
                         sourceLocation: running.location)
            return
        }
        let scenario = Scenario(gherkinScenario, feature: Feature(gherkinScenario))
        let step = Step(GherkinStep(keyword: keyword ?? [],
                                    keywordName: "",
                                    text: matching,
                                    line: running.location.line,
                                    column: running.location.column,
                                    suggestion: ""),
                        in: scenario)
        do {
            try await runWithTimeout(record: running.record) { try await match.body(step) }
        } catch {
            Issue.record(Comment(rawValue: "ExecuteFirstStep threw error \"\(error)\""), sourceLocation: running.location)
        }
    }
}
