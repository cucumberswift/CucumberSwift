//
//  ItemCountWait.swift
//  CucumberSwiftTests
//
//  How the UI fixture waits for the item count its app shows (#375), apart from XCUITest so that unit tests
//  can reach it. It lives in this bundle, where ItemCountWaitTests run; the fixtures' manifest,
//  Tests/ParallelFixtures/Project.swift, compiles this same file into the UI test targets.
//

import Foundation

enum ItemCountWait {
    /// What the app's item count shows at one moment.
    struct Reading: Equatable {
        let label: String
        let value: String
    }

    enum Outcome: Equatable {
        case matched
        /// The time ran out. `lastSeen` is the last reading, or nil when the count never appeared.
        case timedOut(lastSeen: Reading?)
    }

    /// The text the app shows for `count` items.
    static func text(for count: Int) -> String {
        "Items: \(count)"
    }

    /// Whether the label or the value is exactly `count`'s text. Exactly: "Items: 10" doesn't show 1.
    static func shows(_ count: Int, in reading: Reading) -> Bool {
        let text = text(for: count)
        return reading.label == text || reading.value == text
    }

    /// Reads until a reading shows `count`, or `timeout` seconds have passed on `now`, waiting `interval` seconds
    /// with `sleep` between reads. `read` returns nil while the app shows no count. It always reads once.
    static func wait(
        for count: Int,
        timeout: TimeInterval,
        interval: TimeInterval,
        read: () -> Reading?,
        now: () -> Date,
        sleep: (TimeInterval) -> Void
    ) -> Outcome {
        let deadline = now().addingTimeInterval(timeout)
        var lastSeen: Reading?
        while true {
            if let reading = read() {
                if shows(count, in: reading) { return .matched }
                lastSeen = reading
            }
            if now() >= deadline { return .timedOut(lastSeen: lastSeen) }
            sleep(interval)
        }
    }
}
