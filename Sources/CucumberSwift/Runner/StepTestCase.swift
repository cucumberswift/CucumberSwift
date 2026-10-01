//
//  StepTestCase.swift
//  CucumberSwift
//

import Foundation
import XCTest

/// The superclass of the test case generated for each step. A step that follows a failed step does not
/// run, and throwing `XCTSkip` before it starts makes Xcode report it as skipped, not as a pass.
class StepTestCase: XCTestCase {
    static let skippedAfterFailureMessage = "Skipped: an earlier step in this scenario failed."

    /// Returns why the step must not run, or `nil` when it should.
    var skipReason: (() -> String?)?

    /// Why a step of `scenario` must not run, or `nil` when it should: an earlier step in the scenario failed.
    static func skipReason(for scenario: Scenario?) -> String? {
        Cucumber.shared.failedScenarios.contains { $0 === scenario } ? skippedAfterFailureMessage : nil
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        if let reason = skipReason?() {
            throw XCTSkip(reason)
        }
    }
}
