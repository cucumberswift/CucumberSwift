import Foundation

enum Linter {
    static func check(features: [String], stepDefinitionFiles: [String]) -> [Diagnostic] {
        var diagnostics = [Diagnostic]()
        let definitions = stepDefinitionFiles.flatMap { StepDefinition.read(file: $0) { diagnostics.append($0) } }
        for feature in features {
            // Without any step definitions in the target, they live somewhere the build can't see,
            // so only check the Gherkin itself.
            FeatureChecker(file: feature, definitions: definitions.isEmpty ? nil : definitions)
                .check { diagnostics.append($0) }
        }
        return diagnostics
    }
}
