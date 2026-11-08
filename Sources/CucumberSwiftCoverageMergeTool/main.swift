import Foundation

// cucumberswift-coverage-merge <folder>…
//
// Scores the scenarios of several runs as one run: the workers of a parallel run, or the shards of a suite.
// Each folder is a run's folder, run-<id>, or a coverage folder that holds them, as CUCUMBER_COVERAGE_PATH
// sets it. Prints each feature's and each Rule's scores, and each issue as `file:line: warning: message`,
// with the levels the runs checked. Exits 1 when an issue is an error, and 2 when the runs can't be merged.

let arguments = Array(CommandLine.arguments.dropFirst())
guard !arguments.isEmpty, !arguments.contains(where: { ["-h", "--help"].contains($0) }) else {
    print("usage: cucumberswift-coverage-merge <coverage folder or run folder>…")
    exit(arguments.isEmpty ? 2 : 0)
}
let folders = arguments.map { URL(fileURLWithPath: $0, isDirectory: true) }
do {
    let merge = try CoverageMerge(runs: CoverageMerge.read(folders))
    exit(merge.report { print($0) } ? 1 : 0)
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(2)
}
