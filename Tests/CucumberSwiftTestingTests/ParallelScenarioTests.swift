@testable import CucumberSwiftTesting
import Foundation
import Testing

/// Scenarios that run at the same time: where their failures, their verbose lines and their features land.
extension CucumberTests {
    final class Basket {
        var cukes = 0
    }

    /// Lets the other scenarios run until `condition` holds, and fails the test, instead of hanging it, if
    /// that takes more than five seconds: a scenario that never started would otherwise be waited for forever.
    static func yield(until condition: () -> Bool, _ what: String) async {
        let deadline = Date().addingTimeInterval(5)
        while !condition() {
            guard Date() < deadline else {
                Issue.record("Timed out waiting for \(what).")
                return
            }
            await Task.yield()
        }
    }

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
            await Self.yield(until: { paying.count == 2 }, "both scenarios to be paying")
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
        await Cucumber.shared.endSuite()

        let elements = try #require(try readReport(url).first?["elements"] as? [[String: Any]])
        #expect(elements.compactMap { $0["name"] as? String } == ["Pay by card", "Pay 5 (example 1)"])
        for (element, name) in zip(elements, ["card", "cash"]) {
            let results = try #require(element["steps"] as? [[String: Any]]).compactMap { $0["result"] as? [String: Any] }
            #expect(results.map { $0["status"] as? String } == ["passed", "failed"])
            #expect((results[1]["error_message"] as? String)?.contains("the \(name) payment was refused") == true)
        }
    }
    #endif

    @Test func aFeatureWhoseScenariosAreStillRunningIsNotEndedWhenAnotherFeatureStarts() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a thing") { _, _ in await Task.yield() }
        let first = scenario([step(.given, "a thing", line: 3), step(.given, "a thing", line: 4)])
        let other = GherkinScenario(
            featureTitle: "G",
            featureTags: [],
            title: "T",
            tags: [],
            file: first.file.replacingOccurrences(of: "Test", with: "Other"),
            line: 2,
            column: 3,
            steps: [])

        Cucumber.shared.beginSuite()
        async let firstRun: Void = Cucumber.shared.run(first)
        async let secondRun: Void = Cucumber.shared.run(other)
        _ = await (firstRun, secondRun)
        #expect(!observer.log.contains("feature passed F"))
        await Cucumber.shared.endFeature(file: first.file, title: "F", line: 1)
        await Cucumber.shared.endFeature(file: other.file, title: "G", line: 1)
        await Cucumber.shared.endSuite()

        #expect(observer.log.suffix(3) == ["feature passed F", "feature passed G", "suite finished"])
    }

    // MARK: Turning parallel scenarios on

    @Test func scenariosRunInParallelAsCucumberSwiftReadsAFeatureFlagThenTheCompilationCondition() {
        defer { Cucumber.parallelTesting = nil }
        let key = "CUCUMBER_PARALLEL_TESTING"
        #expect(!CucumberSettings.runsInParallel(compiled: false, environment: [:]))
        #expect(CucumberSettings.runsInParallel(compiled: true, environment: [:]))
        #expect(CucumberSettings.runsInParallel(compiled: false, environment: [key: "yes"]))
        #expect(!CucumberSettings.runsInParallel(compiled: true, environment: [key: "NO"]))
        // A value that isn't a setting is ignored, as it is for CucumberSwift.
        #expect(!CucumberSettings.runsInParallel(compiled: false, environment: [key: "maybe"]))
        #expect(CucumberSettings.runsInParallel(compiled: true, environment: [key: "maybe"]))
        // The static variable wins over the environment variable, which wins over the compilation condition.
        Cucumber.parallelTesting = true
        #expect(CucumberSettings.runsInParallel(compiled: false, environment: [key: "NO"]))
        Cucumber.parallelTesting = false
        #expect(!CucumberSettings.runsInParallel(compiled: true, environment: [key: "YES"]))
    }

    @Test func theGeneratedSuiteIsSerializedUnlessScenariosRunInParallel() {
        defer { CucumberSettings.isSuiteSerialized = false }
        #expect(scenarioOrder(compiled: false, environment: [:]) is ParallelizationTrait)
        #expect(CucumberSettings.isSuiteSerialized)
        #expect(scenarioOrder(compiled: false, environment: ["CUCUMBER_PARALLEL_TESTING": "1"]) is CucumberParallelScenariosTrait)
        #expect(!CucumberSettings.isSuiteSerialized)
    }

    @Test func parallelTestingSetInSetupStepsCountsBecauseTheStepsAreLoadedWhenTheTestsAreDiscovered() {
        defer {
            Cucumber.parallelTesting = nil
            ImplementationSettings.parallelTesting = nil
            CucumberSettings.isSuiteSerialized = false
        }
        Cucumber.shared.isSetUp = false
        ImplementationSettings.parallelTesting = true
        #expect(scenarioOrder(compiled: false, environment: [:]) is CucumberParallelScenariosTrait)
    }

    @Test func parallelTestingThatCameTooLateIsSaidOnceWithoutFailingTheRun() async {
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
        #expect(!Cucumber.shared.hasReportedParallelTestingTooLate)

        // It isn't an issue that fails the test, only a note, and only once.
        Cucumber.parallelTesting = true
        await Cucumber.shared.run(scenario([]))
        #expect(Cucumber.shared.hasReportedParallelTestingTooLate)
    }

    @Test func parallelTestingIsNotTooLateWhenTheSuiteIsNotSerialized() async {
        defer { Cucumber.parallelTesting = nil }
        Cucumber.shared.hasReportedParallelTestingTooLate = false
        CucumberSettings.isSuiteSerialized = false
        Cucumber.parallelTesting = true
        await Cucumber.shared.run(scenario([]))
        #expect(!Cucumber.shared.hasReportedParallelTestingTooLate)
    }

    // MARK: What runs together

    @Test func theUnitIsReadAsCucumberSwiftReadsItsFeatureFlags() {
        defer { Cucumber.parallelTestingUnit = nil }
        let key = "CUCUMBER_PARALLEL_TESTING_UNIT"
        #expect(CucumberSettings.parallelTestingUnit(environment: [:]) == .scenario)
        for text in ["feature", "FEATURE", " Feature\t"] {
            #expect(CucumberSettings.parallelTestingUnit(environment: [key: text]) == .feature)
        }
        #expect(CucumberSettings.parallelTestingUnit(environment: [key: "scenario"]) == .scenario)
        // A value that isn't a setting is ignored, as it is for CucumberSwift.
        for text in ["", "features", "yes"] { #expect(CucumberSettings.parallelTestingUnit(environment: [key: text]) == .scenario) }
        // The static variable wins over the environment variable.
        Cucumber.parallelTestingUnit = .feature
        #expect(CucumberSettings.parallelTestingUnit(environment: [key: "scenario"]) == .feature)
        Cucumber.parallelTestingUnit = .scenario
        #expect(CucumberSettings.parallelTestingUnit(environment: [key: "feature"]) == .scenario)
    }

    @Test func aFeaturesSuiteIsSerializedOnlyWhenScenariosRunInParallelAndTheUnitIsTheFeature() {
        defer { Cucumber.parallelTestingUnit = nil }
        let parallel = ["CUCUMBER_PARALLEL_TESTING": "YES"]
        let feature = parallel.merging(["CUCUMBER_PARALLEL_TESTING_UNIT": "feature"]) { $1 }
        #expect(featureOrder(compiled: false, environment: parallel) is CucumberParallelScenariosTrait)
        #expect(featureOrder(compiled: false, environment: feature) is ParallelizationTrait)
        // Not in parallel, the whole suite is serialized, so a feature has nothing to add.
        #expect(featureOrder(compiled: false, environment: ["CUCUMBER_PARALLEL_TESTING_UNIT": "feature"]) is CucumberParallelScenariosTrait)
        // The compilation condition turns parallel on, and the static variable chooses the unit.
        Cucumber.parallelTestingUnit = .feature
        #expect(featureOrder(compiled: true, environment: [:]) is ParallelizationTrait)
    }

    // MARK: A scenario's own state

    @Test func aScenarioKeepsItsStateAcrossStepsAndHooksAndOtherScenariosDontShareIt() async {
        var seen = [String: Int]()
        var started = Set<String>()
        BeforeScenario { _ in Scenario.state(Basket.init).cukes = 100 }
        Given("a basket for {word}") { match, _ in
            let name = try match.first(\.word)
            Scenario.state(Basket.init).cukes += name == "one" ? 1 : 2
            started.insert(name)
            // Waits until both scenarios have a step running, so that they overlap.
            await Self.yield(until: { started.count == 2 }, "both scenarios to start")
        }
        Then("the basket is read for {word}") { match, _ in seen[try match.first(\.word)] = Scenario.state(Basket.init).cukes }

        let oneSteps = [step(.given, "a basket for one", line: 3), step(.then, "the basket is read for one", line: 4)]
        let twoSteps = [step(.given, "a basket for two", line: 3), step(.then, "the basket is read for two", line: 4)]
        async let first: Void = Cucumber.shared.run(scenario(oneSteps))
        async let second: Void = Cucumber.shared.run(scenario(twoSteps))
        _ = await (first, second)
        #expect(seen == ["one": 101, "two": 102])
    }

    @Test func aStepRunByExecuteFirstStepSeesTheStateOfTheScenarioThatCalledIt() async {
        var seen = 0
        Given("a nested step") { _, _ in seen = Scenario.state(Basket.init).cukes }
        Given("an outer step") { _, _ in
            Scenario.state(Basket.init).cukes = 7
            await ExecuteFirstStep(matching: "a nested step")
        }
        await Cucumber.shared.run(scenario([step(.given, "an outer step", line: 3)]))
        #expect(seen == 7)
    }

    @Test func aScenarioLetsGoOfItsStateWhenItIsOver() async {
        weak var weakBasket: Basket?
        Given("a basket") { _, _ in weakBasket = Scenario.state(Basket.init) }
        await Cucumber.shared.run(scenario([step(.given, "a basket", line: 3)]))
        #expect(weakBasket == nil)
    }

    @Test func differentTypesAreDifferentValuesAndAskingTwiceGivesTheSameOne() async {
        final class Beach {
            let sand = true
        }
        var checked = false
        Given("a basket and a beach") { _, _ in
            let basket = Scenario.state(Basket.init)
            #expect(Scenario.state(Basket.init) === basket)
            #expect(Scenario.state(Beach.init) !== (basket as AnyObject))
            checked = true
        }
        await Cucumber.shared.run(scenario([step(.given, "a basket and a beach", line: 3)]))
        #expect(checked)
    }

    @Test func askingForStateOutsideAScenarioRecordsAFailureAndReturnsAThrowawayValue() {
        withKnownIssue {
            #expect(Scenario.state(Basket.init).cukes == 0)
        } matching: { issue in
            issue.comments.contains { $0.rawValue.contains("Scenario.state(_:) needs a running scenario") }
        }
    }
}
