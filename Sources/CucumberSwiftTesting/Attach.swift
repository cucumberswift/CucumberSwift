//
//  Attach.swift
//  CucumberSwiftTesting
//
// Attachments are Swift Testing's, which exist from Swift 6.2. Before it `Attach` is unavailable, so that a
// step definition that attaches something fails to compile instead of losing the attachment unnoticed.

import Foundation
import Testing

#if compiler(>=6.2)
/// Adds an attachment, such as a screenshot, a log or a file, to the test that is running.
///
/// Call it from any hook or step, where there is no test to call `Attachment.record(_:)` on with a
/// location in the feature file. Xcode's test report shows the attachment under the scenario's test, and
/// `swift test --attachments-path` writes it to a folder. An attachment added in a step is recorded at the
/// step's line in its feature file.
public func Attach<Value: Attachable & Sendable>(_ attachment: Attachment<Value>) {
    attach(attachment) { attachment, location in
        guard let location else { return Attachment.record(attachment) }
        Attachment.record(attachment, sourceLocation: location)
    }
}

/// `record` is a parameter so a test can see what gets attached.
func attach<Value: Attachable & Sendable>(
    _ attachment: Attachment<Value>,
    record: (Attachment<Value>, SourceLocation?) -> Void
) {
    record(attachment, RunningLocation.current?.location)
}
#else
/// Unavailable before Swift 6.2, which added attachments to Swift Testing.
@available(*, unavailable, message: "Attach needs Swift 6.2 or later, which added attachments to Swift Testing.")
public func Attach<Value>(_: Value) {
    // Never called: the function is unavailable.
}
#endif
