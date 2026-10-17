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

    @Test func attachOutsideAStepHasNoLocationInTheFeatureFile() {
        RunningLocation.shared.current = nil
        var location: SourceLocation?? = .none
        attach(Attachment("x", named: "x.txt")) { _, recordedAt in location = .some(recordedAt) }
        #expect(location == .some(nil))
    }
}
#endif
