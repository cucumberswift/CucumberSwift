/// Walks Swift source and blanks its comments. It tracks string and regex literals, so `//` or `/*`
/// inside one isn't a comment, and nested block comments and string interpolations.
struct CommentScanner {
    private static let slash = code("/")
    private static let star = code("*")
    private static let hash = code("#")
    private static let quote = code("\"")
    private static let backslash = code("\\")
    private static let open = code("(")
    private static let close = code(")")
    private static let newline = code("\n")
    private static let carriageReturn = code("\r")
    private static let space = code(" ")
    private static let tab = code("\t")
    // A bare `/…/` regex literal can follow these, where a `/` can't be division.
    private static let beforeBareRegex = Set("(,=[:{;!&|?^~".utf16)

    var units: [UInt16]
    private var index = 0

    private static func code(_ scalar: Unicode.Scalar) -> UInt16 { UInt16(scalar.value) }

    init(units: [UInt16]) {
        self.units = units
    }

    private func unit(at offset: Int) -> UInt16? {
        offset < units.count ? units[offset] : nil
    }

    /// Scans code until the end, or with `inInterpolation`, until the `)` that closes it.
    mutating func scanCode(inInterpolation: Bool = false) {
        var depth = 0
        while index < units.count {
            let current = units[index]
            switch current {
                case Self.slash where unit(at: index + 1) == Self.slash:
                    blankLineComment()
                case Self.slash where unit(at: index + 1) == Self.star:
                    blankBlockComment()
                case Self.slash where startsBareRegex():
                    skipBareRegex()
                case Self.hash, Self.quote:
                    var hashes = 0
                    while unit(at: index + hashes) == Self.hash { hashes += 1 }
                    if unit(at: index + hashes) == Self.quote {
                        index += hashes
                        skipString(hashes: hashes)
                    } else if hashes > 0 && unit(at: index + hashes) == Self.slash {
                        index += hashes
                        skipExtendedRegex(hashes: hashes)
                    } else {
                        index += max(hashes, 1)
                    }
                case Self.backslash:
                    // A key path, or an escape in a bare regex literal: never the start of anything.
                    index += 2
                case Self.open:
                    depth += 1
                    index += 1
                case Self.close:
                    index += 1
                    if depth == 0 && inInterpolation { return }
                    depth -= 1
                default:
                    index += 1
            }
        }
    }

    private mutating func blankLineComment() {
        while index < units.count && units[index] != Self.newline && units[index] != Self.carriageReturn {
            units[index] = Self.space
            index += 1
        }
    }

    private mutating func blankBlockComment() {
        var depth = 0
        while index < units.count {
            if units[index] == Self.slash && unit(at: index + 1) == Self.star {
                depth += 1
                blank(2)
            } else if units[index] == Self.star && unit(at: index + 1) == Self.slash {
                depth -= 1
                blank(2)
                if depth == 0 { return }
            } else {
                blank(1)
            }
        }
    }

    /// Blanks `count` units from `index`, keeping line breaks.
    private mutating func blank(_ count: Int) {
        for _ in 0..<count where index < units.count {
            if units[index] != Self.newline && units[index] != Self.carriageReturn { units[index] = Self.space }
            index += 1
        }
    }

    /// Whether the `/` at `index` starts a bare regex literal rather than being division: it follows
    /// an opening bracket, a comma or an operator, isn't followed by a space, and closes on its line.
    private func startsBareRegex() -> Bool {
        var previous = index - 1
        while previous >= 0 && (units[previous] == Self.space || units[previous] == Self.tab) { previous -= 1 }
        guard previous < 0 || Self.beforeBareRegex.contains(units[previous]) || units[previous] == Self.newline,
              let next = unit(at: index + 1), next != Self.space, next != Self.tab else { return false }
        return bareRegexEnd() != nil
    }

    /// The offset of the `/` that closes the bare regex literal starting at `index`, on the same line.
    private func bareRegexEnd() -> Int? {
        var offset = index + 1
        while let current = unit(at: offset), current != Self.newline, current != Self.carriageReturn {
            if current == Self.backslash {
                offset += 2
            } else if current == Self.slash {
                return offset
            } else {
                offset += 1
            }
        }
        return nil
    }

    private mutating func skipBareRegex() {
        index = (bareRegexEnd() ?? index) + 1
    }

    /// Skips `#/…/#` (with `hashes` `#`s), from its `/`. It may span lines.
    private mutating func skipExtendedRegex(hashes: Int) {
        index += 1
        while index < units.count {
            if units[index] == Self.backslash {
                index += 2
            } else if units[index] == Self.slash && hasHashes(hashes, at: index + 1) {
                index += 1 + hashes
                return
            } else {
                index += 1
            }
        }
    }

    /// Skips a string literal from its opening quote: single-line or `"""`, raw with `hashes` `#`s,
    /// and scans each interpolation in it as code.
    private mutating func skipString(hashes: Int) {
        let isMultiLine = unit(at: index + 1) == Self.quote && unit(at: index + 2) == Self.quote
        index += isMultiLine ? 3 : 1
        while index < units.count {
            let current = units[index]
            if current == Self.backslash && hasHashes(hashes, at: index + 1) {
                index += 1 + hashes
                if unit(at: index) == Self.open {
                    index += 1
                    scanCode(inInterpolation: true)
                } else {
                    index += 1
                }
            } else if current == Self.quote && isMultiLine {
                if unit(at: index + 1) == Self.quote && unit(at: index + 2) == Self.quote && hasHashes(hashes, at: index + 3) {
                    index += 3 + hashes
                    return
                }
                index += 1
            } else if current == Self.quote && hasHashes(hashes, at: index + 1) {
                index += 1 + hashes
                return
            } else if !isMultiLine && (current == Self.newline || current == Self.carriageReturn) {
                // An unterminated string: go back to reading code.
                return
            } else {
                index += 1
            }
        }
    }

    private func hasHashes(_ count: Int, at offset: Int) -> Bool {
        (0..<count).allSatisfy { unit(at: offset + $0) == Self.hash }
    }
}

extension String {
    /// This Swift source with every comment replaced by spaces, so a step definition in a comment
    /// isn't read. Line breaks and UTF-16 offsets stay where they were, so line numbers still agree.
    var blankingComments: String {
        var scanner = CommentScanner(units: Array(utf16))
        scanner.scanCode()
        return String(decoding: scanner.units, as: UTF16.self)
    }
}
