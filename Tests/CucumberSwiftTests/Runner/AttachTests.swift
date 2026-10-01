//
//  AttachTests.swift
//  CucumberSwiftTests
//
//  Coverage for issue #63: a hook or step has no XCTestCase to add an attachment to, so Attach(_:) does it.
//  A real screenshot (XCUIScreen) needs a UI test target and fails in a unit test bundle with "Not
//  authorized for performing UI testing actions", so the UI case here attaches a rendered view instead.
//

import Foundation
import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import CucumberSwift

class AttachTests: XCTestCase {
    private class RecordingActivity: NSObject, XCTActivity {
        var name = "recording"
        var added = [XCTAttachment]()
        func add(_ attachment: XCTAttachment) { added.append(attachment) }
    }

    /// What `attach` hands to its activity runner, and the attachments the activity received.
    private struct Recorded {
        var activityName: String?
        var attachments = [XCTAttachment]()
    }

    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    private func record(_ attachment: XCTAttachment) -> Recorded {
        let activity = RecordingActivity()
        var recorded = Recorded()
        attach(attachment) { name, block in
            recorded.activityName = name
            block(activity)
        }
        recorded.attachments = activity.added
        return recorded
    }

    private func scenario(_ title: String = "Attach") -> Scenario {
        Scenario(with: [], title: title, tags: [], position: .start)
    }

    // MARK: Delivery

    func testAttachAddsTheAttachmentToAnActivityNamedAfterIt() {
        let attachment = XCTAttachment(string: "evidence")
        attachment.name = "Final screen"

        let recorded = record(attachment)

        XCTAssertEqual(recorded.activityName, "Final screen")
        XCTAssertEqual(recorded.attachments.count, 1)
        XCTAssertTrue(recorded.attachments.first === attachment)
    }

    func testAttachNamesTheActivityWhenTheAttachmentHasNoName() {
        XCTAssertEqual(record(XCTAttachment(string: "evidence")).activityName, "Attachment")
    }

    func testAttachKeepsTheLifetimeTheCallerSet() {
        let attachment = XCTAttachment(string: "evidence")
        attachment.lifetime = .keepAlways
        XCTAssertEqual(record(attachment).attachments.first?.lifetime, .keepAlways)
    }

    // MARK: Without a UI (any test bundle)

    func testAttachDeliversAStringAttachment() {
        let attachment = XCTAttachment(string: "log line")
        XCTAssertTrue(record(attachment).attachments.first === attachment)
    }

    func testAttachDeliversDataWithATypeIdentifier() throws {
        let data = try XCTUnwrap(#"{"scenario":"Attach"}"#.data(using: .utf8))
        let attachment = XCTAttachment(uniformTypeIdentifier: "public.json", name: "state.json", payload: data, userInfo: nil)

        let recorded = record(attachment)

        XCTAssertEqual(recorded.activityName, "state.json")
        XCTAssertTrue(recorded.attachments.first === attachment)
    }

    func testAttachDeliversAFileAttachment() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AttachTests-\(UUID().uuidString).txt")
        try "from a file".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let attachment = XCTAttachment(contentsOfFile: url)

        XCTAssertTrue(record(attachment).attachments.first === attachment)
    }

    // MARK: With a UI (a rendered view; XCUIScreen needs a UI test target)

    #if canImport(UIKit)
    func testAttachDeliversASnapshotOfARenderedView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 80))
        view.backgroundColor = .systemTeal
        let label = UILabel(frame: view.bounds)
        label.text = "Checkout"
        view.addSubview(label)
        let image = UIGraphicsImageRenderer(bounds: view.bounds).image { context in
            view.layer.render(in: context.cgContext)
        }
        XCTAssertEqual(image.size, CGSize(width: 120, height: 80))
        let attachment = XCTAttachment(image: image)
        attachment.name = "Checkout screen"

        let recorded = record(attachment)

        XCTAssertEqual(recorded.activityName, "Checkout screen")
        XCTAssertTrue(recorded.attachments.first === attachment)
    }
    #endif

    // MARK: From hooks and steps

    func testAttachWorksFromInsideAnAfterScenarioHook() {
        var attached = false
        AfterScenario { _ in
            Attach(XCTAttachment(string: "evidence"))
            attached = true
        }
        Cucumber.shared.afterScenarioHooks.forEach { $0.hook(scenario()) }
        XCTAssertTrue(attached)
    }

    func testAttachWorksFromInsideAnAsyncHook() {
        var attached = false
        AfterScenario { _ async throws in
            Attach(XCTAttachment(string: "evidence"))
            attached = true
        }
        Cucumber.shared.afterScenarioHooks.forEach { $0.hook(scenario()) }
        XCTAssertTrue(attached)
    }

    func testAttachWorksFromInsideAStep() throws {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Attachments
           Scenario: Attach from a step
              Given a step that attaches
        """, uri: "file:///Features/Attach.feature")
        var attached = false
        Given("a step that attaches") { _, _ in
            Attach(XCTAttachment(string: "evidence"))
            attached = true
        }
        let step = try XCTUnwrap(Cucumber.shared.features.first?.scenarios.first?.steps.first)
        try step.matchingDefinitions.first?.execute?("a step that attaches", step)
        XCTAssertTrue(attached)
    }
}
