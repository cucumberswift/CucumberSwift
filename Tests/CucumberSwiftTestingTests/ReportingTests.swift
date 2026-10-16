@testable import CucumberSwiftTesting
import Foundation
import JSONSchema
import Testing

struct Broken: Error, CustomStringConvertible { var description: String { "the card was declined" } }

/// What the test target's `CucumberTestObservable` conformance hands the runner.
@MainActor
enum ObserverRegistry {
    static var observers = [CucumberTestObserver]()
}

/// Records what the runner tells an observer, one line for each event.
@MainActor
final class RecordingObserver: CucumberTestObserver {
    var log = [String]()

    private static func describe(_ result: Reporter.Result) -> String {
        if case .failed(let message) = result { return message.map { "failed: \($0)" } ?? "failed" }
        return "\(result)"
    }

    func testSuiteStarted(at _: Date) { log.append("suite started") }
    func testSuiteFinished(at _: Date) { log.append("suite finished") }
    func didStart(feature: Feature, at _: Date) { log.append("feature started \(feature.title)") }
    func didStart(scenario: Scenario, at _: Date) { log.append("scenario started \(scenario.title)") }
    func didStart(step: Step, at _: Date) { log.append("step started \(step.keywordName) \(step.match)") }
    func didFinish(feature: Feature, result: Reporter.Result, duration _: Measurement<UnitDuration>) {
        log.append("feature \(Self.describe(result)) \(feature.title)")
    }
    func didFinish(scenario: Scenario, result: Reporter.Result, duration _: Measurement<UnitDuration>) {
        log.append("scenario \(Self.describe(result)) \(scenario.title)")
    }
    func didFinish(step _: Step, result: Reporter.Result, duration _: Measurement<UnitDuration>) {
        log.append("step \(Self.describe(result))")
    }
}

extension Cucumber: CucumberTestObservable {
    public var observers: [CucumberTestObserver] { ObserverRegistry.observers }
}

extension CucumberTests {
    func reportURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CucumberSwiftTestingReports-\(UUID().uuidString)")
            .appendingPathComponent("report.json")
    }

    func readReport(_ url: URL) throws -> [[String: Any]] {
        let data = try Data(contentsOf: url)
        return try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    }

    /// The report's text with each duration replaced by 0, which differs from one run to the next.
    func withoutDurations(_ data: Data) throws -> String {
        let text = try #require(String(data: data, encoding: .utf8))
        return text.replacingOccurrences(of: #""duration" : [0-9.e+-]+"#, with: #""duration" : 0"#, options: .regularExpression)
    }

    @Test func observersSeeTheSuiteTheFeatureTheScenarioAndEachStepInOrder() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a thing") { _, _ in }

        Cucumber.shared.beginSuite()
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a thing", line: 3), step(.then, "a result", line: 4)]))
        }
        Cucumber.shared.endFeature(file: "/Features/Test.feature", title: "F", line: 1)
        Cucumber.shared.endSuite()

        #expect(observer.log == [
            "suite started",
            "feature started F",
            "scenario started S",
            "step started Given a thing",
            "step passed",
            "step started Given a result",
            // The step has no step definition: it fails, and the scenario goes no further.
            "step failed: \(Cucumber.missingStepDefinitionMessage(suggestion: "Given(\"a result\") { _, _ in }"))",
            "scenario failed S",
            "feature failed F",
            "suite finished"
        ])
    }

    @Test func aFeatureThatNothingSaysIsOverEndsWhenTheNextOneStarts() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        let other = GherkinScenario(
            featureTitle: "G",
            featureTags: [],
            title: "T",
            tags: [],
            file: "/Features/Other.feature",
            line: 2,
            column: 3,
            steps: [])

        await Cucumber.shared.run(scenario([]))
        await Cucumber.shared.run(other)

        #expect(observer.log == [
            "feature started F", "scenario started S", "scenario passed S",
            "feature passed F", "feature started G", "scenario started T", "scenario passed T"
        ])
    }

    @Test func aFeatureIsOneObjectForAllOfItsScenarios() async {
        final class Features: CucumberTestObserver {
            var seen = [ObjectIdentifier]()
            func testSuiteStarted(at _: Date) {}
            func testSuiteFinished(at _: Date) {}
            func didStart(feature _: Feature, at _: Date) {}
            func didStart(scenario: Scenario, at _: Date) { scenario.feature.map { seen.append(ObjectIdentifier($0)) } }
            func didStart(step _: Step, at _: Date) {}
            func didFinish(feature _: Feature, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {}
            func didFinish(scenario _: Scenario, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {}
            func didFinish(step _: Step, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {}
        }
        let observer = Features()
        Cucumber.shared.reporters = [observer]

        await Cucumber.shared.run(scenario([]))
        await Cucumber.shared.run(scenario([]))

        #expect(observer.seen.count == 2)
        #expect(Set(observer.seen).count == 1)
    }

    @Test func observersFromTheCucumberTestObservableConformanceAreInstalled() async {
        let observer = RecordingObserver()
        ObserverRegistry.observers = [observer]
        defer { ObserverRegistry.observers = [] }
        Cucumber.shared.reporters = Cucumber.shared.makeReporters()

        await Cucumber.shared.run(scenario([]))

        #expect(Cucumber.shared.reporters.contains { ($0 as AnyObject) === observer })
        #expect(observer.log == ["feature started F", "scenario started S", "scenario passed S"])
    }

    @Test func verboseOutputPrintsEachFeatureScenarioAndStepWithItsResult() async {
        var lines = [String]()
        // swiftlint:disable:next trailing_closure
        Cucumber.shared.reporters = [VerboseReporter(write: { lines.append($0) })]
        Given("a thing") { _, _ in }
        Then("a result") { _, _ in throw Broken() }

        Cucumber.shared.beginSuite()
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a thing", line: 3), step(.then, "a result", line: 4)]))
        }
        Cucumber.shared.endFeature(file: "/Features/Test.feature", title: "F", line: 1)
        Cucumber.shared.endSuite()

        let masked = lines.map { $0.replacingOccurrences(of: #"\(\d+\.\d{3}s\)"#, with: "(0.000s)", options: .regularExpression) }
        #expect(masked == [
            "[CucumberSwift] Test suite started",
            "[CucumberSwift] Feature: F",
            "[CucumberSwift]   Scenario: S",
            "[CucumberSwift]     Given a thing",
            "[CucumberSwift]       -> passed (0.000s)",
            "[CucumberSwift]     Given a result",
            "[CucumberSwift]       -> failed: the card was declined (0.000s)",
            "[CucumberSwift]   Scenario \"S\" failed (0.000s)",
            "[CucumberSwift] Feature \"F\" failed (0.000s)",
            "[CucumberSwift] Test suite finished"
        ])
    }

    @Test func verboseOutputIsOffUnlessTheEnvironmentTheStaticVariableOrTheImplementationAsksForIt() {
        let cucumber = Cucumber.shared
        #expect(!cucumber.isVerbose)

        cucumber.environment = ["CUCUMBER_VERBOSE": "1"]
        #expect(cucumber.isVerbose)
        cucumber.environment = ["CUCUMBER_VERBOSE": " TRUE "]
        #expect(cucumber.isVerbose)
        cucumber.environment = ["CUCUMBER_VERBOSE": "0"]
        #expect(!cucumber.isVerbose)

        cucumber.environment = [:]
        Cucumber.verboseOutput = true
        #expect(cucumber.isVerbose)
        Cucumber.verboseOutput = false

        ImplementationSettings.verbose = true
        #expect(cucumber.isVerbose)
    }

    @Test func theInstalledVerboseReporterPrintsOnlyWhenVerboseIsOn() {
        var lines = [String]()
        let reporter = VerboseReporter(isEnabled: { Cucumber.shared.isVerbose }, write: { lines.append($0) })
        reporter.testSuiteStarted(at: Date())
        #expect(lines.isEmpty)

        Cucumber.verboseOutput = true
        reporter.testSuiteStarted(at: Date())
        #expect(lines == ["[CucumberSwift] Test suite started"])
    }

    @Test func theReportPathIsTheStaticVariableThenTheEnvironmentVariable() {
        let key = "CUCUMBER_REPORT_PATH"
        #expect(CucumberSettings.reportPath(environment: [:]) == nil)
        #expect(CucumberSettings.reportPath(environment: [key: " "]) == nil)
        #expect(CucumberSettings.reportPath(environment: [key: "/tmp/env.json"]) == "/tmp/env.json")

        Cucumber.reportPath = "/tmp/static.json"
        #expect(CucumberSettings.reportPath(environment: [key: "/tmp/env.json"]) == "/tmp/static.json")
        #expect(CucumberSettings.reportPath(environment: [:]) == "/tmp/static.json")
    }

    /// The scenarios and steps of ReportParityTests.feature in CucumberSwiftTests, as the generator writes them.
    func parityScenarios() -> [GherkinScenario] {
        func step(_ keyword: Step.Keyword, _ name: String, _ text: String, line: Int) -> GherkinStep {
            GherkinStep(keyword: keyword, keywordName: name, text: text, line: line, column: 5, suggestion: "")
        }
        func scenario(_ title: String, tags: [String], line: Int, _ steps: [GherkinStep]) -> GherkinScenario {
            GherkinScenario(
                featureTitle: "Checkout",
                featureTags: ["shop"],
                featureDescription: "Collect payment for the basket.\n",
                featureLine: 1,
                title: title,
                tags: tags,
                file: "/Features/Checkout.feature",
                line: line,
                column: 3,
                steps: steps)
        }
        let basket = step(.given, "Given", "a basket", line: 6)
        let paid = { line in step(.then, "Then", "the order is paid", line: line) }
        return [
            scenario("Pay by card", tags: ["shop", "fast"], line: 8, [basket, step(.when, "When", "I pay by card", line: 10), paid(11)]),
            scenario("Pay 5 (example 1)", tags: ["shop"], line: 19, [basket, step(.when, "When", "I pay 5", line: 14), paid(15)]),
            scenario("Pay 10 (example 2)", tags: ["shop"], line: 20, [basket, step(.when, "When", "I pay 10", line: 14), paid(15)])
        ]
    }

    private func registerParityStepDefinitions() {
        Given("a basket") { _, _ in }
        When("I pay by card") { _, _ in }
        When("I pay {int}") { _, _ in }
        Then("the order is paid") { _, _ in }
    }

    private func directoryOfCucumberSwiftTests(file: String = #filePath) -> URL {
        URL(fileURLWithPath: file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CucumberSwiftTests/Reporter")
    }

    @Test func theReportIsTheOneCucumberSwiftWritesForTheSameFeatureFile() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        let reporter = try #require(CucumberJSONReporter())
        Cucumber.shared.reporters = [reporter]
        registerParityStepDefinitions()

        // In an order of their own: Swift Testing doesn't promise the order of the tests in a suite.
        let scenarios = parityScenarios()
        Cucumber.shared.beginSuite()
        for scenario in [scenarios[2], scenarios[0], scenarios[1]] {
            await Cucumber.shared.run(scenario)
        }
        Cucumber.shared.endFeature(file: "/Features/Checkout.feature", title: "Checkout", line: 1)
        Cucumber.shared.endSuite()

        let written = try Data(contentsOf: url)
        let expected = try Data(contentsOf: directoryOfCucumberSwiftTests().appendingPathComponent("ParityReport.json"))
        #expect(try withoutDurations(written) == withoutDurations(expected))

        let schemaData = try Data(contentsOf: directoryOfCucumberSwiftTests().appendingPathComponent("Schema.json"))
        let schema = try #require(JSONSerialization.jsonObject(with: schemaData) as? [String: Any])
        let result = try JSONSchema.validate(JSONSerialization.jsonObject(with: written), schema: schema)
        #expect(result.errors?.count ?? 0 == 0, "\(String(describing: result.errors))")
    }

    /// The report is sorted and rewritten whole each time, so it is written where a scenario finishes, not for
    /// every step.
    @Test func theReportIsWrittenWhereAScenarioFinishesNotForEveryStep() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        var namesInTheReportDuringTheSecondScenario = [String]()
        Given("a basket") { _, _ in }
        When("I pay by card") { _, _ in }
        When("I pay {int}") { [self] _, _ in
            let features = try readReport(url)
            namesInTheReportDuringTheSecondScenario = (features.first?["elements"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
        }
        Then("the order is paid") { _, _ in }

        let scenarios = parityScenarios()
        await Cucumber.shared.run(scenarios[0])
        await Cucumber.shared.run(scenarios[1])

        // The first scenario had finished, so it was in the report; the second was still running, so it wasn't.
        #expect(namesInTheReportDuringTheSecondScenario == ["Pay by card"])
        let elements = try #require(try readReport(url).first?["elements"] as? [[String: Any]])
        #expect(elements.compactMap { $0["name"] as? String } == ["Pay by card", "Pay 5 (example 1)"])
    }

    @Test func scenariosThatRunAtTheSameTimeAreEachInTheReportOnce() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        // Every step lets the other scenarios run, so that their events interleave.
        Given("a basket") { _, _ in await Task.yield() }
        When("I pay by card") { _, _ in await Task.yield() }
        When("I pay {int}") { _, _ in await Task.yield() }
        Then("the order is paid") { _, _ in await Task.yield() }

        let scenarios = parityScenarios()
        Cucumber.shared.beginSuite()
        async let first: Void = Cucumber.shared.run(scenarios[2])
        async let second: Void = Cucumber.shared.run(scenarios[0])
        async let third: Void = Cucumber.shared.run(scenarios[1])
        _ = await (first, second, third)
        Cucumber.shared.endSuite()

        let features = try readReport(url)
        #expect(features.count == 1)
        let elements = try #require(features.first?["elements"] as? [[String: Any]])
        #expect(elements.compactMap { $0["name"] as? String } == ["Pay by card", "Pay 5 (example 1)", "Pay 10 (example 2)"])
        for element in elements {
            let steps = try #require(element["steps"] as? [[String: Any]])
            #expect(steps.map { ($0["result"] as? [String: Any])?["status"] as? String } == ["passed", "passed", "passed"])
        }
    }

    @Test func aStepThatThrowsIsFailedWithItsErrorAndItsLaterStepsAreNotInTheReport() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        Given("a basket") { _, _ in }
        When("I pay by card") { _, _ in throw Broken() }

        await withKnownIssue {
            await Cucumber.shared.run(parityScenarios()[0])
        }

        let elements = try #require(try readReport(url).first?["elements"] as? [[String: Any]])
        let steps = try #require(elements.first?["steps"] as? [[String: Any]])
        let results = steps.compactMap { $0["result"] as? [String: Any] }
        #expect(results.map { $0["status"] as? String } == ["passed", "failed"])
        #expect(results.last?["error_message"] as? String == "the card was declined")
    }

    #if compiler(>=6.2)
    /// A failed `#expect` doesn't throw, so the report learns of it from the issue handling trait.
    @Test(.reportedInFeatureFiles)
    func aFailedExpectationInAStepIsAFailedStepInTheReport() async throws {
        let url = reportURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        Cucumber.reportPath = url.path
        Cucumber.shared.reporters = [try #require(CucumberJSONReporter())]
        Given("a basket") { _, _ in }
        When("I pay by card") { _, _ in #expect(Bool(false), "the total is wrong") }
        Then("the order is paid") { _, _ in }

        await withKnownIssue {
            await Cucumber.shared.run(parityScenarios()[0])
        }

        let elements = try #require(try readReport(url).first?["elements"] as? [[String: Any]])
        let steps = try #require(elements.first?["steps"] as? [[String: Any]])
        let results = steps.compactMap { $0["result"] as? [String: Any] }
        #expect(results.map { $0["status"] as? String } == ["passed", "failed", "passed"])
        #expect((results[1]["error_message"] as? String)?.contains("the total is wrong") == true)
    }
    #endif

    @Test func theReportsFolderIsCreatedAndAReporterMadeWithAPathKeepsIt() async throws {
        let setting = reportURL()
        let own = reportURL()
        defer {
            try? FileManager.default.removeItem(at: setting.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: own.deletingLastPathComponent())
        }
        Cucumber.reportPath = setting.path
        Cucumber.shared.reporters = [CucumberJSONReporter(reportPath: own)]
        registerParityStepDefinitions()

        await Cucumber.shared.run(parityScenarios()[0])

        #expect(FileManager.default.fileExists(atPath: own.path))
        #expect(!FileManager.default.fileExists(atPath: setting.path))
    }
}
