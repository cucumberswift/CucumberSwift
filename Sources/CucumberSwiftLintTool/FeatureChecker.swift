import CucumberSwiftGherkin
import Foundation

/// Checks one `.feature` file, line by line, for the mistakes that otherwise only show up when the
/// tests run: text where a step should be, a misspelt keyword, a table with uneven rows, an
/// unclosed doc string, and (when `definitions` is not nil) steps that no step definition matches.
/// Keywords are only checked in English; the rest is checked in every language CucumberSwift reads.
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

    private var report: ((Diagnostic) -> Void)?
    // The keywords of a file in another language than English, as CucumberSwift reads them.
    private var keywords: FeatureFile.Keywords?
    private var section = Section.none
    private var sawStep = false
    private var tableAllowed = false
    private var docString: (delimiter: String, line: Int)?
    private var table: (cells: Int, line: Int)?
    // A scenario's steps are checked at its end, against its Examples if it has any.
    private var pendingSteps = [PendingStep]()
    private var exampleHeader: [String]?
    private var exampleRows = [[String: String]]()
    // Every line, trimmed, to look ahead from a line that may be a description.
    private var lines = [String]()

    init(file: String, definitions: [StepDefinition]?) {
        self.file = file
        self.definitions = definitions
    }

    func check(report: @escaping (Diagnostic) -> Void) {
        guard let contents = try? String(contentsOfFile: file, encoding: .utf8) else { return }
        check(contents: contents, report: report)
    }

    /// Checks `contents` as the text of `file`.
    func check(contents: String, report: @escaping (Diagnostic) -> Void) {
        self.report = report
        let rawLines = contents.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        lines = rawLines.map { $0.trimmingCharacters(in: .whitespaces) }
        for (index, raw) in rawLines.enumerated() {
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
            checkComment(text, line: line, column: column)
        } else if text.hasPrefix("\"\"\"") || text.hasPrefix("```") {
            checkDocStringStart(text, line: line, column: column)
        } else if text.hasPrefix("|") {
            checkTableRow(text, line: line, column: column)
        } else {
            table = nil
            guard !text.hasPrefix("@") else { return }
            if let keywords = keywords {
                checkLine(text, keywords: keywords, line: line, column: column)
            } else if let header = Self.headers.first(where: { text.hasPrefix($0 + ":") }) {
                checkHeader(header, line: line, column: column)
            } else if let keyword = Self.stepKeyword(of: text) {
                checkStep(String(text.dropFirst(keyword.count)), line: line, column: column)
            } else {
                checkOtherText(text, line: line, column: column)
            }
        }
    }

    /// A `# language:` comment sets the language from its line on, as in CucumberSwift. A language
    /// CucumberSwift doesn't support leaves the language as it was.
    private func checkComment(_ text: String, line: Int, column: Int) {
        let comment = text.dropFirst().trimmingCharacters(in: .whitespaces)
        guard comment.hasPrefix("language") else { return }
        let rest = comment.dropFirst("language".count).trimmingCharacters(in: .whitespaces)
        guard rest.hasPrefix(":") else { return }
        let code = rest.dropFirst().trimmingCharacters(in: .whitespaces)
        if code == "en" {
            keywords = nil
        } else if let language = FeatureFile.Keywords(language: code) {
            keywords = language
        } else {
            warn(line, column, "CucumberSwift doesn't support the language '\(code)'")
        }
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

    /// A line in another language than English. Its headers and steps are checked as in English, but
    /// keywords aren't, so other text is never reported.
    private func checkLine(_ text: String, keywords: FeatureFile.Keywords, line: Int, column: Int) {
        switch keywords.line(text, inScenario: [.scenario, .outline, .examples].contains(section)) {
            case .feature: checkHeader("Feature", line: line, column: column)
            case .rule: checkHeader("Rule", line: line, column: column)
            case .background: checkHeader("Background", line: line, column: column)
            case .scenario: checkHeader("Scenario", line: line, column: column)
            case .scenarioOutline: checkHeader("Scenario Outline", line: line, column: column)
            case .examples: checkHeader("Examples", line: line, column: column)
            case .step(let keyword): checkStep(String(text.dropFirst(keyword.count)), line: line, column: column)
            // Examples may have a description before their table.
            case nil: tableAllowed = section == .examples && exampleHeader == nil
        }
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
        // A header of more than one word is matched whole, so "Scenaro Outline" isn't "Scenario: Outline",
        // unless the line starts with another header as it is written: "Scenarios Outline" is Scenarios.
        let exact = Self.headerWithoutColon(in: text)
        var multiWord = Self.multiWordHeader(in: text)
        if let exact = exact, multiWord?.header.hasPrefix(exact) == false { multiWord = nil }
        let header = multiWord?.header ?? exact
        let written = multiWord?.written ?? header.map { String(text.prefix($0.count)) }
            ?? String(text.prefix { !$0.isWhitespace && $0 != ":" })
        let inScenario = [.background, .scenario, .outline].contains(section)
        // A description line directly above a step, a table or a doc string is a misspelt step in practice.
        let aboveStep = inScenario && nextLine(after: line, skippingBlankLines: false).map(Self.isStepContent) == true
        let suggestion = header.map { $0 + ":" } ?? Self.suggestion(for: written, strict: !sawStep && !aboveStep)
        let inSteps = sawStep && inScenario
        let fix = suggestion.flatMap { suggestion -> Diagnostic.Fix? in
            guard inSteps || section == .none || isMistake(written, in: text, suggestion: suggestion, line: line) else { return nil }
            return Self.fix(replacing: written, in: text, with: suggestion)
        }
        if inSteps {
            let hint = suggestion.map { " Did you mean '\($0)'?" } ?? ""
            warn(line, column, "Expected a step (Given, When, Then, And, But), a table or a doc string.\(hint)", fix: fix)
        } else if let suggestion = suggestion {
            warn(line, column, "'\(written)' is not a Gherkin keyword. Did you mean '\(suggestion)'?", fix: fix)
        }
        // Read a header that is only missing its colon as that header, so the lines after it
        // aren't reported too.
        if let header = header, fix != nil {
            checkHeader(header, line: line, column: column)
        }
    }

    /// Text after a header and before its first step is a description, where anything goes. So a
    /// `word` there is only a mistake when it isn't an ordinary word (a misspelling, the header in
    /// its own case, or a word with a colon), and the next line is a step, a table or a doc string.
    private func isMistake(_ word: String, in text: String, suggestion: String, line: Int) -> Bool {
        let keyword = suggestion.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        let misspelt = word.lowercased() != keyword.lowercased()
        guard misspelt || word == keyword || text.dropFirst(word.count).hasPrefix(":") else { return false }
        guard let next = nextLine(after: line, skippingBlankLines: true) else { return false }
        if Self.isStepContent(next) { return true }
        // The next line may be a misspelt step itself.
        let nextWord = String(next.prefix { !$0.isWhitespace && $0 != ":" })
        guard let step = Self.suggestion(for: nextWord, strict: false), Self.stepKeywords.contains(step) else { return false }
        return nextWord.lowercased() != step.lowercased()
    }

    /// The next line after `line` that isn't a comment, nor blank when `skippingBlankLines`.
    private func nextLine(after line: Int, skippingBlankLines: Bool) -> String? {
        lines.dropFirst(line).first { !$0.hasPrefix("#") && !(skippingBlankLines && $0.isEmpty) }
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

    private func warn(_ line: Int, _ column: Int, _ message: String, fix: Diagnostic.Fix? = nil) {
        report?(.init(file: file, line: line, column: column, message: message, fix: fix))
    }
}

extension FeatureChecker {
    private static func stepKeyword(of text: String) -> String? {
        if text.hasPrefix("* ") { return "*" }
        return stepKeywords.first { text.hasPrefix($0 + " ") }
    }

    /// Whether `line` is a step, a table row or the start of a doc string.
    private static func isStepContent(_ line: String) -> Bool {
        stepKeyword(of: line) != nil || line.hasPrefix("|") || line.hasPrefix("\"\"\"") || line.hasPrefix("```")
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

    /// The header that `text` starts with when it is written without its colon, or in the wrong case:
    /// `Scenario Outline Foo` or `feature: F`. Not `Rule`, which also starts sentences.
    private static func headerWithoutColon(in text: String) -> String? {
        headers.first { header in
            guard header != "Rule", text.prefix(header.count).lowercased() == header.lowercased() else { return false }
            let next = text.dropFirst(header.count).first
            return next.map { $0 == ":" || $0.isWhitespace } ?? true
        }
    }

    /// The header of more than one word that `text` starts with, and its words as written there, when
    /// each word is at most one edit from the header's: `Scenaro Outline: O` or `Scenario Outlne O`.
    private static func multiWordHeader(in text: String) -> (header: String, written: String)? {
        headers.lazy.filter { $0.contains(" ") }.compactMap { header -> (header: String, written: String)? in
            var rest = Substring(text)
            for (index, keyword) in header.split(separator: " ").enumerated() {
                if index > 0 {
                    guard rest.first?.isWhitespace == true else { return nil }
                    rest = rest.drop { $0.isWhitespace }
                }
                let word = rest.prefix { !$0.isWhitespace && $0 != ":" }
                guard editDistance(word.lowercased(), keyword.lowercased()) <= 1 else { return nil }
                rest = rest.dropFirst(word.count)
            }
            return (header, String(text.dropLast(rest.count)))
        }.first
    }

    /// The fix that replaces `word`, at the start of `text`, with the keyword `suggestion`. A colon
    /// already after the word is kept rather than doubled. Nil when there is nothing to change.
    private static func fix(replacing word: String, in text: String, with suggestion: String) -> Diagnostic.Fix? {
        var replacement = suggestion
        if suggestion.hasSuffix(":"), text.dropFirst(word.count).hasPrefix(":") {
            replacement.removeLast()
        }
        return replacement == word ? nil : Diagnostic.Fix(text: word, replacement: replacement)
    }

    /// A keyword that `word` looks like a misspelling of. Before the first step of a scenario, text
    /// is a description, so `strict` only suggests one for a near miss that isn't a common word.
    private static func suggestion(for word: String, strict: Bool) -> String? {
        let lowered = word.lowercased()
        guard lowered.count >= 3, !commonWords.contains(lowered) else { return nil }
        // The closest keyword, so that "then" is "Then" rather than "When".
        let closest = (stepKeywords + ["Feature:", "Background:", "Scenario:", "Examples:"])
            .map { candidate in
                (candidate, editDistance(lowered, candidate.trimmingCharacters(in: CharacterSet(charactersIn: ":")).lowercased()))
            }
            .min { $0.1 < $1.1 }
        guard let (candidate, distance) = closest else { return nil }
        return distance == 0 || (distance == 1 && (!strict || lowered.count >= 4)) ? candidate : nil
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
