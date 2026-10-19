@testable import CucumberSwiftTesting
import Foundation
import Testing

#if compiler(>=6.2)
extension CucumberTests {
    static func text(of attachment: Attachment<String>) -> String {
        let text = try? attachment.withUnsafeBytes { String(bytes: $0, encoding: .utf8) }
        return text.flatMap { $0 } ?? ""
    }

    @Test func attachRecordsTheValueWithItsNameAtTheRunningStepsLineInTheFeatureFile() async {
        var recorded = [(name: String, text: String, line: Int?)]()
        Given("a log") { _, _ in
            attach(Attachment("the log", named: "log.txt")) { attachment, location in
                recorded.append((attachment.preferredName, Self.text(of: attachment), location?.line))
            }
        }

        await Cucumber.shared.run(scenario([step(.given, "a log", line: 3)]))
        #expect(recorded.map(\.name) == ["log.txt"])
        #expect(recorded.map(\.text) == ["the log"])
        #expect(recorded.map(\.line) == [3])
    }

    @Test func attachesFromScenariosThatRunAtTheSameTimeAreRecordedAtTheirOwnStepsLines() async {
        var recorded = [String: Int?]()
        var started = Set<String>()
        Given("a log for {word}") { match, _ in
            let name = try match.first(\.word)
            started.insert(name)
            // Waits until both scenarios have a step running, so that each attaches while the other's
            // step is the one that started last.
            await Self.yield(until: { started.count == 2 }, "both scenarios to start")
            attach(Attachment(name, named: "\(name).txt")) { attachment, location in
                recorded[Self.text(of: attachment)] = .some(location?.line)
            }
        }

        async let first: Void = Cucumber.shared.run(scenario([step(.given, "a log for one", line: 3)]))
        async let second: Void = Cucumber.shared.run(scenario([step(.given, "a log for two", line: 9)]))
        _ = await (first, second)
        #expect(recorded["one"] == .some(3))
        #expect(recorded["two"] == .some(9))
    }

    @Test func attachOutsideAStepHasNoLocationInTheFeatureFile() {
        var location: SourceLocation?? = .none
        attach(Attachment("x", named: "x.txt")) { _, recordedAt in location = .some(recordedAt) }
        #expect(location == .some(nil))
    }
}
#endif
