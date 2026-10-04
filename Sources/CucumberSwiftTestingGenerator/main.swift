//
//  main.swift
//  CucumberSwiftTestingGenerator
//
// CucumberSwiftTestingGenerator --output <file.swift> <feature files…>
//
// Writes the Swift Testing tests for the feature files. The CucumberSwiftTestingPlugin build tool
// plugin runs it.

import CucumberSwiftGherkin
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2, arguments[0] == "--output" else {
    FileHandle.standardError.write(Data("usage: CucumberSwiftTestingGenerator --output <file.swift> <feature files…>\n".utf8))
    exit(2)
}
let output = arguments[1]
var inputs = [SwiftTestingSource.Input]()
for path in arguments.dropFirst(2).sorted() {
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
        print("\(path):1: error: CucumberSwift can't read this feature file as UTF-8 text")
        exit(1)
    }
    inputs.append(SwiftTestingSource.Input(path: path, file: FeatureFile(parsing: text, uri: path)))
}
let source = SwiftTestingSource.generate(inputs)
// Write only when the source changes, so that an unchanged feature file doesn't recompile the tests.
if (try? String(contentsOfFile: output, encoding: .utf8)) != source {
    do {
        try source.write(toFile: output, atomically: true, encoding: .utf8)
    } catch {
        print("error: CucumberSwiftTestingGenerator can't write \(output): \(error.localizedDescription)")
        exit(1)
    }
}
