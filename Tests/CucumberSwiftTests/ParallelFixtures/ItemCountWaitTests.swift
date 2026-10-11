//
//  ItemCountWaitTests.swift
//  CucumberSwiftTests
//
//  The UI fixture's count wait (#375), without an app: the readings are given, and a clock that only
//  moves when the wait sleeps, so nothing waits for real.
//

import Foundation
import XCTest

final class ItemCountWaitTests: XCTestCase {
    private final class Clock {
        var now = Date(timeIntervalSince1970: 0)
        var sleeps = 0

        func sleep(_ seconds: TimeInterval) {
            now = now.addingTimeInterval(seconds)
            sleeps += 1
        }
    }

    private func wait(for count: Int, readings: [ItemCountWait.Reading?], clock: Clock = Clock()) -> ItemCountWait.Outcome {
        var reads = readings[...]
        return ItemCountWait.wait(
            for: count,
            timeout: 30,
            interval: 0.25,
            // The last reading repeats, like an app that has stopped changing.
            read: { reads.count > 1 ? reads.removeFirst() : reads.first.flatMap { $0 } },
            now: { clock.now },
            sleep: clock.sleep
        )
    }

    func testMatchesAnExactCountInTheLabel() {
        let reading = ItemCountWait.Reading(label: "Items: 1", value: "")
        XCTAssertEqual(wait(for: 1, readings: [reading]), .matched)
    }

    func testMatchesAnExactCountInTheValue() {
        let reading = ItemCountWait.Reading(label: "", value: "Items: 1")
        XCTAssertEqual(wait(for: 1, readings: [reading]), .matched)
    }

    func testDoesNotMatchALongerCountThatStartsWithTheExpectedOne() {
        let clock = Clock()
        let reading = ItemCountWait.Reading(label: "Items: 10", value: "Items: 10")
        XCTAssertEqual(wait(for: 1, readings: [reading], clock: clock), .timedOut(lastSeen: reading))
        XCTAssertGreaterThan(clock.sleeps, 0)
    }

    func testMatchesACountThatShowsUpOnALaterRead() {
        let clock = Clock()
        let readings: [ItemCountWait.Reading?] = [
            nil,
            ItemCountWait.Reading(label: "Items: 0", value: ""),
            ItemCountWait.Reading(label: "Items: 0", value: ""),
            ItemCountWait.Reading(label: "Items: 1", value: "")
        ]
        XCTAssertEqual(wait(for: 1, readings: readings, clock: clock), .matched)
        XCTAssertEqual(clock.sleeps, 3)
    }

    func testTimesOutAfterTheTimeWithTheLastReadingSeen() {
        let clock = Clock()
        let reading = ItemCountWait.Reading(label: "Items: 0", value: "")
        XCTAssertEqual(wait(for: 2, readings: [reading], clock: clock), .timedOut(lastSeen: reading))
        XCTAssertEqual(clock.now.timeIntervalSince1970, 30, accuracy: 0.001)
    }

    func testTimesOutWithNoReadingWhenTheCountNeverAppears() {
        XCTAssertEqual(wait(for: 0, readings: [nil]), .timedOut(lastSeen: nil))
    }
}
