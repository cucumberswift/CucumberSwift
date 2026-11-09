//
//  Calculator.swift
//  Calculator
//
//  The code under test.
//

public final class Calculator {
    public private(set) var display = "0"
    private var memory: Int?

    private static func name(of number: Int) -> String {
        number < 0 ? "minus \(-number)" : "\(number)"
    }

    public init() {
        // A new calculator shows 0 and has no memory.
    }

    public func add(_ first: Int, _ second: Int) {
        display = Self.name(of: first + second)
    }

    public func divide(_ dividend: Int, by divisor: Int) {
        guard divisor != 0 else {
            display = "error"
            return
        }
        display = Self.name(of: dividend / divisor)
    }

    public func classify(_ number: Int) {
        if number < 10 {
            display = "small"
        } else if number < 100 {
            display = "medium"
        } else {
            display = "large"
        }
    }

    public func readMemory() {
        openMemory()
        display = Self.name(of: memory ?? 0)
    }

    public func clearMemory() {
        openMemory()
        memory = 0
        display = Self.name(of: 0)
    }

    private func openMemory() {
        if memory == nil {
            memory = 0
        }
    }
}
