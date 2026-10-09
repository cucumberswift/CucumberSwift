//
//  RegexLiteralPattern.swift
//  CucumberSwiftMacrosPlugin
//

import Foundation

/// What a regex literal captures, in order, read from its syntax. CucumberSwiftMacroConverterTool shares this
/// file through a symlink, to give a converted closure the arguments the macro takes.
///
/// The compiler, not the macro, knows a regex literal's `Output`, and the expansion leaves the type check to
/// it. This reading is for the macro's own diagnostics and fix-its, so it only claims to know the captures
/// (`isCertain`) when ICU's reading of the same pattern finds as many. Otherwise the macro says nothing
/// and the compiler's check stands alone.
struct RegexLiteralPattern {
    /// One capture group, which gives the closure one argument.
    struct Capture: Equatable {
        /// The group's name, for `(?<name>…)`, `(?'name'…)` and `(?P<name>…)`.
        let name: String?
        /// Whether the group may match nothing, which makes its output optional: it is in an alternation,
        /// or in a group that may repeat zero times.
        var isOptional: Bool

        /// The capture's type in the regex's `Output`.
        var type: String { isOptional ? "Substring?" : "Substring" }
    }

    /// Reads the groups. Anything that changes how groups are numbered or what captures, such as
    /// branch reset `(?|…)`, the `n` and `x` options, conditionals and recursion, is left to the compiler.
    private struct Scanner {
        /// A group being read.
        private struct Group {
            /// The index in `captures` of the group's own capture, if it captures.
            let capture: Int?
            /// The index in `captures` of the first capture inside it.
            let firstInside: Int
            var hasAlternation = false
        }

        private let characters: [Character]
        private let isExtended: Bool
        private var index = 0
        private var captures = [Capture]()
        private var groups = [Group]()
        private var hasAlternationOutside = false

        init(_ characters: [Character], isExtended: Bool) {
            self.characters = characters
            self.isExtended = isExtended
        }

        /// The captures, or `nil` if the pattern has syntax this doesn't read.
        mutating func read() -> [Capture]? {
            while index < characters.count {
                let character = characters[index]
                index += 1
                switch character {
                    case "\\":
                        skipEscape()
                    case "[":
                        guard skipCharacterClass() else { return nil }
                    case "(":
                        guard openGroup() else { return nil }
                    case ")":
                        guard let group = groups.popLast() else { return nil }
                        if group.hasAlternation { makeOptional(from: group.firstInside) }
                        if allowsZeroRepetitions() { makeOptional(from: group.capture ?? group.firstInside) }
                    case "|":
                        if groups.isEmpty { hasAlternationOutside = true } else { groups[groups.count - 1].hasAlternation = true }
                    case "#" where isExtended:
                        while index < characters.count, !characters[index].isNewline { index += 1 }
                    default:
                        break
                }
            }
            guard groups.isEmpty else { return nil }
            if hasAlternationOutside { makeOptional(from: 0) }
            return captures
        }

        private mutating func makeOptional(from first: Int) {
            for capture in first..<captures.count { captures[capture].isOptional = true }
        }

        private func hasPrefix(_ prefix: String) -> Bool {
            characters[index...].starts(with: prefix)
        }

        /// After a `\`: skips the escaped character, or a `\Q…\E` quote.
        private mutating func skipEscape() {
            guard index < characters.count else { return }
            if characters[index] == "Q" {
                index += 1
                while index < characters.count, !hasPrefix("\\E") { index += 1 }
                index = min(index + 2, characters.count)
            } else {
                index += 1
            }
        }

        /// After a `[`: skips the class, with nested classes and POSIX classes such as `[:alpha:]`.
        private mutating func skipCharacterClass() -> Bool {
            var depth = 1
            var isAtStart = true
            while index < characters.count {
                let character = characters[index]
                index += 1
                if isAtStart, character == "^" { continue }
                defer { isAtStart = false }
                switch character {
                    case "\\":
                        skipEscape()
                    case "]" where !isAtStart:
                        depth -= 1
                        if depth == 0 { return true }
                    case "[" where hasPrefix(":"):
                        while index < characters.count, !hasPrefix(":]") { index += 1 }
                        guard index < characters.count else { return false }
                        index += 2
                    case "[":
                        depth += 1
                        isAtStart = true
                    default:
                        break
                }
            }
            return false
        }

        /// After a `(`: opens a group, or skips a comment or an option setting. `false` for syntax this doesn't read.
        private mutating func openGroup() -> Bool {
            if hasPrefix("*") { return false }
            guard hasPrefix("?") else { return push(name: nil, captures: true) }
            index += 1
            if hasPrefix("#") {
                guard let end = characters[index...].firstIndex(of: ")") else { return false }
                index = end + 1
                return true
            }
            for opening in [":", "=", "!", ">", "*", "<=", "<!", "<*", "P="] where hasPrefix(opening) {
                index += opening.count
                return push(name: nil, captures: false)
            }
            for (opening, closing) in [("<", ">"), ("'", "'"), ("P<", ">")] where hasPrefix(opening) {
                index += opening.count
                guard let end = characters[index...].firstIndex(of: Character(closing)) else { return false }
                let name = String(characters[index..<end])
                index = end + 1
                return push(name: name, captures: true)
            }
            // Options, such as (?i) or (?i-m:…). `n` and `x` change what captures and what is a comment.
            let options = characters[index...].prefix { $0.isLetter || $0 == "-" || $0 == "^" }
            guard !options.isEmpty, !options.contains("n"), !options.contains("x"),
                  index + options.count < characters.count else { return false }
            index += options.count
            let next = characters[index]
            index += 1
            switch next {
                case ")": return true
                case ":": return push(name: nil, captures: false)
                default: return false
            }
        }

        private mutating func push(name: String?, captures isCapturing: Bool) -> Bool {
            if isCapturing { captures.append(Capture(name: name, isOptional: false)) }
            groups.append(Group(capture: isCapturing ? captures.count - 1 : nil, firstInside: captures.count))
            return true
        }

        /// After a `)`: whether a quantifier follows that allows no repetitions, such as `?`, `*` or `{0,2}`.
        private mutating func allowsZeroRepetitions() -> Bool {
            guard index < characters.count else { return false }
            switch characters[index] {
                case "?", "*":
                    return true
                case "{":
                    let body = characters[(index + 1)...].prefix { $0 != "}" }
                    guard index + 1 + body.count < characters.count else { return false }
                    let bounds = body.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                    guard (1...2).contains(bounds.count), bounds.allSatisfy({ $0.allSatisfy(\.isNumber) }),
                          !bounds.allSatisfy(\.isEmpty) else { return false }
                    return bounds[0].isEmpty || Int(String(bounds[0])) == 0
                default:
                    return false
            }
        }
    }

    let captures: [Capture]
    /// Whether `captures` can be relied on to report a wrong number of arguments.
    let isCertain: Bool

    /// The number of capture groups ICU finds, or `nil` if it can't read the pattern, as for syntax only
    /// Swift has.
    private static func icuCaptureCount(of pattern: String, isExtended: Bool) -> Int? {
        try? NSRegularExpression(pattern: pattern, options: isExtended ? [.allowCommentsAndWhitespace] : [])
            .numberOfCaptureGroups
    }

    /// - Parameters:
    ///   - pattern: The literal's text between its delimiters.
    ///   - isExtended: Whether it is a multi-line literal, whose whitespace and `#` comments are ignored.
    init(_ pattern: String, isExtended: Bool) {
        var scanner = Scanner(Array(pattern), isExtended: isExtended)
        let read = scanner.read()
        captures = read ?? []
        isCertain = read.map { Self.icuCaptureCount(of: pattern, isExtended: isExtended) == $0.count } ?? false
    }
}

extension StepPattern {
    /// A regex literal's captures. Each is read from the regex's `Output`, so `parameter` is only the
    /// capture's name in messages: its group's name, or `anonymous`.
    init(regexCaptures: [RegexLiteralPattern.Capture]) {
        captures = regexCaptures.map { Capture(parameter: $0.name ?? "anonymous", type: $0.type) }
        isRegularExpression = true
    }
}
