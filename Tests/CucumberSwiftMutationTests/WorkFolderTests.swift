//
//  WorkFolderTests.swift
//  CucumberSwiftMutationTests
//

#if os(macOS) || os(Linux)
import XCTest
@testable import CucumberSwiftMutation

/// What a run on another thread did, for a test of two runs at once.
private final class RunOutcome: @unchecked Sendable {
    var cleanupError: Error?
    var wroteItsLock = false
}

/// A runner that does `during` instead of each command, and fails it, so that a copy goes on with FileManager.
private final class PausingRunner: CommandRunning, @unchecked Sendable {
    private let during: () -> Void

    init(during: @escaping () -> Void) {
        self.during = during
    }

    func run(_: String, _: [String], in _: URL, environment _: [String: String], timeout _: TimeInterval?) -> CommandResult {
        during()
        return .finished(1)
    }
}

final class WorkFolderTests: TemporaryFolderTestCase {
    private func lockFolder() -> URL { folder.appendingPathComponent("reports") }

    func testARunThatFindsTheLockTakenStopsWithoutReplacingIt() throws {
        // Another run wrote the lock after this one checked for a dead run's lock.
        let root = try makePackage()
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        try FileManager.default.createDirectory(at: lockFolder(), withIntermediateDirectories: true)
        let holder = try JSONEncoder().encode(WorkFolder.Lock(pid: 4_242, folder: "/elsewhere/mutation-copy-4242"))
        try holder.write(to: lock)
        let location = folder.appendingPathComponent("work")
        XCTAssertThrowsError(try WorkFolder(copying: root, into: location, lockFolder: lockFolder())) {
            XCTAssertEqual($0 as? WorkFolder.Failure, .anotherRunIsActive(pid: 4_242))
        }
        XCTAssertEqual(try Data(contentsOf: lock), holder, "The other run's lock stays as it was")
        let left = (try? FileManager.default.contentsOfDirectory(atPath: location.path)) ?? []
        XCTAssertEqual(left.filter { $0.hasPrefix(WorkFolder.folderPrefix) }, [], "Nothing was copied")
    }

    func testACopyThatFailsLeavesNeitherThePartialCopyNorTheLock() throws {
        let location = folder.appendingPathComponent("work")
        let missing = folder.appendingPathComponent("no-such-package")
        XCTAssertThrowsError(try WorkFolder(copying: missing, into: location, lockFolder: lockFolder()))
        XCTAssertFalse(FileManager.default.fileExists(atPath: lockFolder().appendingPathComponent("mutation.lock").path))
        let left = (try? FileManager.default.contentsOfDirectory(atPath: location.path)) ?? []
        XCTAssertEqual(left.filter { $0.hasPrefix(WorkFolder.folderPrefix) }, [])
    }

    func testCopiesTheSourcesButNotTheGitOrBuildFolders() throws {
        let root = try makePackage()
        let location = try WorkFolder.chooseLocation(explicit: folder.appendingPathComponent("work"), root: root)
        let work = try WorkFolder(copying: root, into: location, lockFolder: lockFolder())
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: work.copy.appendingPathComponent("Sources/Voting/Voting.swift").path))
        XCTAssertTrue(fileManager.fileExists(atPath: work.copy.appendingPathComponent("Package.swift").path))
        XCTAssertFalse(fileManager.fileExists(atPath: work.copy.appendingPathComponent(".git").path))
        XCTAssertFalse(fileManager.fileExists(atPath: work.copy.appendingPathComponent(".build/debug").path))
    }

    func testChangingTheCopyLeavesTheOriginalAlone() throws {
        let root = try makePackage()
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        let copied = work.copy.appendingPathComponent("Sources/Voting/Voting.swift")
        try "changed".write(to: copied, atomically: true, encoding: .utf8)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent("Sources/Voting/Voting.swift")),
                       "public func canVote(age: Int) -> Bool { age >= 18 }\n")
    }

    func testRemoveDeletesTheCopyAndTheLockFile() throws {
        let root = try makePackage()
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        XCTAssertTrue(FileManager.default.fileExists(atPath: lockFolder().appendingPathComponent("mutation.lock").path))
        work.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: work.folder.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: lockFolder().appendingPathComponent("mutation.lock").path))
        work.remove()
    }

    func testRemovesACopyWithReadOnlyFiles() throws {
        let root = try makePackage()
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        let file = work.copy.appendingPathComponent("Sources/Voting/Voting.swift")
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: file.path)
        work.remove()
        XCTAssertFalse(FileManager.default.fileExists(atPath: work.folder.path))
    }

    func testTheNextRunRemovesTheCopyOfARunThatWasKilled() throws {
        let root = try makePackage()
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        // A kill -9 leaves the copy and the lock file behind. The next run sees that the process is gone. This process
        // holds the lock, so the lock is rewritten as a process that is gone.
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        try JSONEncoder().encode(WorkFolder.Lock(pid: 99_999_999, folder: work.folder.path)).write(to: lock)
        let removed = try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in false }
        XCTAssertEqual(removed?.lastPathComponent, work.folder.lastPathComponent)
        XCTAssertFalse(FileManager.default.fileExists(atPath: work.folder.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: lockFolder().appendingPathComponent("mutation.lock").path))
    }

    func testTwoRunsThatFindTheSameDeadLockLeaveExactlyOneOfThemHoldingTheLock() throws {
        try FileManager.default.createDirectory(at: lockFolder(), withIntermediateDirectories: true)
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        let dead: Int32 = 99_999_998
        try JSONEncoder().encode(WorkFolder.Lock(pid: dead, folder: "/nowhere/mutation-copy-dead")).write(to: lock)
        // Each run removes the dead lock, then writes its own, as WorkFolder.init does: never over another's.
        let firstLock = try JSONEncoder().encode(WorkFolder.Lock(pid: 77_777, folder: "/nowhere/mutation-copy-first"))
        let secondLock = try JSONEncoder().encode(WorkFolder.Lock(pid: 88_888, folder: "/nowhere/mutation-copy-second"))
        let secondReadTheDeadLock = DispatchSemaphore(value: 0)
        let firstTriedToWrite = DispatchSemaphore(value: 0)
        let secondDone = DispatchSemaphore(value: 0)
        let second = RunOutcome()
        let folder = lockFolder()
        // Run B starts while run A judges the dead lock. If B reads the dead lock too, it calls it dead only after A
        // has written its own lock: the order in which an unguarded B removes A's lock.
        _ = try WorkFolder.cleanUpAfterDeadRun(lockFolder: folder) { _ in
            DispatchQueue.global().async {
                do {
                    _ = try WorkFolder.cleanUpAfterDeadRun(lockFolder: folder) { pid in
                        guard pid == dead else { return true }
                        secondReadTheDeadLock.signal()
                        firstTriedToWrite.wait()
                        return false
                    }
                    try secondLock.write(to: lock, options: .withoutOverwriting)
                    second.wroteItsLock = true
                } catch {
                    second.cleanupError = error
                }
                secondDone.signal()
            }
            _ = secondReadTheDeadLock.wait(timeout: .now() + 1)
            return false
        }
        let firstWroteItsLock = (try? firstLock.write(to: lock, options: .withoutOverwriting)) != nil
        firstTriedToWrite.signal()
        XCTAssertEqual(secondDone.wait(timeout: .now() + 10), .success)
        XCTAssertNotEqual(firstWroteItsLock, second.wroteItsLock, "Exactly one run holds the lock")
        XCTAssertEqual(try Data(contentsOf: lock), firstWroteItsLock ? firstLock : secondLock, "The lock is the holder's")
        if let error = second.cleanupError as? WorkFolder.Failure {
            XCTAssertEqual(error, .anotherRunIsActive(pid: 77_777), "Run B found run A's lock")
        }
    }

    func testASecondRunInTheSameProcessLeavesTheFirstOnesLockAndCopy() throws {
        let root = try makePackage()
        let first = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        let held = try Data(contentsOf: lock)
        XCTAssertThrowsError(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in false }) {
            XCTAssertEqual($0 as? WorkFolder.Failure, .anotherRunIsActive(pid: getpid()))
        }
        XCTAssertEqual(try Data(contentsOf: lock), held, "The first run's lock stays")
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.copy.path), "The first run's copy stays")
        first.remove()
        XCTAssertNil(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in false }, "Once it's done, nothing is left")
    }

    func testACleanupInTheSameProcessDuringTheCopyLeavesTheLockAndTheCopy() throws {
        let root = try makePackage()
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        let folder = lockFolder()
        var cleanupError: Error?
        var lockDuringCopy = false
        // The copy runs `cp` through the runner, and a second run's cleanup runs then.
        let runner = PausingRunner {
            guard cleanupError == nil else { return }
            do { _ = try WorkFolder.cleanUpAfterDeadRun(lockFolder: folder) { _ in false } } catch { cleanupError = error }
            lockDuringCopy = FileManager.default.fileExists(atPath: lock.path)
        }
        let first = try WorkFolder(copying: root, into: self.folder.appendingPathComponent("work"), lockFolder: folder, runner: runner)
        XCTAssertEqual(cleanupError as? WorkFolder.Failure, .anotherRunIsActive(pid: getpid()))
        XCTAssertTrue(lockDuringCopy, "The first run's lock stayed during its copy")
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.copy.appendingPathComponent("Package.swift").path))
        first.remove()
    }

    func testALockWithThisProcesssIDThatNoRunHereHoldsIsADeadRuns() throws {
        // The system can give a dead run's process ID to a later process.
        let root = try makePackage()
        let dead = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        let lock = try Data(contentsOf: lockFolder().appendingPathComponent("mutation.lock"))
        dead.remove()
        try FileManager.default.createDirectory(at: dead.folder, withIntermediateDirectories: true)
        try Data().write(to: dead.folder.appendingPathComponent(WorkFolder.ownerMarker))
        try lock.write(to: lockFolder().appendingPathComponent("mutation.lock"))
        XCTAssertEqual(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in true }?.lastPathComponent, dead.folder.lastPathComponent)
    }

    func testALockThatNamesAFolderThisToolDidNotMakeDeletesNothing() throws {
        // A stale or planted lock can name any folder, even one whose name starts like a copy's.
        let notes = folder.appendingPathComponent("mutation-copy-notes")
        try FileManager.default.createDirectory(at: notes, withIntermediateDirectories: true)
        try "keep".write(to: notes.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: lockFolder(), withIntermediateDirectories: true)
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        try JSONEncoder().encode(WorkFolder.Lock(pid: 99_999_999, folder: notes.path)).write(to: lock)
        XCTAssertNil(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in false })
        XCTAssertTrue(FileManager.default.fileExists(atPath: notes.appendingPathComponent("notes.txt").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: lock.path), "The dead run's lock is gone")
    }

    func testARunThatIsStillActiveIsNotTouched() throws {
        let root = try makePackage()
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        // Rewrite the lock as another process's.
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        try JSONEncoder().encode(WorkFolder.Lock(pid: getpid() + 1, folder: work.folder.path)).write(to: lock)
        XCTAssertThrowsError(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in true }) {
            XCTAssertEqual($0 as? WorkFolder.Failure, .anotherRunIsActive(pid: getpid() + 1))
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: work.folder.path))
        work.remove()
    }

    func testNeverRemovesAFolderThatThisToolDidNotMake() throws {
        let precious = folder.appendingPathComponent("precious")
        try FileManager.default.createDirectory(at: precious, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: lockFolder(), withIntermediateDirectories: true)
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        try JSONEncoder().encode(WorkFolder.Lock(pid: 1, folder: precious.path)).write(to: lock)
        XCTAssertNil(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in false })
        XCTAssertTrue(FileManager.default.fileExists(atPath: precious.path), "A lock file is data, and must not choose what gets deleted")
    }

    func testNoLockFileMeansNothingToCleanUp() throws {
        XCTAssertNil(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder()) { _ in false })
    }

    func testChoosesTheExplicitFolderFirst() throws {
        let root = try makePackage()
        let explicit = folder.appendingPathComponent("chosen")
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: explicit, root: root), explicit)
    }

    func testFallsBackToTheTemporaryFolderThenTheCaches() throws {
        let root = try makePackage()
        let readOnly = folder.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnly, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: readOnly.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnly.path) }
        let temporary = folder.appendingPathComponent("temporary")
        let caches = folder.appendingPathComponent("caches")
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: readOnly.appendingPathComponent("inside"), root: root, temporary: temporary, caches: caches).path,
                       temporary.appendingPathComponent("cucumberswift-mutation").path)
        // With the temporary folder unwritable too, the user's caches are next.
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: nil, root: root, temporary: readOnly, caches: caches).path,
                       caches.appendingPathComponent("cucumberswift-mutation").path)
    }

    func testNeverPutsTheCopyInABuildFolderOrInThePackage() throws {
        let root = try makePackage()
        let inBuild = root.appendingPathComponent(".build/mutation-testing/work")
        XCTAssertThrowsError(try WorkFolder.chooseLocation(explicit: inBuild, root: root)) {
            XCTAssertEqual($0 as? WorkFolder.Failure, .pathInBuildFolder(inBuild.path))
        }
        // A temporary folder inside the package is skipped for the caches.
        let caches = folder.appendingPathComponent("caches")
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: nil, root: root, temporary: root.appendingPathComponent("tmp"), caches: caches).path,
                       caches.appendingPathComponent("cucumberswift-mutation").path)
    }

    func testRefusesAnExplicitFolderWithASpaceAndSkipsOtherCandidatesThatHaveOne() throws {
        let root = try makePackage()
        let spaced = folder.appendingPathComponent("with space")
        XCTAssertThrowsError(try WorkFolder.chooseLocation(explicit: spaced, root: root)) {
            XCTAssertEqual($0 as? WorkFolder.Failure, .pathHasSpace(spaced.path))
        }
        // A package in a folder with a space has a .build folder with a space in its path too: use the temporary folder.
        let packageWithSpace = folder.appendingPathComponent("My Package")
        try FileManager.default.createDirectory(at: packageWithSpace, withIntermediateDirectories: true)
        let temporary = folder.appendingPathComponent("temporary")
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: nil, root: packageWithSpace, temporary: temporary).path,
                       temporary.appendingPathComponent("cucumberswift-mutation").path)
    }

    func testTheCopyIsNamedWithoutTheProjectsFolderName() throws {
        let root = try makePackage(named: "My Voting Package")
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        XCTAssertEqual(work.copy.lastPathComponent, "package")
        XCTAssertFalse(work.copy.path.contains(" "))
    }

    func testStopsWhenNoFolderIsWritableAndNeverUsesThePackageItself() throws {
        let locked = folder.appendingPathComponent("locked")
        try FileManager.default.createDirectory(at: locked, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: locked.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locked.path) }
        let elsewhere = folder.appendingPathComponent("elsewhere")
        try FileManager.default.createDirectory(at: elsewhere, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: elsewhere.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: elsewhere.path) }
        XCTAssertThrowsError(try WorkFolder.chooseLocation(explicit: elsewhere.appendingPathComponent("a"),
                                                           root: locked,
                                                           temporary: elsewhere.appendingPathComponent("b"),
                                                           caches: elsewhere.appendingPathComponent("c"))) {
            guard case .noWritableFolder(let tried)? = $0 as? WorkFolder.Failure else { return XCTFail("Wrong error: \($0)") }
            XCTAssertEqual(tried.count, 3)
        }
    }
}
#endif
