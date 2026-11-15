//
//  ProjectFingerprint.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import CryptoKit
import Foundation

/// What identifies the user's project before a run and after it. A run changes nothing in it, so the two
/// fingerprints must be equal; if they aren't, the tool has a bug, and the run fails and names the file.
public struct ProjectFingerprint: Equatable, Sendable {
    /// The folders a run neither copies nor compares: version control, build output and editor state.
    public static let ignoredFolders: Set<String> = [".git", ".build", ".swiftpm", "DerivedData"]

    /// The SHA-256 of each file's relative path and contents, by path. Not the build folders.
    public let files: [String: String]
    /// `git status --porcelain`, `git ls-files -s` and `git rev-parse HEAD`, when the project is in a git
    /// work tree. A mutation run never stages, commits or checks out anything.
    public let git: [String]

    public static func take(of root: URL, runner: CommandRunning = ProcessRunner(ignoresCancellation: true)) -> ProjectFingerprint {
        var files = [String: String]()
        let fileManager = FileManager.default
        // The real path: the folders under /var are really under /private/var, and the enumerator reports those.
        let real = root.path.withCString { pointer -> String in
            guard let resolved = realpath(pointer, nil) else { return root.path }
            defer { free(resolved) }
            return String(cString: resolved)
        }
        let prefix = real + "/"
        if let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: real),
                                                   includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                                                   options: []) {
            for case let url as URL in enumerator {
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if values?.isDirectory == true, values?.isSymbolicLink != true {
                    if ignoredFolders.contains(url.lastPathComponent) || url.lastPathComponent.hasPrefix("bazel-") {
                        enumerator.skipDescendants()
                    }
                    continue
                }
                let path = url.path.hasPrefix(prefix) ? String(url.path.dropFirst(prefix.count)) : url.path
                if values?.isSymbolicLink == true {
                    let target = (try? fileManager.destinationOfSymbolicLink(atPath: url.path)) ?? ""
                    files[path] = "link:" + target
                } else if let data = try? Data(contentsOf: url) {
                    files[path] = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                }
            }
        }
        return ProjectFingerprint(files: files, git: gitState(of: root, runner: runner))
    }

    private static func gitState(of root: URL, runner: CommandRunning) -> [String] {
        guard fileManager(hasGitIn: root) else { return [] }
        return [["status", "--porcelain"], ["ls-files", "-s"], ["rev-parse", "HEAD"]].map {
            runner.run("/usr/bin/git", $0, in: root, environment: [:], timeout: 60).output
        }
    }

    private static func fileManager(hasGitIn root: URL) -> Bool {
        FileManager.default.fileExists(atPath: root.appendingPathComponent(".git").path)
    }

    /// The differences from `other`, one line each: the files that changed, appeared or disappeared, and
    /// whether git's view changed.
    public func differences(from other: ProjectFingerprint) -> [String] {
        var lines = [String]()
        for path in Set(files.keys).union(other.files.keys).sorted() where files[path] != other.files[path] {
            lines.append(path)
        }
        if git != other.git { lines.append("git status, index or HEAD") }
        return lines
    }
}
#endif
