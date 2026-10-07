//
//  ConverterTool.swift
//  CucumberSwiftMacroConverterTests
//

import Foundation
import XCTest

/// Runs the converter tool, built next to the test bundle, on a source string: `--stdin`. The tests run it
/// as a program because SwiftPM links every test target into one bundle, and linking swift-syntax into a
/// second target breaks the macros' tests with Swift 6.2's prebuilt swift-syntax.
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

    static var url: URL {
        Bundle.allBundles.first { $0.bundlePath.hasSuffix(".xctest") }.map {
            $0.bundleURL.deletingLastPathComponent().appendingPathComponent("CucumberSwiftMacroConverterTool")
        } ?? URL(fileURLWithPath: "CucumberSwiftMacroConverterTool")
    }

    static func convert(_ source: String) throws -> Result {
        let process = Process()
        process.executableURL = url
        process.arguments = ["--stdin"]
        let input = Pipe(), output = Pipe(), report = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = report
        try process.run()
        // Read before waiting, so a large source can't fill a pipe and block the tool.
        input.fileHandleForWriting.write(Data(source.utf8))
        try input.fileHandleForWriting.close()
        let converted = output.fileHandleForReading.readDataToEndOfFile()
        let lines = String(decoding: report.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "ConverterTool", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "The tool exited with status \(process.terminationStatus): \(lines)"])
        }
        var result = Result(source: String(decoding: converted, as: UTF8.self), converted: [], leftUnchanged: [])
        var convertedEntries = [Entry](), left = [Entry]()
        for line in lines.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, let number = Int(parts[0]) else { continue }
            let text = parts[1].dropFirst()
            if text.hasPrefix("converted ") {
                convertedEntries.append(Entry(line: number, stepDefinition: String(text.dropFirst("converted ".count)), reason: nil))
            } else if text.hasPrefix("left unchanged ") {
                let rest = text.dropFirst("left unchanged ".count)
                // The step definition ends at the first `): ` after its closing parenthesis.
                if let end = rest.range(of: "): ") {
                    left.append(Entry(line: number, stepDefinition: String(rest[..<end.lowerBound]) + ")",
                                      reason: String(rest[end.upperBound...])))
                }
            }
        }
        result = Result(source: result.source, converted: convertedEntries, leftUnchanged: left)
        return result
    }
}
