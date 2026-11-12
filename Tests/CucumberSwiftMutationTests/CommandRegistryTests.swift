//
//  CommandRegistryTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import Foundation
import XCTest
@testable import CucumberSwiftMutation

/// Starting a command and cancelling the run, from two threads at once, as the signal handler does. The commands are
/// fake: `start` returns a process ID without starting a process.
final class CommandRegistryTests: XCTestCase {
    private final class Outcome: @unchecked Sendable {
        var started = false
        var stopped = Set<Int32>()
    }

    func testACancelEitherKeepsACommandFromStartingOrStopsIt() {
        for pid in Int32(1)...200 {
            let registry = CommandRegistry()
            let outcome = Outcome()
            let group = DispatchGroup()
            DispatchQueue.global().async(group: group) {
                outcome.started = registry.launch(ignoresCancellation: false) {
                    // A slow start, as `Process.run()` can be: a cancel now must wait for it.
                    Thread.sleep(forTimeInterval: 0.001)
                    return pid
                }
            }
            DispatchQueue.global().async(group: group) { outcome.stopped = registry.cancel() }
            group.wait()
            XCTAssertEqual(outcome.stopped, outcome.started ? [pid] : [], "A command that started before the cancel is stopped")
            XCTAssertFalse(registry.launch(ignoresCancellation: false) { XCTFail("started after the cancel"); return 0 })
        }
    }

    func testACommandThatIgnoresCancellationStillStarts() {
        let registry = CommandRegistry()
        _ = registry.cancel()
        XCTAssertTrue(registry.launch(ignoresCancellation: true) { 42 })
        XCTAssertEqual(registry.cancel(), [42])
    }
}
#endif
