//
//  StepText.swift
//  CucumberSwift
//
// The text of a step written in the Swift DSL with a function, such as `Given(I: logIn())`: read from the
// Swift file at run time, from the step's line and column. It needs the source file, so it finds nothing on a
// device or from an archived test bundle; the DSL step macros, such as `#Given(I: logIn())`, capture the text
// when the tests compile instead. CucumberSwiftTesting has only the macros.

import Foundation

enum DSLStepText {
    private enum StepError: Error {
        case lineOutOfBounds
        case columnOutOfBounds
    }

    /// What is between the parentheses of the call at `line` and `column` of `file`, or `nil` if the file can't
    /// be read.
    static func read(line: UInt, column: UInt, file: StaticString) -> String? {
        try? readStepName(lineNumber: line, column: column, filePath: file)
    }

    private static func readStepName(lineNumber: UInt, column: UInt, filePath: StaticString) throws -> String {
        let fileContents = try String(contentsOfFile: String(describing: filePath), encoding: .utf8)
        let lines = fileContents.components(separatedBy: .newlines)
        let lineIndex = Int(lineNumber - 1)
        let columnIndex = Int(column - 1)

        guard lineIndex + 1 < lines.count else { throw StepError.lineOutOfBounds }

        var line = lines[lineIndex]

        guard columnIndex < line.count else { throw StepError.columnOutOfBounds }

        line.removeFirst(columnIndex)

        line += lines[lineIndex + 1...lines.count - 1].map { $0.trimmingCharacters(in: .whitespacesAndNewlines ) }.joined()

        return readClosureNameFrom(line: line)
    }

    private static func readClosureNameFrom(line: String) -> String {
        var matchedQuote = false

        // overly complex way of matching () to grab the step text
        // ignores strings and docstrings
        // any more complex and I need to pull in a way to look at the Swift AST
        return line.reduce((match: "", openCount: 0, closeCount: 0)) { res, c in
            let char = String(c)
            var (match, openCount, closeCount) = res
            if openCount > 0 && openCount == closeCount { return res }
            if char == "\"" {
                matchedQuote.toggle()
            }
            if char == "(" && !matchedQuote {
                openCount += 1
                guard openCount > 1 else {
                    return (match: match,
                            openCount: openCount,
                            closeCount: closeCount)
                }
            }
            if char == ")" && !matchedQuote { closeCount += 1 }
            if openCount > 0 && openCount == closeCount {
                return (match: match,
                        openCount: openCount,
                        closeCount: closeCount)
            }
            return (match: match + char,
                    openCount: openCount,
                    closeCount: closeCount)
        }.match
    }
}
