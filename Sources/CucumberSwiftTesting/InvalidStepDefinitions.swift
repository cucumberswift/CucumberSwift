//
//  InvalidStepDefinitions.swift
//  CucumberSwiftTesting
//
// A step definition whose regular expression doesn't compile can never match. As in CucumberSwift, the
// runner reports it where it is written, in the test for the feature files.

import Testing

extension Cucumber {
    struct InvalidDefinition {
        let message: String
        let file: String
        let line: Int
    }

    /// Records an issue at each step definition whose regular expression doesn't compile, where it is
    /// written, as CucumberSwift's `testGherkin()` fails there. The generated Gherkin test calls it.
    public func reportInvalidStepDefinitions() {
        loadStepDefinitions()
        for definition in invalidDefinitions {
            Issue.record(Comment(rawValue: definition.message),
                         sourceLocation: SourceLocation(writtenIn: definition.file, line: definition.line, folder: "StepDefinitions"))
        }
    }
}
