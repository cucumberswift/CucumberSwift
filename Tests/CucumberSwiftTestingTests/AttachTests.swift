@testable import CucumberSwiftTesting
import Foundation
import Testing

#if compiler(>=6.2)
extension CucumberTests {
    @Test func attachRecordsTheValueWithItsNameAtTheRunningStepsLineInTheFeatureFile() async {
        var recorded = [(name: String, text: String, line: Int?)]()
        Given("a log") { _, _ in
            attach(Attachment("the log", named: "log.txt")) { attachment, location in
                let text = (try? attachment.withUnsafeBytes { String(decoding: $0, as: UTF8.self) }) ?? ""
                recorded.append((attachment.preferredName, text, location.line))
            }
        }

        await Cucumber.shared.run(scenario([step(.given, "a log", line: 3)]))
        #expect(recorded.map(\.name) == ["log.txt"])
        #expect(recorded.map(\.text) == ["the log"])
        #expect(recorded.map(\.line) == [3])
    }

    @Test func attachOutsideAStepKeepsWhereItWasCalled() {
        RunningLocation.shared.current = nil
        var line: Int?
        attach(Attachment("x", named: "x.txt")) { _, location in line = location.line }
        #expect(line == #line - 1)
    }
}
#endif
