//
//  TestNames.swift
//  CucumberSwift
//
// How a generated test is named after a feature, scenario or step. This folder is compiled by CucumberSwift
// and, through a symlink, by CucumberSwiftTesting, so a suite moved between the runners keeps its test names.

import Foundation

enum TestNames {
    /// With readable test names, a scenario's test reads `Checkout › Pay with a gift card`.
    static let readableDelimiter = " \u{203A} "

    /// A feature's, scenario's or step's text as it appears in the name of a generated test: as written
    /// with `readable`, and otherwise in camel case.
    static func name(_ text: String, readable: Bool) -> String {
        guard readable else { return text.toClassString() }
        return String(text.filter { !$0.isNewline }.map(readableCharacter)).trimmingCharacters(in: .whitespaces)
    }

    /// XCTest separates a test's class from its method with "/", and Xcode shows only what follows the
    /// last "." of a class name, as it would for a module, so a readable name can contain neither. A one
    /// dot leader (U+2024) looks like a full stop.
    private static func readableCharacter(_ character: Character) -> Character {
        switch character {
            case "/": return "-"
            case ".": return "\u{2024}"
            default: return character
        }
    }

    /// The name of the test for the step at `index` of a scenario's `count` steps. A test runner may order a
    /// scenario's tests by name, so the name starts with the step's zero-padded position to keep that
    /// order the same as the feature file's: `Step002_ThenTheTotalIs99`, or with readable test names,
    /// `3 › Then the total is 99`.
    static func stepName(for text: String, at index: Int, of count: Int, readable: Bool) -> String {
        guard readable else {
            let position = String(format: "%0*d", max(3, String(count - 1).count), index)
            return "Step\(position)_" + name(text, readable: false)
        }
        let position = String(format: "%0*d", String(count).count, index + 1)
        return "\(position)\(readableDelimiter)" + name(text, readable: true)
    }

    /// The text a step's test is named after: the keyword as written with readable test names, and
    /// otherwise the keyword it counts as, so that camel-case names keep the ones tests already have.
    static func stepText(writtenKeyword: String, keywordText: String, match: String, readable: Bool) -> String {
        "\(readable ? writtenKeyword : keywordText) \(match)"
    }
}
