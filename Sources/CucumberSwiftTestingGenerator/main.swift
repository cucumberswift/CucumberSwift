//
//  main.swift
//  CucumberSwiftTestingGenerator
//
// CucumberSwiftTestingGenerator --output <file.swift> <feature files…> [--swift <Swift file>]…
//
// Writes the Swift Testing tests for the feature files, and the test for the features that the Swift files
// write in the Swift DSL, if they write any. The CucumberSwiftTestingPlugin build tool plugin runs it.

import CucumberSwiftGherkin
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2, arguments[0] == "--output" else {
    FileHandle.standardError.write(Data("usage: CucumberSwiftTestingGenerator --output <file.swift> <feature files…>\n".utf8))
    exit(2)
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
        exit(1)
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
        print("error: CucumberSwiftTestingGenerator can't write \(output): \(error.localizedDescription)")
        exit(1)
    }
}
