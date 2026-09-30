//
//  LockedTests.swift
//  CucumberSwiftTests
//
//  Coverage for issue #219: the shared stores of setup problems can be written from several threads at
//  once without losing or duplicating an entry.
//

import Foundation
import XCTest
@testable import CucumberSwift

class LockedTests: XCTestCase {
    private let iterations = 1_000

    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testConcurrentAppendsAreAllKept() {
        let locked = Locked([Int]())

        DispatchQueue.concurrentPerform(iterations: iterations) { locked.append($0) }

        XCTAssertEqual(locked.snapshot.sorted(), Array(0..<iterations))
    }

    func testConcurrentAppendIfAbsentKeepsOneCopy() {
        let locked = Locked([String]())

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in locked.appendIfAbsent("same") }

        XCTAssertEqual(locked.snapshot, ["same"])
    }

    func testRemoveAllEmptiesTheCollection() {
        let locked = Locked([1, 2, 3])

        locked.removeAll()

        XCTAssertEqual(locked.snapshot, [])
    }

    func testGherkinErrorsKeepEveryConcurrentAppend() {
        DispatchQueue.concurrentPerform(iterations: iterations) { Gherkin.errors.append("error \($0)") }

        XCTAssertEqual(Set(Gherkin.errors.snapshot), Set((0..<iterations).map { "error \($0)" }))
    }

    // `ExecuteFirstStep` can be called from any thread, and matching a regex step definition records a
    // pattern that will not compile. Each pattern is recorded once, however many threads find it.
    func testAnInvalidPatternMatchedConcurrentlyIsRecordedOnce() {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in _ = "text".matches(for: "^(unclosed$") }

        XCTAssertEqual(RegularExpression.errors.snapshot.filter { $0.message.contains("^(unclosed$") }.count, 1)
    }

    func testConcurrentRegistrationsReportEveryDuplicate() {
        DispatchQueue.concurrentPerform(iterations: iterations) {
            DuplicateStepDefinition.register(pattern: "^the same step$", keyword: .given, file: #filePath, line: $0)
        }

        XCTAssertEqual(DuplicateStepDefinition.errors.count, iterations - 1, "Every registration after the first repeats it")
    }
}
