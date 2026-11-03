//
//  main.swift
//  CucumberSwiftMutationTestingTool
//

import CucumberSwiftMutation
import Foundation

// The tool the Mutation Testing command runs: `CucumberSwiftMutationTestingTool --root <package folder> [options]`.
// It copies the package to a temporary folder, finds the mutants there, runs the tests against each, and writes
// the reports. It never changes the package. `--discover` reads one Swift file from standard input and prints
// its mutants as JSON, for the tool's tests.
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
let options: MutationOptions
do {
    options = try MutationOptions.parse(arguments)
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(MutationRun.Status.failed)
}
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
exit(status)
#else
// Without the trait the tool has no swift-syntax, so it can't read Swift code. It says what to change and
// changes nothing.
FileHandle.standardError.write(Data(SetupAdvice.traitOffMessage.utf8))
exit(2)
#endif
