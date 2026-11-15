//
//  MutationTestCommand.swift
//  CucumberSwiftMutationCommand
//

#if os(macOS) || os(Linux)
import CucumberSwiftMutation
import Foundation

/// `cucumberswift mutation-test [options]`: mutation testing in a package, and what the Mutation Testing command runs.
/// It copies the package to a temporary folder, finds the mutants there, runs the tests against each, and writes the
/// reports to .build/mutation-testing. It never changes the package. Without --sources it mutates the package's
/// library and executable targets, or those that --target names. --tags chooses the scenarios, as CUCUMBER_TAGS does.
/// --format xcode also prints each surviving mutant in the compiler's format, which Xcode shows at its line when a Run
/// Script build phase runs the command. `--discover` reads one Swift file from standard input and prints its mutants
/// as JSON, for the command's tests.
public enum MutationTestCommand {
    /// Runs the command with `arguments`, the ones after `mutation-test`, and returns the exit status. A run that is
    /// cancelled with Control-C or a plain kill exits from its signal handler once it has deleted the copy.
    public static func run(arguments: [String]) -> Int32 {
        // Writes each line as it's printed, also into a pipe, such as a build server's log or `tee`, which would
        // otherwise get the whole output at the end.
        setvbuf(stdout, nil, _IOLBF, 0)
        #if Macros
        if arguments == ["--discover"] { return discover() }
        var options: MutationOptions
        do {
            options = try MutationOptions.parse(arguments)
            if options.findsSources {
                options.sources = try SourceFolders.find(in: options.root, named: options.targets, swift: options.swift, runner: ProcessRunner())
            }
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            return MutationRun.Status.failed
        }
        // The command passes its environment on to the tests, so the tags reach them as CUCUMBER_TAGS.
        if let tags = options.tags { setenv("CUCUMBER_TAGS", tags, 1) }
        let run = MutationRun(options: options, discoverer: SyntaxDiscoverer())
        let handlers = cancelOnSignals(run)
        let status = run.run()
        // A cancelled run is still being cleaned up by the signal handler, which exits when it is done.
        if status == MutationRun.Status.cancelled { dispatchMain() }
        withExtendedLifetime(handlers) {
            // Keeps the signal handlers until the run is over: a released source no longer handles its signal.
        }
        // Only a completed run wrote this run's report.
        if options.format == .xcode, status == MutationRun.Status.completed {
            for warning in SurvivorWarning.read(report: options.output.appendingPathComponent("mutation-report.json"), root: options.root) {
                print(warning.xcodeLine)
            }
        }
        return status
        #else
        // Without the trait the command has no swift-syntax, so it can't read Swift code. It says what to change and
        // changes nothing.
        FileHandle.standardError.write(Data(SetupAdvice.traitOffMessage.utf8))
        return 2
        #endif
    }

    #if Macros
    /// Prints the mutants of the Swift file on standard input as JSON.
    private static func discover() -> Int32 {
        let source = String(bytes: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let mutants = MutantFinder.mutants(in: source, file: "Sources/Example.swift")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        FileHandle.standardOutput.write((try? encoder.encode(mutants)) ?? Data("[]".utf8))
        return 0
    }

    /// Deletes the copy on Control-C and on a plain kill. A run killed with SIGKILL can't, and the next run cleans up.
    private static func cancelOnSignals(_ run: MutationRun) -> [DispatchSourceSignal] {
        [SIGINT, SIGTERM].map { signalNumber in
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .global())
            source.setEventHandler {
                run.cancel()
                exit(128 + signalNumber)
            }
            source.resume()
            return source
        }
    }
    #endif
}
#endif
