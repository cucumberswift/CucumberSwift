//
//  CoverageRecorder+Mutation.swift
//  CucumberSwift
//
//  Shared with CucumberSwiftTesting through the Sources/CucumberSwiftTesting/Coverage symlink, so it
//  uses neither XCTest nor Swift Testing.
//

import Foundation

/// What mutation testing reads from the coverage: the regions at a mutant's place, the source files, and
/// `regions.json` for `cucumberswift-mutation-test`.
extension CoverageRecorder {
    /// A stretch of code, by its file and its first and last line and column, as `regions.json` lists them.
    struct CodeRegion: Codable, Equatable {
        var file: String
        var lineStart: Int
        var columnStart: Int
        var lineEnd: Int
        var columnEnd: Int
    }

    /// A scenario, and the numbers of the regions it ran, as `regions.json` lists them.
    struct ScenarioRegions: Codable, Equatable {
        var feature: String
        var line: Int
        var name: String
        var ran: [Int]
    }

    /// `regions.json`: every measured code region, numbered by its place in `regions`, whether a scenario ran it or
    /// not, and the regions each scenario ran. A position belongs to the innermost region that holds it, so a line in an
    /// `if` that no scenario entered has a region of its own that no scenario ran.
    struct RegionsFile: Codable, Equatable {
        var version = 1
        var regions: [CodeRegion]
        var scenarios: [ScenarioRegions]
    }

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

    /// Every measured code region, by file and position, in the order of their numbers.
    func codeRegions() -> [CodeRegion] {
        functions.flatMap { _, function, _ in
            function.regions.map { region in
                CodeRegion(file: function.file,
                           lineStart: region.lineStart,
                           columnStart: region.columnStart,
                           lineEnd: region.lineEnd,
                           columnEnd: region.columnEnd)
            }
        }
    }
}
