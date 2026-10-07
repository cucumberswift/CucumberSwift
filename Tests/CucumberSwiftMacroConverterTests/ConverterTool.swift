//
//  ConverterTool.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import Foundation
import XCTest

/// Runs the converter tool, built next to the test bundle. The tests run it as a program because SwiftPM
/// links every test target into one bundle, and linking swift-syntax into a second target breaks the
/// macros' tests with Swift 6.2's prebuilt swift-syntax.
enum ConverterTool {
    struct Entry: Equatable {
        let line: Int
        let stepDefinition: String
        /// Why it was left unchanged. `nil` when it was converted.
        let reason: String?
    }

    struct Result {
        let source: String
        let converted: [Entry]
        let leftUnchanged: [Entry]
    }

    /// What a run on files and folders printed, and how it ended.
    struct Run {
        let status: Int32
        let output: String
    }

    private struct Launched {
        let status: Int32
        let output: String
        /// What the tool wrote to standard error.
        let report: String
    }

    static var url: URL {
        let bundle = Bundle.allBundles.first { $0.bundlePath.hasSuffix(".xctest") }
        return bundle.map { $0.bundleURL.deletingLastPathComponent().appendingPathComponent("CucumberSwiftMacroConverterTool") }
            ?? URL(fileURLWithPath: "CucumberSwiftMacroConverterTool")
    }

    /// `--stdin`: one file's source in, its converted source out, and a line for each step definition.
    static func convert(_ source: String) throws -> Result {
        let run = try launch(["--stdin"], input: source)
        guard run.status == 0 else {
            let message = "The tool exited with status \(run.status): \(run.report)"
            throw NSError(domain: "ConverterTool", code: Int(run.status), userInfo: [NSLocalizedDescriptionKey: message])
        }
        var converted = [Entry]()
        var left = [Entry]()
        for line in run.report.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, let number = Int(parts[0]) else { continue }
            let text = parts[1].dropFirst()
            if text.hasPrefix("converted ") {
                converted.append(Entry(line: number, stepDefinition: String(text.dropFirst("converted ".count)), reason: nil))
            } else if text.hasPrefix("left unchanged "), let end = text.dropFirst("left unchanged ".count).range(of: "): ") {
                let rest = text.dropFirst("left unchanged ".count)
                left.append(Entry(line: number, stepDefinition: String(rest[..<end.lowerBound]) + ")", reason: String(rest[end.upperBound...])))
            }
        }
        return Result(source: run.output, converted: converted, leftUnchanged: left)
    }

    /// The tool on files and folders, as the command runs it.
    static func run(_ arguments: [String]) throws -> Run {
        let run = try launch(arguments, input: nil)
        return Run(status: run.status, output: run.output)
    }

    private static func launch(_ arguments: [String], input: String?) throws -> Launched {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        let standardInput = Pipe()
        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardInput = standardInput
        process.standardOutput = standardOutput
        process.standardError = standardError
        try process.run()
        if let input { standardInput.fileHandleForWriting.write(Data(input.utf8)) }
        try standardInput.fileHandleForWriting.close()
        // Read before waiting, so a large source can't fill a pipe and block the tool.
        let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
        let report = standardError.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Launched(status: process.terminationStatus,
                        output: String(bytes: output, encoding: .utf8) ?? "",
                        report: String(bytes: report, encoding: .utf8) ?? "")
    }
}
#endif
