import CucumberSwiftCommandLine
import Foundation

// The tool that the SwiftPM and Xcode plugins run, with the arguments of a cucumberswift command. A plugin can
// only run an executable that SwiftPM makes a product of its own, and cucumberswift is a declared product under
// another name, so this is the same command line in a second executable, which is not a product of the package.
exit(CucumberSwiftCommandLine.run(arguments: Array(CommandLine.arguments.dropFirst())))
