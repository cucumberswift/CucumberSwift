//
//  WorkFolderTests.swift
//  CucumberSwiftMutationTests
//

import XCTest
@testable import CucumberSwiftMutation

final class WorkFolderTests: TemporaryFolderTestCase {
    private func lockFolder() -> URL { folder.appendingPathComponent("reports") }

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
        // A kill -9 leaves the copy and the lock file behind. The next run sees that the process is gone.
        let removed = try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder(), isAlive: { _ in false })
        XCTAssertEqual(removed?.lastPathComponent, work.folder.lastPathComponent)
        XCTAssertFalse(FileManager.default.fileExists(atPath: work.folder.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: lockFolder().appendingPathComponent("mutation.lock").path))
    }

    func testARunThatIsStillActiveIsNotTouched() throws {
        let root = try makePackage()
        let work = try WorkFolder(copying: root, into: folder.appendingPathComponent("work"), lockFolder: lockFolder())
        // Rewrite the lock as another process's.
        let lock = lockFolder().appendingPathComponent("mutation.lock")
        try JSONEncoder().encode(WorkFolder.Lock(pid: getpid() + 1, folder: work.folder.path)).write(to: lock)
        XCTAssertThrowsError(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder(), isAlive: { _ in true })) {
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
        XCTAssertNil(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder(), isAlive: { _ in false }))
        XCTAssertTrue(FileManager.default.fileExists(atPath: precious.path), "A lock file is data, and must not choose what gets deleted")
    }

    func testNoLockFileMeansNothingToCleanUp() throws {
        XCTAssertNil(try WorkFolder.cleanUpAfterDeadRun(lockFolder: lockFolder(), isAlive: { _ in false }))
    }

    func testChoosesTheExplicitFolderFirst() throws {
        let root = try makePackage()
        let explicit = folder.appendingPathComponent("chosen")
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: explicit, root: root), explicit)
    }

    func testFallsBackToTheBuildFolderThenTheTemporaryFolder() throws {
        let root = try makePackage()
        let readOnly = folder.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnly, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: readOnly.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnly.path) }
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: readOnly.appendingPathComponent("inside"), root: root).path,
                       root.appendingPathComponent(".build/mutation-testing/work").path)
        // With the package's own folder unwritable too, the temporary folder is next.
        let lockedPackage = folder.appendingPathComponent("locked")
        try FileManager.default.createDirectory(at: lockedPackage, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: lockedPackage.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: lockedPackage.path) }
        let temporary = folder.appendingPathComponent("temporary")
        XCTAssertEqual(try WorkFolder.chooseLocation(explicit: nil, root: lockedPackage, temporary: temporary).path,
                       temporary.appendingPathComponent("cucumberswift-mutation").path)
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
        XCTAssertThrowsError(try WorkFolder.chooseLocation(explicit: locked.appendingPathComponent("a"), root: locked, temporary: locked.appendingPathComponent("b"))) {
            guard case .noWritableFolder(let tried)? = $0 as? WorkFolder.Failure else { return XCTFail("Wrong error: \($0)") }
            XCTAssertEqual(tried.count, 3)
        }
    }
}
