//
//  main.swift
//  CucumberSwiftMutationTestingTool
//

import CucumberSwiftMutation
import Foundation

// The mutation testing tool: `swift run cucumberswift-mutation-test [options]` in a package, and what the Mutation
// Testing command runs. It copies the package to a temporary folder, finds the mutants there, runs the tests against
// each, and writes the reports to .build/mutation-testing. It never changes the package. Without --sources it mutates
// the package's library and executable targets, or those that --target names. --tags chooses the scenarios, as
// CUCUMBER_TAGS does. --format xcode also prints each surviving mutant in the compiler's format, which Xcode shows at
// its line when a Run Script build phase runs the tool. `--discover` reads one Swift file from standard input and
// prints its mutants as JSON, for the tool's tests.
let arguments = Array(CommandLine.arguments.dropFirst())

#if Macros
if arguments == ["--discover"] {
    let source = String(bytes: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let mutants = MutantFinder.mutants(in: source, file: "Sources/Example.swift")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    FileHandle.standardOutput.write((try? encoder.encode(mutants)) ?? Data("[]".utf8))
    exit(0)
}
var options: MutationOptions
do {
    options = try MutationOptions.parse(arguments)
    if options.findsSources {
        options.sources = try SourceFolders.find(in: options.root, named: options.targets, swift: options.swift, runner: ProcessRunner())
    }
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(MutationRun.Status.failed)
}
// The tool passes its environment on to the tests, so the tags reach them as CUCUMBER_TAGS.
if let tags = options.tags { setenv("CUCUMBER_TAGS", tags, 1) }
let run = MutationRun(options: options, discoverer: SyntaxDiscoverer())
// Delete the copy on Control-C and on a plain kill. A run killed with SIGKILL can't, and the next run cleans up.
var handlers = [DispatchSourceSignal]()
for signalNumber in [SIGINT, SIGTERM] {
    signal(signalNumber, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .global())
    source.setEventHandler {
        run.cancel()
        exit(128 + signalNumber)
    }
    source.resume()
    handlers.append(source)
}
let status = run.run()
// A cancelled run is still being cleaned up by the signal handler, which exits when it is done.
if status == MutationRun.Status.cancelled { dispatchMain() }
if options.format == .xcode {
    for warning in SurvivorWarning.read(report: options.output.appendingPathComponent("mutation-report.json"), root: options.root) {
        print(warning.xcodeLine)
    }
}
exit(status)
#else
// Without the trait the tool has no swift-syntax, so it can't read Swift code. It says what to change and
// changes nothing.
FileHandle.standardError.write(Data(SetupAdvice.traitOffMessage.utf8))
exit(2)
#endif
