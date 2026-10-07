import CucumberSwiftExpressions
import Foundation

/// A step definition found in a Swift file: `Given("…")`, `When(#/…/#)`, `Then(/…/)` and so on.
/// Only literal patterns are found; a pattern built at run time is invisible to the build.
struct StepDefinition {
    enum Pattern {
        case expression(CucumberExpression)
        case regex(NSRegularExpression)
    }

    // Given("…"), Given(#/…/#) or Given(/…/), and the same for the other keywords.
    private static let finder = compile(
        #"\b(?:Given|When|Then|And|But|MatchAll)\s*\(\s*(?:"((?:[^"\\\n]|\\.)*)"|#/((?:[^\\\n]|\\.)*?)/#|/((?:[^/\\\n]|\\.)+)/)"#)
    private static let builtInParameters: Set = ["", "int", "float", "double", "word", "string"]
    private static let parameter = compile(#"(?<!\\)\{([^{}]*)\}"#)

    let pattern: Pattern
    let file: String
    let line: Int

    /// Reads the step definitions in `file`, and reports each pattern that can never match.
    static func read(file: String, report: (Diagnostic) -> Void) -> [StepDefinition] {
        guard let source = (try? String(contentsOfFile: file, encoding: .utf8))?.blankingComments else { return [] }
        let lineStarts = source.lineStartOffsets
        var definitions = [StepDefinition]()
        for match in finder.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
            let line = lineStarts.line(containing: match.range.location)
            if let range = Range(match.range(at: 1), in: source) {
                let literal = String(source[range])
                // An interpolated string is only known at run time.
                guard !literal.contains("\\(") else { continue }
                let text = anonymizingCustomParameters(in: literal.unescapingSwiftString)
                do {
                    let expression = try CucumberExpression(validating: text)
                    definitions.append(.init(pattern: .expression(expression), file: file, line: line))
                } catch {
                    report(.init(file: file, line: line, message: "This step definition can never match: \(error)"))
                }
            } else if let range = Range(match.range(at: 2), in: source) ?? Range(match.range(at: 3), in: source) {
                do {
                    let regex = try NSRegularExpression(pattern: String(source[range]))
                    definitions.append(.init(pattern: .regex(regex), file: file, line: line))
                } catch {
                    report(.init(file: file, line: line, message: "This regular expression does not compile: \(error.localizedDescription)"))
                }
            }
        }
        return definitions
    }

    /// Compiles one of the fixed patterns above, which are known to be valid.
    private static func compile(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            fatalError("CucumberSwiftLintTool's pattern \(pattern) does not compile: \(error)")
        }
    }

    /// Custom parameter types are registered at run time, so the build can't know what they match.
    /// Treat each one as `{}`, which matches anything, rather than report a step as undefined.
    private static func anonymizingCustomParameters(in expression: String) -> String {
        // An anchored or slash-delimited pattern is a regular expression, where `{2}` is a quantifier.
        let isRegex = expression.hasPrefix("^") || expression.hasSuffix("$")
            || (expression.count > 1 && expression.hasPrefix("/") && expression.hasSuffix("/"))
        guard !isRegex else { return expression }
        let range = NSRange(expression.startIndex..., in: expression)
        var result = expression
        for match in parameter.matches(in: expression, range: range).reversed() {
            guard let nameRange = Range(match.range(at: 1), in: expression),
                  !builtInParameters.contains(String(expression[nameRange])),
                  let whole = Range(match.range, in: result) else { continue }
            result.replaceSubrange(whole, with: "{}")
        }
        return result
    }

    func matches(_ text: String) -> Bool {
        switch pattern {
            case .expression(let expression):
                return expression.match(in: text) != nil
            case .regex(let regex):
                let range = NSRange(text.startIndex..., in: text)
                guard let match = regex.firstMatch(in: text, range: range) else { return false }
                return match.range == range
        }
    }
}

extension String {
    var unescapingSwiftString: String {
        var result = ""
        var escaped = false
        for character in self {
            if escaped {
                switch character {
                    case "n": result.append("\n")
                    case "t": result.append("\t")
                    default: result.append(character)
                }
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else {
                result.append(character)
            }
        }
        return result
    }

    /// The UTF-16 offset at which each line starts, for turning a match location into a line number.
    var lineStartOffsets: [Int] {
        var offsets = [0]
        var offset = 0
        for unit in utf16 {
            offset += 1
            if unit == 10 { offsets.append(offset) }
        }
        return offsets
    }
}

extension Array where Element == Int {
    /// The 1-based line that contains `offset`, for an array made by `lineStartOffsets`.
    func line(containing offset: Int) -> Int {
        var low = 0
        var high = count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if self[middle] <= offset { low = middle } else { high = middle - 1 }
        }
        return low + 1
    }
}
