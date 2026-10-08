//
//  Keywords.swift
//  CucumberSwiftGherkin
//

import Foundation

extension FeatureFile {
    /// The Gherkin keywords of one language, for a build tool that reads a feature file line by line.
    /// A line starts a header or a step exactly when CucumberSwift's parser reads it as one.
    public struct Keywords {
        /// What a line of a feature file starts with.
        public enum Line: Equatable, Sendable {
            case feature, rule, background, scenario, scenarioOutline, examples
            /// A step, and its keyword as written, such as `Soit`, `Étant donné que`, `前提` or `*`.
            case step(keyword: String)
        }

        private let language: Language

        /// The keywords of the language that `# language: <code>` names, such as `fr`. Nil for a language
        /// CucumberSwift doesn't support.
        public init?(language code: String) {
            guard let language = Language(code) else { return nil }
            self.language = language
        }

        /// What `text`, a line with its indentation removed, starts with, read outside a scenario. Nil for
        /// any other line, such as a description.
        public func line(_ text: String) -> Line? {
            line(text, inScenario: false)
        }

        /// What `text`, a line with its indentation removed, starts with. Nil for any other line, such as
        /// a description.
        ///
        /// `inScenario` is whether the line is inside a Scenario or Scenario Outline, after its header.
        /// There a keyword that is both Examples and another header, such as Azerbaijani `Nümunələr`,
        /// is Examples.
        public func line(_ text: String, inScenario: Bool) -> Line? {
            // Like the lexer: a header is the text before the line's first colon.
            let header = String(text.prefix { !$0.isScopeTerminator })
            switch Scope.scopeFor(str: header, in: language, inScenario: inScenario) {
                case .feature: return .feature
                case .rule: return .rule
                case .background: return .background
                case .scenario: return .scenario
                case .scenarioOutline: return .scenarioOutline
                case .examples: return .examples
                case .step(let keyword): return .step(keyword: keyword.toString())
                case .unknown: return nil
            }
        }
    }
}
