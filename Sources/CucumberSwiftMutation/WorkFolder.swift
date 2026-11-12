//
//  WorkFolder.swift
//  CucumberSwiftMutation
//

#if os(macOS) || os(Linux)
import Foundation

/// The temporary copy of the project that a run mutates, and the lock file that lets the next run clean up
/// after a run that was killed. The user's own files are never mutated, so nothing needs reverting.
public struct WorkFolder {
    public enum Failure: Error, Equatable, CustomStringConvertible {
        case noWritableFolder(tried: [String])
        case anotherRunIsActive(pid: Int32)
        case copyFailed(String)
        case pathHasSpace(String)
        case pathInBuildFolder(String)

        public var description: String {
            switch self {
                case .noWritableFolder(let tried):
                    let list = tried.joined(separator: ", ")
                    return "No folder for the temporary copy is writable. Tried: \(list). Pass --work-dir with a folder you can write to."
                case .anotherRunIsActive(let pid):
                    return "Another mutation run (process \(pid)) is still active for this package."
                case .copyFailed(let message):
                    return "Couldn't copy the project: \(message)"
                case .pathInBuildFolder(let path):
                    return "The folder for the temporary copy is in a .build folder (\(path)), and code coverage leaves out the code "
                        + "there, so no scenario would run a mutant. Pass --work-dir with a path outside .build."
                case .pathHasSpace(let path):
                    return "The folder for the temporary copy has a space in its path (\(path)), and Swift Testing finds no tests "
                        + "in a package whose path has one. Pass --work-dir with a path that has no space."
            }
        }
    }

    /// What the lock file records.
    struct Lock: Codable, Equatable {
        var pid: Int32
        /// The folder that holds the copy, which the next run removes if this process is gone.
        var folder: String
    }

    /// The prefix of every folder this tool creates, which it checks before it removes one.
    static let folderPrefix = "mutation-copy-"

    /// The folder that holds the copy.
    public let folder: URL
    /// The copy of the project.
    public let copy: URL
    private let lockFile: URL

    /// The folder for the temporary copy: `explicit` when given, then the temporary folder, then the user's caches. Never
    /// a folder in the package at `root`, nor one in a `.build` folder: code coverage leaves out the code under `.build`,
    /// where dependencies are, so no scenario would seem to run a mutant.
    public static func chooseLocation(explicit: URL?,
                                      root: URL,
                                      temporary: URL = URL(fileURLWithPath: NSTemporaryDirectory()),
                                      caches: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first) throws -> URL {
        if let explicit {
            if explicit.path.contains(" ") { throw Failure.pathHasSpace(explicit.path) }
            if explicit.pathComponents.contains(".build") { throw Failure.pathInBuildFolder(explicit.path) }
        }
        let candidates = [explicit, temporary.appendingPathComponent("cucumberswift-mutation"), caches?.appendingPathComponent("cucumberswift-mutation")]
            .compactMap { $0 }
        let inPackage = root.standardizedFileURL.path + "/"
        // A folder with a space in its path would make Swift Testing find no tests in the copy, so it is skipped.
        for candidate in candidates where !candidate.path.contains(" ") && !candidate.pathComponents.contains(".build")
            && !(candidate.standardizedFileURL.path + "/").hasPrefix(inPackage) && isWritable(candidate) {
            return candidate
        }
        throw Failure.noWritableFolder(tried: candidates.map(\.path))
    }

    static func isWritable(_ folder: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let probe = folder.appendingPathComponent(".probe-\(UUID().uuidString)")
            try Data().write(to: probe)
            try fileManager.removeItem(at: probe)
            return true
        } catch {
            return false
        }
    }

    /// Removes the folder of a run that was killed, when the lock file in `lockFolder` names a process that is
    /// gone. Returns the folder it removed. Throws when the process is still running.
    @discardableResult
    public static func cleanUpAfterDeadRun(lockFolder: URL, isAlive: (Int32) -> Bool = processIsAlive) throws -> URL? {
        let lockFile = lockFolder.appendingPathComponent("mutation.lock")
        guard let data = try? Data(contentsOf: lockFile), let lock = try? JSONDecoder().decode(Lock.self, from: data) else {
            return nil
        }
        if lock.pid != getpid(), isAlive(lock.pid) { throw Failure.anotherRunIsActive(pid: lock.pid) }
        let folder = URL(fileURLWithPath: lock.folder)
        // The lock file is data. Remove only a folder that this tool made, never whatever a lock names.
        if folder.lastPathComponent.hasPrefix(folderPrefix) { remove(folder) }
        try? FileManager.default.removeItem(at: lockFile)
        return folder.lastPathComponent.hasPrefix(folderPrefix) ? folder : nil
    }

    public static func processIsAlive(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }

    /// Clones with copy-on-write where the file system can, and copies otherwise.
    private static func clone(_ source: URL, to destination: URL, runner: CommandRunning) throws {
        let result = runner.run("/bin/cp", ["-c", "-R", source.path, destination.path], in: source.deletingLastPathComponent(), environment: [:], timeout: nil)
        if !result.succeeded {
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                throw Failure.copyFailed("\(source.path): \(error.localizedDescription)")
            }
        }
    }

    /// Makes the files writable first, because some build and checkout files are read-only.
    private static func remove(_ folder: URL) {
        guard FileManager.default.fileExists(atPath: folder.path) else { return }
        _ = ProcessRunner(ignoresCancellation: true).run("/bin/chmod", ["-R", "u+w", folder.path], in: folder.deletingLastPathComponent(), environment: [:], timeout: 120)
        try? FileManager.default.removeItem(at: folder)
    }

    /// Copies the package at `root` to `copy`, without the folders a build or a checkout makes.
    private static func copyProject(_ root: URL, to copy: URL, excluding: [String], runner: CommandRunning) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: copy, withIntermediateDirectories: true)
        let top = try fileManager.contentsOfDirectory(atPath: root.path)
        for name in top.sorted() where !ProjectFingerprint.ignoredFolders.contains(name) && !name.hasPrefix("bazel-") && !excluding.contains(name) {
            try clone(root.appendingPathComponent(name), to: copy.appendingPathComponent(name), runner: runner)
        }
        // The dependencies SwiftPM already checked out, so that the copy builds without the network.
        let build = root.appendingPathComponent(".build")
        for name in ["checkouts", "repositories", "workspace-state.json"] where fileManager.fileExists(atPath: build.appendingPathComponent(name).path) {
            try fileManager.createDirectory(at: copy.appendingPathComponent(".build"), withIntermediateDirectories: true)
            try clone(build.appendingPathComponent(name), to: copy.appendingPathComponent(".build/\(name)"), runner: runner)
        }
    }

    /// Writes the lock file, then copies the project into a new folder inside `location`. `excluding` names the
    /// top-level files and folders the copy leaves out, besides the ones every run leaves out.
    public init(copying root: URL, into location: URL, lockFolder: URL, excluding: [String] = [], runner: CommandRunning = ProcessRunner()) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: lockFolder, withIntermediateDirectories: true)
        folder = location.appendingPathComponent("\(Self.folderPrefix)\(getpid())-\(UUID().uuidString.prefix(8))")
        // Not the package's own folder name: it may have a space in it.
        copy = folder.appendingPathComponent("package")
        lockFile = lockFolder.appendingPathComponent("mutation.lock")
        // The lock first: a run killed during the copy still leaves the next run something to clean up.
        try JSONEncoder().encode(Lock(pid: getpid(), folder: folder.path)).write(to: lockFile)
        do {
            try Self.copyProject(root, to: copy, excluding: excluding, runner: runner)
        } catch {
            // No caller gets a WorkFolder to remove, so the partial copy and the lock go now.
            Self.remove(folder)
            try? fileManager.removeItem(at: lockFile)
            throw error
        }
    }

    /// Deletes the copy and the lock file. Safe to call more than once, and from a signal handler's queue.
    public func remove() {
        Self.remove(folder)
        try? FileManager.default.removeItem(at: lockFile)
    }
}
#endif
