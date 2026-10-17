//
//  ScenarioState.swift
//  CucumberSwift
//
// What `Scenario.state(_:)` keeps. This folder is compiled by CucumberSwift and, through a symlink, by
// CucumberSwiftTesting, so both runners keep a scenario's state the same way.

import Foundation

/// A scenario's own values, one for each type that asks for one. A lock guards it, because a step runs on
/// whichever thread XCTest picks, and on the main actor in Swift Testing.
final class ScenarioState: @unchecked Sendable {
    private let lock = NSLock()
    private var values = [ObjectIdentifier: AnyObject]()

    /// The scenario's `Value`, made by `make` the first time it is asked for. `make` runs without the lock
    /// held, so it may ask for the scenario's other state.
    func value<Value: AnyObject>(_ make: () -> Value) -> Value {
        let key = ObjectIdentifier(Value.self)
        if let existing = existingValue(for: key) as? Value { return existing }
        let made = make()
        lock.lock()
        defer { lock.unlock() }
        if let raced = values[key] as? Value { return raced }
        values[key] = made
        return made
    }

    /// Lets go of every value, once the scenario is over.
    func removeAll() {
        lock.lock()
        let old = values
        values = [:]
        lock.unlock()
        withExtendedLifetime(old) {}
    }

    private func existingValue(for key: ObjectIdentifier) -> AnyObject? {
        lock.lock()
        defer { lock.unlock() }
        return values[key]
    }
}
