@testable import CucumberSwiftTesting
import Foundation
import Testing

// In an extension of CucumberTests, so that they run one at a time with the other tests of the runner,
// which they share.
extension CucumberTests {
    func scenario(_ title: String, feature: String = "F", line: Int, steps: [GherkinStep]) -> GherkinScenario {
        GherkinScenario(
            featureTitle: feature,
            featureTags: ["f"],
            featureLine: 1,
            title: title,
            tags: ["f"],
            file: "/Features/\(feature).feature",
            line: line,
            column: 3,
            steps: steps)
    }

    /// Runs scenarios as Swift Testing runs a generated feature suite: inside its feature trait.
    func runFeature(_ title: String = "F", _ body: @escaping @MainActor @Sendable () async -> Void) async throws {
        let trait = CucumberFeatureTrait(file: "/Features/\(title).feature", title: title, line: 1)
        // swiftlint:disable:next force_unwrapping
        try await trait.provideScope(for: Test.current!, testCase: nil) { await body() }
    }

    @Test func featureHooksRunOnceAroundTheFeaturesScenariosAndInPriorityOrder() async throws {
        Given("a step") { [self] _, step in ran.append("step \(step.scenario?.title ?? "")") }
        BeforeFeature { [self] feature in ran.append("before feature \(feature.title)") }
        BeforeFeature(priority: 1) { [self] _ in ran.append("before feature first") }
        AfterFeature { [self] feature in ran.append("after feature \(feature.title)") }
        BeforeScenario { [self] scenario in ran.append("before \(scenario.title)") }

        try await runFeature {
            await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            await Cucumber.shared.run(self.scenario("B", line: 4, steps: [self.step(.given, "a step", line: 5)]))
        }
        #expect(ran == [
            "before feature first", "before feature F",
            "before A", "step A",
            "before B", "step B",
            "after feature F"
        ])
    }

    @Test func featureHooksRunOnceWhenTheFeaturesScenariosRunInParallel() async throws {
        Given("a slow step") { [self] _, step in
            ran.append("start \(step.scenario?.title ?? "")")
            await Task.yield()
            ran.append("end \(step.scenario?.title ?? "")")
        }
        BeforeFeature { [self] _ in
            ran.append("before feature")
            // Gives the other scenarios a chance to start while the hook runs: they wait for it.
            await Task.yield()
            await Task.yield()
            ran.append("before feature done")
        }
        AfterFeature { [self] _ in ran.append("after feature") }

        try await runFeature {
            await withTaskGroup(of: Void.self) { group in
                for (index, title) in ["A", "B", "C"].enumerated() {
                    let scenario = self.scenario(title, line: 2 + index * 2, steps: [self.step(.given, "a slow step", line: 3 + index * 2)])
                    group.addTask { await Cucumber.shared.run(scenario) }
                }
            }
        }
        #expect(ran.filter { $0 == "before feature" }.count == 1)
        #expect(ran.filter { $0 == "after feature" }.count == 1)
        #expect(ran.firstIndex(of: "before feature done") == 1)
        #expect(ran.last == "after feature")
        #expect(ran.filter { $0.hasPrefix("end ") }.count == 3)
    }

    @Test func eachFeatureRunsItsOwnHooks() async throws {
        Given("a step") { _, _ in }
        BeforeFeature { [self] feature in ran.append("before \(feature.title)") }
        AfterFeature { [self] feature in ran.append("after \(feature.title)") }

        try await runFeature("F") {
            await Cucumber.shared.run(self.scenario("A", feature: "F", line: 2, steps: [self.step(.given, "a step", line: 3)]))
        }
        try await runFeature("G") {
            await Cucumber.shared.run(self.scenario("B", feature: "G", line: 2, steps: [self.step(.given, "a step", line: 3)]))
        }
        #expect(ran == ["before F", "after F", "before G", "after G"])
    }

    @Test func withoutASuiteAFeatureEndsWhenTheNextOneStarts() async {
        Given("a step") { _, _ in }
        BeforeFeature { [self] feature in ran.append("before \(feature.title)") }
        AfterFeature { [self] feature in ran.append("after \(feature.title)") }

        await Cucumber.shared.run(scenario("A", feature: "F", line: 2, steps: [step(.given, "a step", line: 3)]))
        await Cucumber.shared.run(scenario("B", feature: "G", line: 2, steps: [step(.given, "a step", line: 3)]))
        #expect(ran == ["before F", "after F", "before G"])
    }

    /// Features run at the same time, so with the suite started a feature ends after its last scenario, or
    /// with the suite, not where another feature starts.
    @Test func withTheSuiteButNotTheFeatureTraitFeaturesEndWhenTheSuiteEnds() async {
        Given("a step") { _, _ in }
        BeforeFeature { [self] feature in ran.append("before \(feature.title)") }
        AfterFeature { [self] feature in ran.append("after \(feature.title)") }

        Cucumber.shared.beginSuite()
        await Cucumber.shared.run(scenario("A", feature: "F", line: 2, steps: [step(.given, "a step", line: 3)]))
        await Cucumber.shared.run(scenario("B", feature: "G", line: 2, steps: [step(.given, "a step", line: 3)]))
        await Cucumber.shared.endSuite()
        #expect(ran == ["before F", "before G", "after F", "after G"])
    }

    @Test func aThrowingBeforeFeatureHookFailsOnceAtItsLineAndTheScenariosStillRun() async throws {
        struct Failure: Error {}
        Given("a step") { [self] _, _ in ran.append("step") }
        let hookLine = #line + 1
        BeforeFeature { _ in throw Failure() }
        AfterFeature { [self] _ in ran.append("after feature") }

        try await withKnownIssue {
            try await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
                await Cucumber.shared.run(self.scenario("B", line: 4, steps: [self.step(.given, "a step", line: 5)]))
            }
        } matching: { issue in
            issue.sourceLocation?.line == hookLine
        }
        #expect(ran == ["step", "step", "after feature"])
    }

    @Test func theBeforeFeatureHooksRunBeforeTheObserversHearTheFeatureStarted() async throws {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a step") { _, _ in }
        BeforeFeature { _ in observer.log.append("before feature hook") }

        try await runFeature {
            await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
        }
        #expect(observer.log.prefix(2) == ["before feature hook", "feature started F"])
    }

    @Test func aThrowingAfterFeatureHookFailsAtItsLine() async throws {
        struct Failure: Error {}
        Given("a step") { _, _ in }
        let hookLine = #line + 1
        AfterFeature { _ in throw Failure() }

        try await withKnownIssue {
            try await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        } matching: { issue in
            issue.sourceLocation?.line == hookLine
        }
    }

    @Test func aHookThatThrowsDoesNotStopTheHooksAfterIt() async throws {
        struct Failure: Error {}
        Given("a step") { _, _ in }
        AfterFeature { _ in throw Failure() }
        AfterFeature { [self] _ in ran.append("second after feature") }
        AfterScenario { _ in throw Failure() }
        AfterScenario { [self] _ in ran.append("second after scenario") }

        await withKnownIssue {
            try? await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        }
        #expect(ran == ["second after scenario", "second after feature"])
    }

    @Test func aScenarioAndItsFeatureFailWhenAStepDoesAndNotWhenAHookDoes() async throws {
        struct Failure: Error {}
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a step") { _, _ in }
        AfterScenario { _ in throw Failure() }

        await withKnownIssue {
            try? await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        }
        #expect(observer.log.contains("scenario passed A"))
        #expect(observer.log.contains("feature passed F"))
    }

    @Test func theAfterFeatureHooksRunBeforeTheObserversHearTheFeatureFinished() async throws {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a step") { _, _ in }
        AfterFeature { _ in observer.log.append("after feature hook") }

        try await runFeature {
            await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
        }
        #expect(observer.log.suffix(2) == ["after feature hook", "feature passed F"])
    }
}
