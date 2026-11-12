//
//  RunnerSupport.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}

final class CopyListing: @unchecked Sendable {
    var names = [String]()
}

/// A runner that runs nothing and counts what the run asks of it.
final class SpyRunner: TestRunner, @unchecked Sendable {
    struct PrepareFailure: Error, CustomStringConvertible {
        let description = "cannot prepare"
    }

    private let prepared: Counter
    private let cleaned: Counter
    private let buildStatus: Bool
    private let testsRun: Int
    private let prepareFails: Bool
    let excludedFromCopy: [String]
    var onPrepare: (URL) -> Void = { _ in }
    private let requestLock = NSLock()
    private var recordedRequests = [TestRequest]()

    /// What each test run was asked to do, in order.
    var requests: [TestRequest] {
        requestLock.lock()
        defer { requestLock.unlock() }
        return recordedRequests
    }

    init(prepared: Counter, cleaned: Counter, buildStatus: Bool = true, testsRun: Int = 3, prepareFails: Bool = false, excluded: [String] = []) {
        self.prepared = prepared
        self.cleaned = cleaned
        self.buildStatus = buildStatus
        self.testsRun = testsRun
        self.prepareFails = prepareFails
        excludedFromCopy = excluded
    }

    func prepare(copy: URL) throws {
        prepared.increment()
        onPrepare(copy)
        if prepareFails { throw PrepareFailure() }
    }

    func build(in _: URL, timeout _: TimeInterval?) -> BuildResult {
        BuildResult(succeeded: buildStatus, duration: 1)
    }

    func test(in _: URL, request: TestRequest) -> TestRun {
        requestLock.lock()
        recordedRequests.append(request)
        requestLock.unlock()
        return TestRun(status: 0, duration: 1, testsRun: testsRun)
    }

    func cleanUp(copy _: URL) {
        cleaned.increment()
    }
}
#endif
