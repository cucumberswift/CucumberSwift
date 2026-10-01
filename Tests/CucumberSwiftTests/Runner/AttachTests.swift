//
//  AttachTests.swift
//  CucumberSwiftTests
//
//  Coverage for issue #63: a hook has no XCTestCase to add an attachment to, so Attach(_:) does it.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class AttachTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testAttachWorksFromInsideAnAfterScenarioHook() throws {
        var attached = false
        AfterScenario { _ in
            let attachment = XCTAttachment(string: "evidence")
            attachment.lifetime = .keepAlways
            Attach(attachment)
            attached = true
        }
        let scenario = Scenario(with: [], title: "Attach", tags: [], position: .start)
        Cucumber.shared.afterScenarioHooks.forEach { $0.hook(scenario) }
        XCTAssertTrue(attached)
    }
}
