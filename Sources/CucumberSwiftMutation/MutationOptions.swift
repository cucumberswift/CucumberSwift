//
//  MutationOptions.swift
//  CucumberSwiftMutation
//

import Foundation

public struct MutationOptions: Equatable, Sendable {
    public struct UsageError: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    /// The package folder.
    public var root: URL
    /// Where the reports and the lock file go. By default `.build/mutation-testing` in the package.
    public var output: URL
    /// Where the temporary copy goes, when the user chose a folder.
    public var workDirectory: URL?
    /// The folders, relative to the package, whose Swift files are mutated.
    public var sources = ["Sources"]
    public var maxMutants: Int?
    /// A mutant's tests may run this many times as long as the baseline before they count as a timeout.
    public var timeoutMultiplier = 3.0
    /// The shortest timeout, in seconds, so that a fast baseline doesn't make a busy machine time out.
    public var minimumTimeout = 30.0
    /// How many times the unmutated tests run first. Two catches a test that fails by chance.
    public var baselineRuns = 2
    public var swift = "/usr/bin/swift"
    /// Lists the mutants without testing them.
    public var dryRun = false
    /// Builds swift-syntax from source instead of downloading SwiftPM's prebuilt copy. The command plugin's
    /// sandbox lets SwiftPM neither download it nor keep it in its cache.
    public var disablePrebuilts = false

    /// The Xcode project or workspace to build and test with `xcodebuild`, instead of the package with SwiftPM.
    public var xcode: XcodebuildRunner.Target?
    public var xcodebuild = "/usr/bin/xcodebuild"

    /// What every `swift build` and `swift test` in the copy gets: the sandbox is off because SwiftPM can't
    /// nest its own inside the plugin's.
    var swiftArguments: [String] {
        ["--disable-sandbox"] + (disablePrebuilts ? ["--disable-experimental-prebuilts"] : [])
    }

    /// The runner for these options: `xcodebuild` when they name a scheme, and SwiftPM otherwise.
    public func makeRunner(commands: CommandRunning = ProcessRunner()) -> TestRunner {
        if let xcode {
            return XcodebuildRunner(target: xcode, xcodebuild: xcodebuild, commands: commands)
        }
        return SwiftPMRunner(options: self, commands: commands)
    }

    /// What is wrong with `root` for the runner, or `nil`: the file that says it is the kind of project the run
    /// builds. Checked before the copy, so that a run in the wrong folder copies nothing.
    public var rootProblem: String? {
        let file = xcode?.container ?? "Package.swift"
        guard !FileManager.default.fileExists(atPath: root.appendingPathComponent(file).path) else { return nil }
        return xcode == nil ? "\(root.path) has no Package.swift. Run the command in a Swift package."
                            : "\(root.path) has no \(file). Pass --root with the folder that holds it."
    }

    public static func parse(_ arguments: [String]) throws -> MutationOptions {
        var root: URL?
        var output: URL?
        var options = MutationOptions(root: URL(fileURLWithPath: "."))
        var sources = [String]()
        var project: String?
        var workspace: String?
        var scheme: String?
        var destination: String?
        var testTarget: String?
        var xcodeArguments = [String]()
        var index = 0
        func value(for option: String) throws -> String {
            index += 1
            guard index < arguments.count, !arguments[index].hasPrefix("--") else {
                throw UsageError(description: "\(option) needs a value")
            }
            return arguments[index]
        }
        func number(_ option: String) throws -> Double {
            let text = try value(for: option)
            guard let number = Double(text), number > 0 else { throw UsageError(description: "\(option) needs a number above 0, not \"\(text)\"") }
            return number
        }
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
                case "--root": root = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                case "--output": output = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                case "--work-dir": options.workDirectory = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                case "--sources": sources.append(try value(for: argument))
                case "--max-mutants": options.maxMutants = Int(try number(argument))
                case "--timeout-multiplier": options.timeoutMultiplier = try number(argument)
                case "--minimum-timeout": options.minimumTimeout = try number(argument)
                case "--baseline-runs": options.baselineRuns = Int(try number(argument))
                case "--swift": options.swift = try value(for: argument)
                case "--dry-run": options.dryRun = true
                case "--disable-prebuilts": options.disablePrebuilts = true
                case "--project": project = try value(for: argument)
                case "--workspace": workspace = try value(for: argument)
                case "--scheme": scheme = try value(for: argument)
                case "--destination": destination = try value(for: argument)
                case "--test-target": testTarget = try value(for: argument)
                case "--xcodebuild": options.xcodebuild = try value(for: argument)
                case "--xcodebuild-arg": xcodeArguments.append(try value(for: argument))
                default: throw UsageError(description: "Unknown option \(argument)")
            }
            index += 1
        }
        guard let root else { throw UsageError(description: "--root needs the package folder") }
        options.root = root
        options.xcode = try xcodeTarget(project: project, workspace: workspace, scheme: scheme, destination: destination,
                                        testTarget: testTarget, arguments: xcodeArguments)
        options.output = output ?? root.appendingPathComponent(".build/mutation-testing")
        if !sources.isEmpty { options.sources = sources }
        return options
    }

    /// The Xcode target the options name, `nil` when none of them does.
    private static func xcodeTarget(
        project: String?, workspace: String?, scheme: String?, destination: String?, testTarget: String?, arguments: [String]
    ) throws -> XcodebuildRunner.Target? {
        let named = project != nil || workspace != nil || scheme != nil || destination != nil || testTarget != nil || !arguments.isEmpty
        guard named else { return nil }
        guard project == nil || workspace == nil else {
            throw UsageError(description: "Pass --project or --workspace, not both")
        }
        guard let container = project ?? workspace else {
            throw UsageError(description: "--scheme, --destination, --test-target and --xcodebuild-arg need --project or --workspace")
        }
        guard let scheme else { throw UsageError(description: "--project and --workspace need --scheme") }
        guard let destination else { throw UsageError(description: "--project and --workspace need --destination, such as \"platform=macOS\"") }
        return XcodebuildRunner.Target(container: container, scheme: scheme, destination: destination, testTarget: testTarget, arguments: arguments)
    }

    public init(root: URL) {
        self.root = root
        output = root.appendingPathComponent(".build/mutation-testing")
    }
}
