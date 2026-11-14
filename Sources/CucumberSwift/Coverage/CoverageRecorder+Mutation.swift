//
//  CoverageRecorder+Mutation.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// What the Mutation test reads from the coverage: the regions at a mutant's place, and the source files.
extension CoverageRecorder {
    /// The numbers of the measured regions that hold `line` of the file whose path ends with `file`, at `column`
    /// when it is given: the innermost ones, so that code inside an `if`, or after `&&`, belongs to its own region
    /// and not to the whole function's. Empty when no measured code is there.
    func regions(file: String, line: Int, column: Int? = nil) -> Set<Int> {
        var found = [(span: Int, region: Int)]()
        for (_, function, firstRegion) in functions where function.file == file || function.file.hasSuffix("/" + file) {
            for (index, region) in function.regions.enumerated() where region.contains(line: line, column: column) {
                // Lines first, then columns: the innermost region is the one with the fewest of both.
                let span = (region.lineEnd - region.lineStart) * 10_000 + max(0, region.columnEnd - region.columnStart)
                found.append((span, firstRegion + index))
            }
        }
        guard let smallest = found.map(\.span).min() else { return [] }
        return Set(found.filter { $0.span == smallest }.map(\.region))
    }

    /// The path, as the binary recorded it, of the measured source file whose path ends with `file`.
    func sourcePath(endingWith file: String) -> String? {
        functions.first { $0.function.file == file || $0.function.file.hasSuffix("/" + file) }?.function.file
    }
}
