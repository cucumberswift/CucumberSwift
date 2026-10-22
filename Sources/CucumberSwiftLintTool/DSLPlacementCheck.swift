import Foundation

/// Keeps the two ways of writing steps apart, as the DSL macros do when they compile, for code written with the
/// functions too: a step definition, such as `Given("I do X") { _, _ in }`, which matches a feature file's step,
/// doesn't belong in a feature written in the Swift DSL; a DSL step, such as `Given(I: doX())`, which is the code it
/// runs, doesn't belong outside one. Both are errors, which fail the build.
///
/// Read from the text, so a DSL step is only recognized by its label, `I:`, `it:`, `my:`, `some:`, `a:` or `the:`:
/// without one, `Given(doX())`, it can't be told from a step definition whose pattern is a variable.
enum DSLPlacementCheck {
    static let stepDefinitionInFeature = "A step definition belongs in setupSteps(), outside a feature written in the Swift DSL. "
        + "Inside a scenario, write a DSL step, such as Given(I: doSomething())."
    static let stepOutsideScenario = "A DSL step belongs inside a Scenario, Background or ScenarioOutline. "
        + "To match a step of a feature file, write a step definition, such as Given(\"I do something\") { _, _ in }."

    /// The DSL's containers, whose contents are a feature's: English, and in every language, such as `ES_Escenario`.
    static let containerNames = ["Feature", "Scenario", "ScenarioOutline", "Background", "Rule"] + localizedContainerNames
    static let labels = ["I", "it", "my", "some", "a", "the"]

    private static let names = StepDefinition.names.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
    /// `Feature(`, `#Scenario(`, `Background {` and the rest, at the start of a name.
    private static let container = compile(
        #"(?<![\w.])#?(?:"# + containerNames.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|") + #")\s*[({]"#)
    /// A function or property whose body builds a scenario's steps or a feature's scenarios.
    private static let builder = compile(#"@(?:StepBuilder|ScenarioBuilder)\b"#)
    /// A step definition: a step's name, then a string or regex literal.
    private static let stepDefinition = compile(#"(?<![\w.])#?(?:"# + names + #")\s*\(\s*(?:"|#/|/)"#)
    /// A DSL step with a label: `Given(I:` and the rest.
    private static let dslStep = compile(#"(?<![\w.])#?(?:"# + names + #")\s*\(\s*(?:"# + labels.joined(separator: "|") + #")\s*:"#)

    /// Reports each step written where the other kind belongs, in a Swift file whose comments are blanked.
    static func check(file: String, source: String, report: (Diagnostic) -> Void) {
        let code = Array(source.blankingLiterals.utf16)
        let text = String(decoding: code, as: UTF16.self)
        let fullRange = NSRange(location: 0, length: code.count)
        var regions = [Range<Int>]()
        for match in container.matches(in: text, range: fullRange) {
            regions.append(match.range.location..<extent(ofCallAt: match.range.location + match.range.length - 1, in: code))
        }
        for match in builder.matches(in: text, range: fullRange) {
            guard let open = code[(match.range.location + match.range.length)...].firstIndex(of: UInt16(UInt8(ascii: "{"))) else { continue }
            regions.append(match.range.location..<closing(from: open, in: code))
        }
        let lineStarts = source.lineStartOffsets
        func inRegion(_ offset: Int) -> Bool { regions.contains { $0.contains(offset) } }
        // The definitions are found in the source, whose literals they start with, and the DSL steps in the code.
        for match in stepDefinition.matches(in: source, range: NSRange(location: 0, length: source.utf16.count))
            where inRegion(match.range.location) {
            report(Diagnostic(file: file,
                              line: lineStarts.line(containing: match.range.location),
                              message: stepDefinitionInFeature,
                              severity: .error))
        }
        for match in dslStep.matches(in: text, range: fullRange) where !inRegion(match.range.location) {
            report(Diagnostic(file: file,
                              line: lineStarts.line(containing: match.range.location),
                              message: stepOutsideScenario,
                              severity: .error))
        }
    }

    /// Where a container's call ends: after its parentheses, if it has them, and its trailing closures. `last` is the
    /// call's first `(` or `{`.
    private static func extent(ofCallAt last: Int, in code: [UInt16]) -> Int {
        var end = last
        if code[end] == UInt16(UInt8(ascii: "(")) {
            end = closing(from: end, in: code)
        }
        while true {
            var next = end
            while next < code.count, [9, 10, 13, 32].contains(code[next]) { next += 1 }
            guard next < code.count, code[next] == UInt16(UInt8(ascii: "{")) else { return end }
            end = closing(from: next, in: code)
        }
    }

    /// The offset just after the bracket that closes the one at `open`, or the end of the code.
    private static func closing(from open: Int, in code: [UInt16]) -> Int {
        let pairs: [UInt16: UInt16] = [40: 41, 123: 125, 91: 93]
        var depth = 0
        var index = open
        while index < code.count {
            let unit = code[index]
            if pairs.keys.contains(unit) {
                depth += 1
            } else if pairs.values.contains(unit) {
                depth -= 1
                if depth == 0 { return index + 1 }
            }
            index += 1
        }
        return code.count
    }

    private static func compile(_ pattern: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern)
    }
}

extension String {
    /// The text with each string and regex literal's contents blanked, so that brackets in them don't count.
    /// Comments are blanked already. Its UTF-16 offsets are the original's.
    var blankingLiterals: String {
        var units = Array(utf16)
        var index = 0
        func isQuote(_ offset: Int) -> Bool { offset < units.count && units[offset] == 34 }
        while index < units.count {
            // `#"…"#`, `##"…"##` and `#/…/#`: count the leading `#`s.
            var hashes = 0
            while index + hashes < units.count, units[index + hashes] == 35 { hashes += 1 }
            let start = index + hashes
            guard start < units.count, units[start] == 34 || (hashes > 0 && units[start] == 47) else {
                index += max(hashes, 1)
                continue
            }
            let isRegex = units[start] == 47
            let isMultiline = !isRegex && isQuote(start + 1) && isQuote(start + 2)
            let delimiter: [UInt16] = (isRegex ? [47] : isMultiline ? [34, 34, 34] : [34]) + Array(repeating: 35, count: hashes)
            var position = start + (isMultiline ? 3 : 1)
            while position < units.count {
                if hashes == 0, !isRegex, units[position] == 92 {
                    position += 2
                    continue
                }
                if position + delimiter.count <= units.count, Array(units[position..<position + delimiter.count]) == delimiter {
                    break
                }
                if !isMultiline, !isRegex, units[position] == 10 { break }
                units[position] = 32
                position += 1
            }
            index = min(position + delimiter.count, units.count)
        }
        return String(decoding: units, as: UTF16.self)
    }
}
