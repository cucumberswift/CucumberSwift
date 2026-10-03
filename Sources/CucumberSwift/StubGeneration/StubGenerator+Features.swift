//
//  StubGenerator+Features.swift
//  CucumberSwift
//
// The step definitions CucumberSwift suggests for the undefined steps of the features it runs. How one
// step's suggestion is written is in Gherkin/Core/StubGeneration, which build tools share.

import Foundation

extension StubGenerator {
    static var implementorRegexLiteralStyle: RegexLiteralStyle {
        (Cucumber.shared as? StepImplementation)?.regexLiteralStyle ?? .extendedDelimiter
    }

    static var implementorStyle: Style {
        FeatureFlags.isGenerateRegexLiterals ? .regexLiteral(implementorRegexLiteralStyle) : .cucumberExpression
    }

    /// The generated step definition for a step that no step definition matches: the step's own, or else
    /// one `getStubs` lists for a step with the same pattern that the step's keyword can use, preferring one
    /// that also has a data table or doc string when this step does, so the definition binds `step` to read it.
    static func stub(for step: Step,
                     in features: [Feature],
                     style: Style = implementorStyle) -> String? {
        let stubs = getStubs(for: features, style: style)
        if let own = stubs.first(where: { $0.step === step }) {
            return own.generatedSwift
        }
        let regex = regexForTokens(Lexer(step.match).lex())
        let keyword = step.keyword.primaryKeywords.toString().capitalizingFirstLetter()
        let samePattern = stubs.filter { stub in
            regexForTokens(Lexer(stub.step.match).lex()) == regex
                && stub.generatedSwift.components(separatedBy: "\n").contains { $0.hasPrefix("\(keyword)(") || $0.hasPrefix("MatchAll(") }
        }
        let sameShape = samePattern.first {
            ($0.step.dataTable != nil) == (step.dataTable != nil) && ($0.step.docString != nil) == (step.docString != nil)
        }
        return (sameShape ?? samePattern.first)?.generatedSwift
    }

    static func getStubs(for features: [Feature],
                         style: Style = implementorStyle) -> [(step: Step, generatedSwift: String)] {
        var lookup = [String: Method]()
        let executableSteps = features
            .taggedElements(askImplementor: false)
            .flatMap { $0.scenarios }
            .taggedElements(askImplementor: true)
            .flatMap { $0.steps }
            .sorted { $0.keyword.rawValue < $1.keyword.rawValue }

        let implementedSteps = executableSteps.filter { $0.canExecute }

        let methods = executableSteps
            .filter { !$0.canExecute }
            .reduce(into: [(step: Step, method: Method)]()) {
                let method = StubGenerator.method(for: $1.match,
                                                  keyword: $1.keyword,
                                                  hasDataTable: $1.dataTable != nil,
                                                  hasDocString: $1.docString != nil,
                                                  style: style)

                // Steps with the same pattern share a step definition. As Cucumber Expressions, steps that
                // differ only in a number, such as `5` and `-5`, do; regular expressions keep the `-`.
                if let m = lookup[method.pattern],
                   !m.keyword.contains($1.keyword) {
                    m.insertKeyword($1.keyword)
                } else {
                    $0.append(($1, method))
                    lookup[method.pattern] = method
                }
            }

        return methods.map { step, method in
            let canMatchAll = implementedSteps.allSatisfy { $0.match.matches(for: method.regex).isEmpty }
            let overwrittenSteps = implementedSteps.filter { method.keyword.contains($0.keyword) && !$0.match.matches(for: method.regex).isEmpty }
            if !overwrittenSteps.isEmpty {
                method.comment = "//FIXME: WARNING: This will overwite your implementation for the step(s):\n"
                method.comment += overwrittenSteps.map { "//                \($0.keyword.toString()) \($0.match)" }.joined(separator: "\n")
                method.comment += "\n"
            }
            return (step, method.generateSwift(matchAllAllowed: canMatchAll))
        }
    }
}
