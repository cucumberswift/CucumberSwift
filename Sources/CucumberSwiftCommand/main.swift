import CucumberSwiftCoverageMerge
import Foundation

// cucumberswift <command> …
//
// CucumberSwift's command-line tool, run with `swift run cucumberswift`. It picks the command by its first
// argument, and the command's library target runs it with `run(arguments:) -> Int32`, which returns the exit
// status. Another command is another case here and a library target that the tool depends on.
//
//   coverage merge <folder>…   scores the scenarios of several runs as one run (CoverageCommand)

let usage = "usage: cucumberswift coverage merge <coverage folder or run folder>…"
let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
    case "coverage":
        exit(CoverageCommand.run(arguments: Array(arguments.dropFirst())))
    case "-h", "--help":
        print(usage)
        exit(0)
    case nil:
        print(usage)
        exit(2)
    default:
        FileHandle.standardError.write(Data("error: unknown command \(arguments[0])\n".utf8))
        print(usage)
        exit(2)
}
