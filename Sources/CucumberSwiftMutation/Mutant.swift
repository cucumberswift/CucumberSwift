//
//  Mutant.swift
//  CucumberSwiftMutation
//

import Foundation

/// One small change to the code under test: the text at a place in a file is replaced with another.
public struct Mutant: Codable, Equatable, Sendable {
    public enum ApplyError: Error, Equatable, CustomStringConvertible {
        case outOfRange
        case textChanged(expected: String, found: String)

        public var description: String {
            switch self {
                case .outOfRange: return "the mutant's place is outside the file"
                case .textChanged(let expected, let found):
                    return "the file changed since the mutants were found: expected \"\(expected)\" at the mutant's place, found \"\(found)\""
            }
        }
    }

    public var id: Int
    /// The file, relative to the package folder.
    public let file: String
    /// Where the replaced text starts and ends, 1-based, as an editor shows them.
    public let line: Int
    public let column: Int
    public let endLine: Int
    public let endColumn: Int
    /// Where the replaced text starts, and how long it is, in UTF-8 bytes of the file.
    public let offset: Int
    public let length: Int
    public let original: String
    public let replacement: String
    /// The rule that made it, such as `RelationalOperator`.
    public let mutator: String
    /// The text after the ignore marker when a comment marks this line, `""` for a marker with no text, or nil.
    public var ignoredReason: String?

    /// `Sources/Voting.swift:1:41 RelationalBoundary >= → >`
    public var summary: String {
        "\(file):\(line):\(column) \(mutator) \(original) → \(replacement.isEmpty ? "(removed)" : replacement)"
    }

    public init(
        id: Int,
        file: String,
        line: Int,
        column: Int,
        endLine: Int,
        endColumn: Int,
        offset: Int,
        length: Int,
        original: String,
        replacement: String,
        mutator: String
    ) {
        self.id = id
        self.file = file
        self.line = line
        self.column = column
        self.endLine = endLine
        self.endColumn = endColumn
        self.offset = offset
        self.length = length
        self.original = original
        self.replacement = replacement
        self.mutator = mutator
    }

    /// The same mutant with another number, as the run numbers them in order.
    public func numbered(_ id: Int) -> Mutant {
        var copy = self
        copy.id = id
        return copy
    }

    /// `source` with the replacement in place of the original text. Throws, and changes nothing, when the
    /// text at the mutant's place is not the original, because the file is no longer the one the mutant
    /// was found in.
    public func applied(to source: String) throws -> String {
        var bytes = Array(source.utf8)
        guard offset >= 0, length >= 0, offset + length <= bytes.count else { throw ApplyError.outOfRange }
        let found = String(bytes: bytes[offset..<offset + length], encoding: .utf8) ?? ""
        guard found == original else { throw ApplyError.textChanged(expected: original, found: found) }
        bytes.replaceSubrange(offset..<offset + length, with: Array(replacement.utf8))
        return String(bytes: bytes, encoding: .utf8) ?? source
    }
}
