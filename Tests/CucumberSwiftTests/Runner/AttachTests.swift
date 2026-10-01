//
//  AttachTests.swift
//  CucumberSwiftTests
//
//  Coverage for issue #63: a hook has no XCTestCase to add an attachment to, so Attach(_:) does it.
//

import Foundation
import XCTest
@testable import CucumberSwift

class AttachTests: XCTestCase {
    private class RecordingActivity: NSObject, XCTActivity {
        var name = "recording"
        var added = [XCTAttachment]()
        func add(_ attachment: XCTAttachment) { added.append(attachment) }
    }

    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testAttachAddsTheAttachmentToAnActivityNamedAfterIt() {
        let activity = RecordingActivity()
        var activityName: String?
        let attachment = XCTAttachment(string: "evidence")
        attachment.name = "Final screen"

        attach(attachment) { name, block in
            activityName = name
            block(activity)
        }

        XCTAssertEqual(activityName, "Final screen")
        XCTAssertEqual(activity.added.count, 1)
        XCTAssertTrue(activity.added.first === attachment)
    }

    func testAttachNamesTheActivityWhenTheAttachmentHasNoName() {
        var activityName: String?
        attach(XCTAttachment(string: "evidence")) { name, _ in activityName = name }
        XCTAssertEqual(activityName, "Attachment")
    }

    func testAttachWorksFromInsideAnAfterScenarioHook() {
        var attached = false
        AfterScenario { _ in
            Attach(XCTAttachment(string: "evidence"))
            attached = true
        }
        let scenario = Scenario(with: [], title: "Attach", tags: [], position: .start)
        Cucumber.shared.afterScenarioHooks.forEach { $0.hook(scenario) }
        XCTAssertTrue(attached)
    }
}
