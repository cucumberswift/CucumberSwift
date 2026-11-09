//
//  GenerateCommand.swift
//  CucumberSwiftTestingGenerator
//

import CucumberSwiftGherkin
import Foundation

/// `cucumberswift generate --output <file.swift> <feature files…> [--swift <Swift file>]…`
///
/// Writes the Swift Testing tests for the feature files, and the test for the features that the Swift files
/// write in the Swift DSL, if they write any. The CucumberSwiftTestingPlugin build tool plugin and the Bazel
/// rule cucumberswift_testing_sources run it.
public enum GenerateCommand {
    public static let usage = "usage: cucumberswift generate --output <file.swift> <feature files…> [--swift <Swift file>]…"

    /// Returns the exit status: 0, 1 when a feature file can't be read or the output can't be written, 2 when the
    /// arguments can't be used.
    public static func run(arguments: [String]) -> Int32 {
        guard arguments.count >= 2, arguments[0] == "--output" else {
            FileHandle.standardError.write(Data("\(usage)\n".utf8))
            return 2
        }
        let output = arguments[1]
        var inputs = [SwiftTestingSource.Input]()
        var featurePaths = [String]()
        var swiftPaths = [String]()
        var rest = arguments.dropFirst(2)[...]
        while let argument = rest.popFirst() {
            if argument == "--swift", let path = rest.popFirst() {
                swiftPaths.append(path)
            } else {
                featurePaths.append(argument)
            }
        }
        for path in featurePaths.sorted() {
            guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
                print("\(path):1: error: CucumberSwift can't read this feature file as UTF-8 text")
                return 1
            }
            inputs.append(SwiftTestingSource.Input(path: path, file: FeatureFile(parsing: text, uri: path)))
        }
        let writesDSLFeatures = swiftPaths.contains { path in
            (try? String(contentsOfFile: path, encoding: .utf8)).map(SwiftTestingSource.writesDSLFeatures) ?? false
        }
        let source = SwiftTestingSource.generate(inputs, dslFeatures: writesDSLFeatures)
        // Write only when the source changes, so that an unchanged feature file doesn't recompile the tests.
        if (try? String(contentsOfFile: output, encoding: .utf8)) != source {
            do {
                try source.write(toFile: output, atomically: true, encoding: .utf8)
            } catch {
                print("error: cucumberswift generate can't write \(output): \(error.localizedDescription)")
                return 1
            }
        }
        return 0
    }
}
