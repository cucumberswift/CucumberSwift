@testable import CucumberSwiftTesting
import Foundation
import Testing

/// Scenarios that run at the same time: where their failures, their verbose lines and their features land.
extension CucumberTests {
    #if compiler(>=6.2)
    /// Scenarios that fail at the same time, each while the other's step is the one that started last, are
    /// failed at their own steps in the report, with their own messages.
    @Test(.reportedInFeatureFiles)
    func failuresInScenariosThatRunAtTheSameTimeAreInTheirOwnStepsInTheReport() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        var paying = Set<String>()
        // Each payment step waits until both have started, so that each fails while the other is running.
        func pay(_ name: String) async {
            paying.insert(name)
            while paying.count < 2 { await Task.yield() }
            #expect(Bool(false), "the \(name) payment was refused")
        }
        Given("a basket") { _, _ in await Task.yield() }
        When("I pay by card") { _, _ in await pay("card") }
        When("I pay {int}") { _, _ in await pay("cash") }
        Then("the order is paid") { _, _ in await Task.yield() }

        let scenarios = parityScenarios()
        Cucumber.shared.beginSuite()
        await withKnownIssue {
            async let first: Void = Cucumber.shared.run(scenarios[0])
            async let second: Void = Cucumber.shared.run(scenarios[1])
            _ = await (first, second)
        }
        Cucumber.shared.endSuite()

        let elements = try #require(try readReport(url).first?["elements"] as? [[String: Any]])
        #expect(elements.compactMap { $0["name"] as? String } == ["Pay by card", "Pay 5 (example 1)"])
        for (element, name) in zip(elements, ["card", "cash"]) {
            let results = try #require(element["steps"] as? [[String: Any]]).compactMap { $0["result"] as? [String: Any] }
            #expect(results.map { $0["status"] as? String } == ["passed", "failed", "passed"])
            #expect((results[1]["error_message"] as? String)?.contains("the \(name) payment was refused") == true)
        }
    }
    #endif

    @Test func aFeatureWhoseScenariosAreStillRunningIsNotEndedWhenAnotherFeatureStarts() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a thing") { _, _ in await Task.yield() }
        let other = GherkinScenario(
            featureTitle: "G",
            featureTags: [],
            title: "T",
            tags: [],
            file: "/Features/Other.feature",
            line: 2,
            column: 3,
            steps: [])

        Cucumber.shared.beginSuite()
        async let first: Void = Cucumber.shared.run(scenario([step(.given, "a thing", line: 3), step(.given, "a thing", line: 4)]))
        async let second: Void = Cucumber.shared.run(other)
        _ = await (first, second)
        #expect(!observer.log.contains("feature passed F"))
        Cucumber.shared.endFeature(file: "/Features/Test.feature", title: "F", line: 1)
        Cucumber.shared.endFeature(file: "/Features/Other.feature", title: "G", line: 1)
        Cucumber.shared.endSuite()

        #expect(observer.log.suffix(3) == ["feature passed F", "feature passed G", "suite finished"])
    }

    // MARK: Turning parallel scenarios on

    @Test func parallelTestingIsReadAsCucumberSwiftReadsItsFeatureFlags() {
        for text in ["YES", "yes", "TRUE", "True", "1", " 1 "] { #expect(CucumberSettings.bool(text) == true) }
        for text in ["NO", "no", "FALSE", "false", "0"] { #expect(CucumberSettings.bool(text) == false) }
        for text in ["", "maybe", "2", "on"] { #expect(CucumberSettings.bool(text) == nil) }
        #expect(CucumberSettings.bool(nil) == nil)
    }

    @Test func scenariosRunInParallelOnlyWhenTheEnvironmentVariableThenTheCompilationConditionSaySo() {
        let key = "CUCUMBER_PARALLEL_TESTING"
        #expect(!CucumberSettings.runsInParallel(compiled: false, environment: [:]))
        #expect(CucumberSettings.runsInParallel(compiled: true, environment: [:]))
        #expect(CucumberSettings.runsInParallel(compiled: false, environment: [key: "yes"]))
        #expect(!CucumberSettings.runsInParallel(compiled: true, environment: [key: "NO"]))
        // A value that isn't a setting is ignored, as it is for CucumberSwift.
        #expect(!CucumberSettings.runsInParallel(compiled: false, environment: [key: "maybe"]))
        #expect(CucumberSettings.runsInParallel(compiled: true, environment: [key: "maybe"]))
    }

    @Test func theGeneratedSuiteIsSerializedUnlessScenariosRunInParallel() {
        defer { CucumberSettings.isSuiteSerialized = false }
        #expect(scenarioOrder(compiled: false, environment: [:]) is ParallelizationTrait)
        #expect(CucumberSettings.isSuiteSerialized)
        #expect(scenarioOrder(compiled: false, environment: ["CUCUMBER_PARALLEL_TESTING": "1"]) is CucumberParallelScenariosTrait)
        #expect(!CucumberSettings.isSuiteSerialized)
    }

    @Test func parallelTestingSetInSetupStepsIsReportedOnceBecauseItIsTooLate() async {
        defer {
            Cucumber.parallelTesting = nil
            CucumberSettings.isSuiteSerialized = false
        }
        Cucumber.shared.hasReportedParallelTestingTooLate = false
        CucumberSettings.isSuiteSerialized = true

        // Not set, or off: nothing to say.
        await Cucumber.shared.run(scenario([]))
        Cucumber.parallelTesting = false
        await Cucumber.shared.run(scenario([]))

        Cucumber.parallelTesting = true
        await withKnownIssue {
            await Cucumber.shared.run(scenario([]))
        } matching: { issue in
            issue.sourceLocation?.fileID == "Features/Test.feature"
                && issue.comments.contains { $0.rawValue.contains("Set the environment variable CUCUMBER_PARALLEL_TESTING to YES") }
        }
        // Once per run, not for every scenario.
        await Cucumber.shared.run(scenario([]))
    }

    @Test func parallelTestingSetInSetupStepsIsFineWhenTheSuiteIsNotSerialized() async {
        defer { Cucumber.parallelTesting = nil }
        Cucumber.shared.hasReportedParallelTestingTooLate = false
        CucumberSettings.isSuiteSerialized = false
        Cucumber.parallelTesting = true
        await Cucumber.shared.run(scenario([]))
    }
}
