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
            /// A step, and its keyword as written, such as `Soit` or `*`.
            case step(keyword: String)
        }

        private let language: Language

        /// The keywords of the language that `# language: <code>` names, such as `fr`. Nil for a language
        /// CucumberSwift doesn't support.
        public init?(language code: String) {
            guard let language = Language(code) else { return nil }
            self.language = language
        }

        /// What `text`, a line with its indentation removed, starts with. Nil for any other line, such as
        /// a description.
        public func line(_ text: String) -> Line? {
            // Like the lexer: a header is the text before the line's first colon.
            switch Scope.scopeFor(str: String(text.prefix { !$0.isScopeTerminator }), in: language) {
                case .feature: return .feature
                case .rule: return .rule
                case .background: return .background
                case .scenario: return .scenario
                case .scenarioOutline: return .scenarioOutline
                case .examples: return .examples
                case .step: return .step(keyword: String(text.prefix { $0 != " " }))
                case .unknown: return nil
            }
        }
    }
}
