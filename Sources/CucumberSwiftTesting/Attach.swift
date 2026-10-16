//
//  Attach.swift
//  CucumberSwiftTesting
//
// Attachments are Swift Testing's, which exist from Swift 6.2. Before it `Attach` is unavailable, so that a
// step definition that attaches something fails to compile instead of losing the attachment unnoticed.

import Foundation
import Testing

#if compiler(>=6.2)
/// Adds an attachment, such as a log or a file, to the test that is running. Xcode's test report shows it
/// under the test, and `swift test` writes it to the folder `--attachments-path` names.
///
/// Call it from any hook or step. An attachment added in a step is recorded at the step's line in its
/// feature file.
public func Attach<Value: Attachable & Sendable>(_ value: Value, named name: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) {
    let location = RunningLocation.shared.current?.location ?? sourceLocation
    attach(Attachment(value, named: name, sourceLocation: location), sourceLocation: location)
}

/// Adds an attachment you made yourself, to set its name or where it is from.
public func Attach<Value: Attachable & Sendable>(_ attachment: Attachment<Value>, sourceLocation: SourceLocation = #_sourceLocation) {
    attach(attachment, sourceLocation: RunningLocation.shared.current?.location ?? sourceLocation)
}

/// `record` is a parameter so that a test can see what gets attached.
func attach<Value: Attachable & Sendable>(
    _ attachment: Attachment<Value>,
    sourceLocation: SourceLocation = #_sourceLocation,
    record: (Attachment<Value>, SourceLocation) -> Void = { Attachment.record($0, sourceLocation: $1) }
) {
    record(attachment, RunningLocation.shared.current?.location ?? sourceLocation)
}
#else
/// Unavailable before Swift 6.2, which added attachments to Swift Testing.
@available(*, unavailable, message: "Attach needs Swift 6.2 or later, which added attachments to Swift Testing.")
public func Attach<Value>(_ value: Value, named name: String? = nil) {}
#endif
