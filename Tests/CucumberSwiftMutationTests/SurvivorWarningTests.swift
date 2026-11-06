//
//  SurvivorWarningTests.swift
//  CucumberSwiftMutationTests
//
//  Each surviving mutant as a warning, in the compiler's format for an Xcode build phase.
//

import XCTest
@testable import CucumberSwiftMutation

final class SurvivorWarningTests: XCTestCase {
    func testASurvivorBecomesAWarningInTheCompilersFormatWithItsPlace() throws {
        let source = "let a = 1\nlet free = total > 100\n"
        let location = ["start": ["line": 2, "column": 18], "end": ["line": 2, "column": 19]]
        let mutant: [String: Any] = ["id": "1", "status": "Survived", "replacement": ">=", "location": location]
        let killed: [String: Any] = ["id": "2", "status": "Killed", "replacement": "<", "location": location]
        let report: [String: Any] = ["files": ["Sources/Shop/Basket.swift": ["source": source, "mutants": [mutant, killed]]]]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("report-\(UUID().uuidString).json")
        try JSONSerialization.data(withJSONObject: report).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let warnings = SurvivorWarning.read(report: url, root: URL(fileURLWithPath: "/tmp/shop"))
        XCTAssertEqual(warnings.count, 1, "Only the survivor")
        XCTAssertEqual(warnings.first?.xcodeLine,
                       "/tmp/shop/Sources/Shop/Basket.swift:2:18: warning: No test failed after changing > to >= at Basket.swift:2. Add a scenario that checks this code.")
    }

    func testAReportThatCantBeReadHasNoWarnings() {
        XCTAssertEqual(SurvivorWarning.read(report: URL(fileURLWithPath: "/nonexistent.json"), root: URL(fileURLWithPath: "/")), [])
    }
}
