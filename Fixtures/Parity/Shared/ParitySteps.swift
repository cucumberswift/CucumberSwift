//
//  ParitySteps.swift
//  Parity
//
//  The parity suite's step definitions: one file, compiled unchanged into an XCTest test target and a
//  Swift Testing test target in every leg. Only the runner's import differs, chosen by the
//  PARITY_SWIFT_TESTING compilation condition that the Swift Testing targets define. Anything else
//  that would need a runner-specific line here is a parity gap: report it, don't add an #if. The one
//  other #if is SwiftPM's own SWIFT_PACKAGE, for the bundle, which differs by build tool as it does
//  in any project.
//  See README.md.
//

#if PARITY_SWIFT_TESTING
import CucumberSwiftTesting
#else
import CucumberSwift
#endif
import Foundation
import ParityShop
import Testing
import XCTest

/// What the scenarios record, for the parity comparison: each scenario's steps and hooks, in the order
/// they ran, and each feature's hooks. Written to the folder in PARITY_TRACE_DIR, one file per scenario
/// run and one per feature hook run, because parallel workers are separate processes and their output
/// interleaves.
final class Trace: @unchecked Sendable {
    static let shared = Trace()

    private let lock = NSLock()
    /// Each scenario's file. The scenario is kept, so that its identifier isn't reused for another.
    private var files = [ObjectIdentifier: (scenario: Scenario, url: URL)]()
    private let folder = ProcessInfo.processInfo.environment["PARITY_TRACE_DIR"].map { URL(fileURLWithPath: $0) }

    /// Appends `event` to the scenario's trace.
    func record(_ scenario: Scenario?, _ event: String) {
        guard let scenario else {
            write(header: "unknown scenario", scenario: nil, event)
            return
        }
        let header = "scenario: \(scenario.feature?.title ?? "?") › \(scenario.title) (line \(scenario.location.line))"
        write(header: header, scenario: scenario, event)
    }

    /// Writes a feature hook's run to a file of its own.
    func record(_ feature: Feature, _ event: String) {
        write(header: "feature: \(feature.title)", scenario: nil, event)
    }

    private func write(header: String, scenario: Scenario?, _ event: String) {
        guard let folder else { return }
        lock.lock()
        defer { lock.unlock() }
        let url: URL
        if let scenario, let existing = files[ObjectIdentifier(scenario)] {
            url = existing.url
        } else {
            url = folder.appendingPathComponent("\(ProcessInfo.processInfo.processIdentifier)-\(UUID().uuidString).trace")
            FileManager.default.createFile(atPath: url.path, contents: Data("\(header)\n".utf8))
            if let scenario { files[ObjectIdentifier(scenario)] = (scenario, url) }
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        handle.seekToEndOfFile()
        handle.write(Data("\(event)\n".utf8))
        handle.closeFile()
    }
}

/// The state the steps of one scenario share.
final class Order {
    let basket = Basket()
    var lastItem = ""
    var note = ""
    var delivered = false
    var madeByHook = false
}

enum World {
    static var order: Order { Scenario.state(Order.init) }
}

struct ParityError: Error, CustomStringConvertible {
    var description: String { "The step threw an error on purpose" }
}

extension Cucumber: @retroactive StepImplementation {
    /// Where the XCTest runner finds the feature files: SwiftPM bundles them in the target's resource bundle,
    /// and Xcode in the test bundle. The Swift Testing runner doesn't need it.
    public var bundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle(for: Trace.self)
        #endif
    }

    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool {
        !tags.contains("skip")
    }

    public func setupSteps() {
        // CucumberSwift never measures the files in its own package folder, and this fixture is inside it.
        // Shop.swift is the code under test, whichever folder or symbolic link a leg compiles it from.
        Cucumber.coverageSources = ["/Shop.swift"]

        BeforeFeature { feature in
            Trace.shared.record(feature, "BeforeFeature")
            if feature.title == "Scenario state in a feature hook" {
                _ = World.order
            }
        }
        AfterFeature { feature in
            Trace.shared.record(feature, "AfterFeature")
        }
        BeforeScenario { scenario in
            Trace.shared.record(scenario, "BeforeScenario")
            if scenario.title == "A scenario hook reaches the scenario's state" {
                World.order.madeByHook = true
            }
        }
        AfterScenario { scenario in
            Trace.shared.record(scenario, "AfterScenario")
        }
        BeforeStep { step in
            Trace.shared.record(step.scenario, "BeforeStep \(step.match)")
        }
        AfterStep { step in
            Trace.shared.record(step.scenario, "AfterStep \(step.match)")
        }

        matching()
        hooks()
        tags()
        state()
        coverage()
        failures()
    }

    private func matching() {
        Given("the shop sells a {word} for {int} cents") { match, step in
            Trace.shared.record(step.scenario, "step: shop sells")
            let item = try match.first(\.word)
            XCTAssertEqual(Shop.price(of: item), try match.first(\.int))
        }
        MatchAll("I add {int} {string} to the basket") { match, step in
            Trace.shared.record(step.scenario, "step: add")
            let item = try match.first(\.string)
            World.order.basket.add(try match.first(\.int), of: item)
            World.order.lastItem = item
        }
        Then("the basket costs {float} dollars") { match, step in
            Trace.shared.record(step.scenario, "step: costs dollars")
            XCTAssertEqual(Double(World.order.basket.total) / 100, Double(try match.first(\.float)))
        }
        Then("the basket costs {int} cents") { match, step in
            Trace.shared.record(step.scenario, "step: costs cents")
            XCTAssertEqual(World.order.basket.total, try match.first(\.int))
        }
        Then("the last item added is a {word}") { match, step in
            Trace.shared.record(step.scenario, "step: last item")
            XCTAssertEqual(World.order.lastItem, try match.first(\.word))
        }
        When(#/^I add (\d+) (\w+)es by regular expression$/#) { match, step in
            Trace.shared.record(step.scenario, "step: add by regular expression")
            World.order.basket.add(Int(match.output.1) ?? -1, of: String(match.output.2))
        }
        When("I add these to the basket:") { _, step in
            Trace.shared.record(step.scenario, "step: add table")
            for row in step.dataTable?.rows.dropFirst() ?? [] {
                World.order.basket.add(Int(row[1]) ?? -1, of: row[0])
            }
        }
        When("I write this note:") { _, step in
            Trace.shared.record(step.scenario, "step: note")
            World.order.note = step.docString?.literal ?? ""
        }
        Then("the note has {int} words") { match, step in
            Trace.shared.record(step.scenario, "step: note words")
            XCTAssertEqual(World.order.note.split(separator: " ").count, try match.first(\.int))
        }
        Given("the basket is empty") { _, step in
            Trace.shared.record(step.scenario, "step: empty")
            XCTAssertEqual(World.order.basket.total, 0)
        }
        When("I wait for the delivery") { _, step in
            Trace.shared.record(step.scenario, "step: wait")
            try await Task.sleep(nanoseconds: 50_000_000)
            World.order.delivered = true
        }
        Then("the delivery has arrived") { _, step in
            Trace.shared.record(step.scenario, "step: arrived")
            XCTAssertTrue(World.order.delivered)
        }
    }

    private func hooks() {
        Given("a step runs") { _, step in
            Trace.shared.record(step.scenario, "step: a step runs")
        }
        When("another step runs") { _, step in
            Trace.shared.record(step.scenario, "step: another step runs")
        }
        Then("the hooks so far ran in order") { _, step in
            Trace.shared.record(step.scenario, "step: hooks in order")
        }
    }

    private func tags() {
        Then("the scenario's tags are {string}") { match, step in
            Trace.shared.record(step.scenario, "step: tags \(step.scenario?.tags.joined(separator: " ") ?? "")")
            XCTAssertEqual(step.scenario?.tags.map { "@\($0)" }.joined(separator: " "), try match.first(\.string))
        }
        Then("this step never runs") { _, step in
            Trace.shared.record(step.scenario, "step: never runs")
            XCTFail("This step should never run")
        }
    }

    private func state() {
        Given("I add {int} {string} to my scenario's basket") { match, step in
            Trace.shared.record(step.scenario, "step: add to my basket")
            World.order.basket.add(try match.first(\.int), of: try match.first(\.string))
        }
        Then("my scenario's basket holds {int} {string}") { match, step in
            Trace.shared.record(step.scenario, "step: my basket holds")
            XCTAssertEqual(World.order.basket.items[try match.first(\.string)], try match.first(\.int))
        }
        Then("my scenario's basket was made by a hook") { _, step in
            Trace.shared.record(step.scenario, "step: made by a hook")
            XCTAssertTrue(World.order.madeByHook)
        }
    }

    private func coverage() {
        Then("a {string} costs {int} cents") { match, step in
            Trace.shared.record(step.scenario, "step: a costs")
            XCTAssertEqual(Shop.price(of: try match.first(\.string)), try match.first(\.int))
        }
    }

    private func failures() {
        When("an XCTest assertion fails") { _, step in
            Trace.shared.record(step.scenario, "step: XCTest assertion fails")
            XCTAssertEqual(1, 2, "An XCTest assertion failed on purpose")
        }
        When("an expectation fails") { _, step in
            Trace.shared.record(step.scenario, "step: expectation fails")
            #expect(1 == 2, "An expectation failed on purpose")
        }
        When("an issue is recorded") { _, step in
            Trace.shared.record(step.scenario, "step: issue recorded")
            Issue.record("An issue recorded on purpose")
        }
        When("a requirement fails") { _, step in
            Trace.shared.record(step.scenario, "step: requirement fails")
            try #require(1 == 2, "A requirement failed on purpose")
            Trace.shared.record(step.scenario, "step: after the requirement")
        }
        When("a step throws an error") { _, step in
            Trace.shared.record(step.scenario, "step: throws")
            throw ParityError()
        }
        When("a step skips the scenario") { _, step in
            Trace.shared.record(step.scenario, "step: skips")
            throw XCTSkip("Skipped on purpose")
        }
        Then("a feature hook asked for scenario state") { _, step in
            Trace.shared.record(step.scenario, "step: feature hook state")
        }
    }
}
