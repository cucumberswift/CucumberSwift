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

    /// What every `swift build` and `swift test` in the copy gets: the sandbox is off because SwiftPM can't
    /// nest its own inside the plugin's.
    var swiftArguments: [String] {
        ["--disable-sandbox"] + (disablePrebuilts ? ["--disable-experimental-prebuilts"] : [])
    }

    public static func parse(_ arguments: [String]) throws -> MutationOptions {
        var root: URL?
        var output: URL?
        var options = MutationOptions(root: URL(fileURLWithPath: "."))
        var sources = [String]()
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
                case "--target": options.targets.append(try value(for: argument))
                case "--tags": options.tags = try value(for: argument)
                case "--format":
                    let name = try value(for: argument)
                    guard let format = Format(rawValue: name) else { throw UsageError(description: "--format is text or xcode, not \"\(name)\"") }
                    options.format = format
                case "--max-mutants": options.maxMutants = Int(try number(argument))
                case "--timeout-multiplier": options.timeoutMultiplier = try number(argument)
                case "--minimum-timeout": options.minimumTimeout = try number(argument)
                case "--baseline-runs": options.baselineRuns = Int(try number(argument))
                case "--swift": options.swift = try value(for: argument)
                case "--dry-run": options.dryRun = true
                case "--disable-prebuilts": options.disablePrebuilts = true
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
        return options
    }

    public init(root: URL) {
        self.root = root
        output = root.appendingPathComponent(".build/mutation-testing")
    }
}
