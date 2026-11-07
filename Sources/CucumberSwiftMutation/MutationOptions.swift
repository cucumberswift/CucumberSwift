//
//  MutationOptions.swift
//  CucumberSwiftMutation
//

import Foundation

public struct MutationOptions: Equatable, Sendable {
    public struct UsageError: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    /// How the tool prints the surviving mutants at the end of a run.
    public enum Format: String, Equatable, Sendable {
        /// Only the summary, as `swift package` and a terminal show it.
        case text
        /// Also a line for each survivor in the compiler's format, `File.swift:22:27: warning: …`, which Xcode
        /// shows at that line when a Run Script build phase prints it.
        case xcode
    }

    /// The Xcode options of a command line: those with a value, by name, then the test targets and the extra arguments.
    private struct XcodeInput {
        var values = [String: String]()
        var testTargets = [String]()
        var arguments = [String]()
    }

    /// The package folder.
    public var root: URL
    /// Where the reports and the lock file go. By default `.build/mutation-testing` in the package.
    public var output: URL
    /// Where the temporary copy goes, when the user chose a folder.
    public var workDirectory: URL?
    /// The folders, relative to the package, whose Swift files are mutated.
    public var sources = ["Sources"]
    /// Whether the tool finds `sources` itself, from the package's targets, as it does unless `--sources` is given.
    public var findsSources = true
    /// The targets whose code is mutated, by name: all the targets with code when empty.
    public var targets = [String]()
    /// The tags that choose the scenarios, as `CUCUMBER_TAGS` does. The tests get them as `CUCUMBER_TAGS`.
    public var tags: String?
    public var format = Format.text
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

    /// The Bazel test target to build and test with `bazel`, instead of the package with SwiftPM.
    public var bazelTarget: BazelRunner.Target?
    /// The Bazel to run: a name that is looked for in PATH, or a full path.
    public var bazel = "bazel"
    /// Where Bazel keeps what it builds, for every copy and every run: its default is in the user's caches folder.
    public var bazelDiskCache: URL?

    /// What every `swift build` and `swift test` in the copy gets: the sandbox is off because SwiftPM can't
    /// nest its own inside the plugin's.
    var swiftArguments: [String] {
        ["--disable-sandbox"] + (disablePrebuilts ? ["--disable-experimental-prebuilts"] : [])
    }

    /// What is wrong with `root` for the runner, or `nil`: the file that says it is the kind of project the run
    /// builds. Checked before the copy, so that a run in the wrong folder copies nothing.
    public var rootProblem: String? {
        if bazelTarget != nil {
            guard !BazelRunner.workspaceFiles.contains(where: { FileManager.default.fileExists(atPath: root.appendingPathComponent($0).path) }) else { return nil }
            return "\(root.path) has no MODULE.bazel. Pass --root with the Bazel workspace."
        }
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
        var xcode = XcodeInput()
        var bazelArguments = [String]()
        var index = 0
        func value(for option: String, isArgument: Bool = false) throws -> String {
            index += 1
            // An argument for Bazel is a flag itself, such as `--config=ci`, so it may start with dashes.
            guard index < arguments.count, isArgument || !arguments[index].hasPrefix("--") else {
                throw UsageError(description: "\(option) needs a value")
            }
            return arguments[index]
        }
        func number(_ option: String) throws -> Double { try positive(try value(for: option), for: option) }
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
                case "--root": root = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                case "--output": output = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                case "--work-dir": options.workDirectory = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                case "--sources": sources.append(try value(for: argument))
                case "--target": options.targets.append(try value(for: argument))
                case "--tags": options.tags = try value(for: argument)
                case "--format": options.format = try format(named: try value(for: argument))
                case "--max-mutants": options.maxMutants = Int(try number(argument))
                case "--timeout-multiplier": options.timeoutMultiplier = try number(argument)
                case "--minimum-timeout": options.minimumTimeout = try number(argument)
                case "--baseline-runs": options.baselineRuns = Int(try number(argument))
                case "--swift": options.swift = try value(for: argument)
                case "--dry-run": options.dryRun = true
                case "--disable-prebuilts": options.disablePrebuilts = true
                case "--project", "--workspace", "--scheme", "--destination": xcode.values[argument] = try value(for: argument)
                case "--test-target": xcode.testTargets.append(try value(for: argument))
                case "--xcodebuild": options.xcodebuild = try value(for: argument)
                case "--xcodebuild-arg": xcode.arguments.append(try value(for: argument))
                case "--bazel-target": options.bazelTarget = BazelRunner.Target(label: try value(for: argument))
                case "--bazel-arg": bazelArguments.append(try value(for: argument, isArgument: true))
                case "--bazel": options.bazel = try value(for: argument)
                case "--bazel-disk-cache": options.bazelDiskCache = URL(fileURLWithPath: try value(for: argument)).standardizedFileURL
                default: throw UsageError(description: "Unknown option \(argument)")
            }
            index += 1
        }
        // The package is the current folder unless --root names another.
        let package = root ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
        options.root = package
        options.output = output ?? package.appendingPathComponent(".build/mutation-testing")
        if !sources.isEmpty {
            options.sources = sources
            options.findsSources = false
        }
        try options.applyXcode(xcode)
        try options.applyBazel(arguments: bazelArguments)
        return options
    }

    private static func positive(_ text: String, for option: String) throws -> Double {
        guard let number = Double(text), number > 0 else { throw UsageError(description: "\(option) needs a number above 0, not \"\(text)\"") }
        return number
    }

    private static func format(named name: String) throws -> Format {
        guard let format = Format(rawValue: name) else { throw UsageError(description: "--format is text or xcode, not \"\(name)\"") }
        return format
    }

    /// The Xcode target the options name, `nil` when none of them does.
    private static func xcodeTarget(_ input: XcodeInput) throws -> XcodebuildRunner.Target? {
        let (values, testTargets, arguments) = (input.values, input.testTargets, input.arguments)
        guard !values.isEmpty || !testTargets.isEmpty || !arguments.isEmpty else { return nil }
        guard values["--project"] == nil || values["--workspace"] == nil else {
            throw UsageError(description: "Pass --project or --workspace, not both")
        }
        guard let container = values["--project"] ?? values["--workspace"] else {
            throw UsageError(description: "--scheme, --destination, --test-target and --xcodebuild-arg need --project or --workspace")
        }
        guard let scheme = values["--scheme"] else { throw UsageError(description: "--project and --workspace need --scheme") }
        guard let destination = values["--destination"] else {
            throw UsageError(description: "--project and --workspace need --destination, such as \"platform=macOS\"")
        }
        return XcodebuildRunner.Target(container: container, scheme: scheme, destination: destination, testTargets: testTargets, arguments: arguments)
    }

    public init(root: URL) {
        self.root = root
        output = root.appendingPathComponent(".build/mutation-testing")
    }

    /// The runner for these options: `bazel` when they name a Bazel target, `xcodebuild` when they name a scheme, and SwiftPM otherwise.
    public func makeRunner(commands: CommandRunning = ProcessRunner()) -> TestRunner {
        if let bazelTarget {
            return BazelRunner(target: bazelTarget, bazel: bazel, diskCache: bazelDiskCache ?? BazelRunner.defaultDiskCache, commands: commands)
        }
        if let xcode {
            return XcodebuildRunner(target: xcode, xcodebuild: xcodebuild, commands: commands)
        }
        return SwiftPMRunner(options: self, commands: commands)
    }

    /// Sets `xcode` from the Xcode options of the command line. An Xcode project has no package to describe, so its sources
    /// are the folders `--sources` names, and `--target` has no targets to name.
    private mutating func applyXcode(_ input: XcodeInput) throws {
        xcode = try Self.xcodeTarget(input)
        guard xcode != nil else { return }
        guard targets.isEmpty else { throw UsageError(description: "--target names a package's targets: with --project or --workspace, pass --sources") }
        findsSources = false
    }

    /// Sets the Bazel target's arguments from `--bazel-arg`. A Bazel workspace has no package to describe either, so its sources
    /// are the folders `--sources` names, and it can't also be an Xcode project.
    private mutating func applyBazel(arguments: [String]) throws {
        guard var target = bazelTarget else {
            guard arguments.isEmpty, bazel == "bazel", bazelDiskCache == nil else {
                throw UsageError(description: "--bazel, --bazel-arg and --bazel-disk-cache need --bazel-target")
            }
            return
        }
        guard xcode == nil else { throw UsageError(description: "Pass --bazel-target or --project and --workspace, not both") }
        guard targets.isEmpty else { throw UsageError(description: "--target names a package's targets: with --bazel-target, pass --sources") }
        guard findsSources == false else { throw UsageError(description: "--bazel-target needs --sources, the folders of the code to mutate") }
        target.arguments = arguments
        bazelTarget = target
    }
}
