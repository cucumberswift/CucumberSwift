import Foundation

/// Checks one `.feature` file, line by line, for the mistakes that otherwise only show up when the
/// tests run: text where a step should be, a misspelt keyword, a table with uneven rows, an
/// unclosed doc string, and (when `definitions` is not nil) steps that no step definition matches.
final class FeatureChecker {
    private enum Section { case none, feature, rule, background, scenario, outline, examples }

    private struct PendingStep {
        let line: Int
        let column: Int
        let text: String
    }

    private static let stepKeywords = ["Given", "When", "Then", "And", "But"]
    private static let headers = [
        "Feature", "Rule", "Background", "Scenario Outline", "Scenario Template",
        "Scenario", "Example", "Examples", "Scenarios"
    ]
    // Words that start descriptions and are one letter away from a keyword.
    private static let commonWords: Set = ["they", "them", "than", "thus", "went", "whom"]

    let file: String
    let definitions: [StepDefinition]?

    private var report: (Diagnostic) -> Void = { _ in }
    private var english = true
    private var section = Section.none
    private var sawStep = false
    private var tableAllowed = false
    private var docString: (delimiter: String, line: Int)?
    private var table: (cells: Int, line: Int)?
    // A scenario's steps are checked at its end, against its Examples if it has any.
    private var pendingSteps = [PendingStep]()
    private var exampleHeader: [String]?
    private var exampleRows = [[String: String]]()

    init(file: String, definitions: [StepDefinition]?) {
        self.file = file
        self.definitions = definitions
    }

    func check(report: @escaping (Diagnostic) -> Void) {
        guard let contents = try? String(contentsOfFile: file, encoding: .utf8) else { return }
        self.report = report
        let lines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        for (index, raw) in lines.enumerated() {
            let text = raw.trimmingCharacters(in: .whitespaces)
            let column = raw.prefix { $0 == " " || $0 == "\t" }.count + 1
            check(text, line: index + 1, column: column)
        }
        if let open = docString {
            warn(open.line, 1, "This doc string is never closed")
        }
        finishScenario()
    }

    private func check(_ text: String, line: Int, column: Int) {
        if let open = docString {
            if text.hasPrefix(open.delimiter) { docString = nil }
        } else if text.isEmpty {
            table = nil
        } else if text.hasPrefix("#") {
            checkComment(text)
        } else if text.hasPrefix("\"\"\"") || text.hasPrefix("```") {
            checkDocStringStart(text, line: line, column: column)
        } else if text.hasPrefix("|") {
            checkTableRow(text, line: line, column: column)
        } else {
            table = nil
            guard !text.hasPrefix("@"), english else { return }
            if let header = Self.headers.first(where: { text.hasPrefix($0 + ":") }) {
                checkHeader(header, line: line, column: column)
            } else if let keyword = Self.stepKeyword(of: text) {
                checkStep(String(text.dropFirst(keyword.count)), line: line, column: column)
            } else {
                checkOtherText(text, line: line, column: column)
            }
        }
    }

    private func checkComment(_ text: String) {
        let comment = text.dropFirst().trimmingCharacters(in: .whitespaces)
        guard comment.hasPrefix("language:") else { return }
        english = comment.dropFirst("language:".count).trimmingCharacters(in: .whitespaces) == "en"
    }

    private func checkDocStringStart(_ text: String, line: Int, column: Int) {
        if !tableAllowed || section == .examples {
            warn(line, column, "A doc string must follow a step")
        }
        docString = (String(text.prefix(3)), line)
        tableAllowed = false
    }

    private func checkTableRow(_ text: String, line: Int, column: Int) {
        let cells = Self.cells(text)
        if !tableAllowed {
            warn(line, column, "A table must follow a step or an Examples line")
        } else if let first = table, first.cells != cells.count {
            warn(line, column, "This row has \(cells.count) cells, but the table's first row (line \(first.line)) has \(first.cells)")
        } else if table == nil {
            table = (cells.count, line)
        }
        guard section == .examples else { return }
        if let header = exampleHeader {
            exampleRows.append(Dictionary(zip(header, cells)) { first, _ in first })
        } else {
            exampleHeader = cells
        }
    }

    private func checkHeader(_ header: String, line: Int, column: Int) {
        switch header {
            case "Feature": section = .feature
            case "Rule": section = .rule
            case "Background": section = .background
            case "Scenario Outline", "Scenario Template": section = .outline
            case "Examples", "Scenarios":
                // Gherkin also allows Examples under a plain Scenario.
                if ![.scenario, .outline, .examples].contains(section) {
                    warn(line, column, "Examples belong to a Scenario Outline")
                }
                section = .examples
                exampleHeader = nil
            default: section = .scenario
        }
        if section != .examples { finishScenario() }
        sawStep = false
        tableAllowed = section == .examples
    }

    private func checkStep(_ text: String, line: Int, column: Int) {
        switch section {
            case .none, .feature, .rule:
                warn(line, column, "A step must be inside a Scenario or Background")
            case .examples:
                warn(line, column, "A step can't follow Examples; start a new Scenario")
            case .background, .scenario, .outline: break
        }
        let step = PendingStep(line: line, column: column, text: text.trimmingCharacters(in: .whitespaces))
        if section == .scenario || section == .outline {
            pendingSteps.append(step)
        } else if section == .background {
            // A misplaced step has been reported already, and has no examples to fill it in.
            checkDefined(step, examples: [])
        }
        sawStep = true
        tableAllowed = true
    }

    private func checkOtherText(_ text: String, line: Int, column: Int) {
        // Examples may have a description before their table.
        tableAllowed = section == .examples && exampleHeader == nil
        let firstWord = String(text.prefix { !$0.isWhitespace && $0 != ":" })
        let suggestion = Self.suggestion(for: firstWord, strict: !sawStep)
        if sawStep, [.background, .scenario, .outline].contains(section) {
            let hint = suggestion.map { " Did you mean '\($0)'?" } ?? ""
            warn(line, column, "Expected a step (Given, When, Then, And, But), a table or a doc string.\(hint)")
        } else if let suggestion = suggestion {
            warn(line, column, "'\(firstWord)' is not a Gherkin keyword. Did you mean '\(suggestion)'?")
            // Read a header that is only missing its colon as that header, so the lines after it
            // aren't reported too.
            if suggestion == firstWord + ":" {
                checkHeader(firstWord, line: line, column: column)
            }
        }
    }

    private func finishScenario() {
        for step in pendingSteps {
            checkDefined(step, examples: exampleRows)
        }
        pendingSteps = []
        exampleHeader = nil
        exampleRows = []
    }

    private func checkDefined(_ step: PendingStep, examples: [[String: String]]) {
        guard let definitions = definitions else { return }
        let candidates = examples.isEmpty ? [step.text] : examples.map { row in
            row.reduce(step.text) { $0.replacingOccurrences(of: "<\($1.key)>", with: $1.value) }
        }
        let defined = candidates.contains { candidate in definitions.contains { $0.matches(candidate) } }
        if !defined {
            warn(step.line, step.column, "Undefined step: no step definition matches \"\(candidates[0])\"")
        }
    }

    private func warn(_ line: Int, _ column: Int, _ message: String) {
        report(.init(file: file, line: line, column: column, message: message))
    }
}

extension FeatureChecker {
    private static func stepKeyword(of text: String) -> String? {
        if text.hasPrefix("* ") { return "*" }
        return stepKeywords.first { text.hasPrefix($0 + " ") }
    }

    private static func cells(_ row: String) -> [String] {
        var cells = [String]()
        var cell = ""
        var escaped = false
        for character in row.dropFirst() {
            if escaped {
                cell.append(character)
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "|" {
                cells.append(cell.trimmingCharacters(in: .whitespaces))
                cell = ""
            } else {
                cell.append(character)
            }
        }
        return cells
    }

    /// A keyword that `word` looks like a misspelling of. Before the first step of a scenario, text
    /// is a description, so `strict` only suggests one for a near miss that isn't a common word.
    private static func suggestion(for word: String, strict: Bool) -> String? {
        let lowered = word.lowercased()
        guard lowered.count >= 3, !commonWords.contains(lowered) else { return nil }
        for candidate in stepKeywords + ["Feature:", "Background:", "Scenario:", "Examples:"] {
            let bare = candidate.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            if bare == word { return candidate } // "Scenario Foo", missing its colon
            let distance = editDistance(lowered, bare.lowercased())
            if distance == 0 || (distance == 1 && (!strict || lowered.count >= 4)) {
                return candidate
            }
        }
        return nil
    }

    /// Optimal string alignment distance: insertions, deletions, substitutions and swaps.
    private static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var d = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { d[i][0] = i }
        for j in 0...b.count { d[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                d[i][j] = Swift.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    d[i][j] = Swift.min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        return d[a.count][b.count]
    }
}
