import CucumberSwiftCommandLine
import Foundation

exit(CucumberSwiftCommandLine.run(arguments: Array(CommandLine.arguments.dropFirst())))
