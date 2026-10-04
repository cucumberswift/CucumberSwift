//
//  Locked.swift
//  CucumberSwift
//

import Foundation

/// A value that several threads can share. Every access holds one lock, so a compound change, such as
/// appending an element unless it is already there, is atomic. `Mutex` would do this, but needs iOS 18.
final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    /// A copy of the value. It does not change when the value does, so read it once and work on the copy.
    var snapshot: Value {
        withLock { $0 }
    }

    init(_ value: Value) {
        self.value = value
    }

    func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}

extension Locked where Value: RangeReplaceableCollection {
    func append(_ element: Value.Element) {
        withLock { $0.append(element) }
    }

    func removeAll() {
        withLock { $0.removeAll() }
    }
}

extension Locked where Value: RangeReplaceableCollection, Value.Element: Equatable {
    /// Appends `element` unless the collection already contains it.
    func appendIfAbsent(_ element: Value.Element) {
        withLock {
            if !$0.contains(element) {
                $0.append(element)
            }
        }
    }
}
