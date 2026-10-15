//
//  MacroConversionTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// The command on files and folders: what it writes, what it reports, and how it ends.
final class MacroConversionTests: XCTestCase {
    private let convertible = """
        import CucumberSwift

        Given("I have {int} cukes") { match, _ in
            let count = try match.first(\\.int)
            use(count)
        }
        """

    private let converted = """
        import CucumberSwift
        import CucumberSwiftMacros

        #Given("I have {int} cukes") { (count: Int) in
            use(count)
        }
        """

    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("MacroConversionTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: folder)
    }

    private func write(_ text: String, to path: String) throws -> URL {
        let url = folder.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func read(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    func testRewritesTheSwiftFilesInAFolderAndReportsThem() throws {
        let steps = try write(convertible, to: "Tests/Steps.swift")
        let run = try ConverterTool.run([folder.path])
        XCTAssertEqual(run.status, 0)
        XCTAssertEqual(try read(steps), converted)
        XCTAssertTrue(run.output.contains("\(steps.path):3: converted Given(\"I have {int} cukes\")"), run.output)
        XCTAssertTrue(run.output.hasSuffix("Converted 1 step definition in 1 of 1 Swift file. Left 0 unchanged.\n"), run.output)
    }

    func testDryRunReportsWithoutChangingAFile() throws {
        let steps = try write(convertible, to: "Steps.swift")
        let run = try ConverterTool.run(["--dry-run", folder.path])
        XCTAssertEqual(run.status, 0)
        XCTAssertEqual(try read(steps), convertible)
        XCTAssertTrue(run.output.contains("converted Given"), run.output)
        XCTAssertTrue(run.output.hasSuffix("Would convert 1 step definition in 1 of 1 Swift file. Left 0 unchanged.\n"), run.output)
    }

    func testAPathThatDoesNotExistFails() throws {
        let missing = folder.appendingPathComponent("Missing").path
        let run = try ConverterTool.run([missing])
        XCTAssertEqual(run.status, 1)
        XCTAssertTrue(run.output.contains("\(missing): no such file or folder"), run.output)
    }

    func testMarksAStepDefinitionItLeavesAndWritesOnlyAFileThatChanged() throws {
        let unchangeable = """
            import CucumberSwift

            Given("I have {int} cukes") { match, _ in
                use(match)
            }
            """
        let marked = try write(unchangeable, to: "Marked.swift")
        let other = try write("let value = 1\n", to: "Other.swift")
        let before = try FileManager.default.attributesOfItem(atPath: other.path)[.modificationDate] as? Date
        let run = try ConverterTool.run([folder.path])
        XCTAssertEqual(run.status, 0)
        XCTAssertEqual(try read(marked), """
            import CucumberSwift

            #warning("Convert to Gherkin Macros by hand: it passes match on to other code")
            Given("I have {int} cukes") { match, _ in
                use(match)
            }
            """)
        XCTAssertEqual(try read(other), "let value = 1\n")
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: other.path)[.modificationDate] as? Date, before)
        XCTAssertTrue(run.output.contains("left unchanged Given(\"I have {int} cukes\"): it passes match on to other code"), run.output)
        XCTAssertTrue(run.output.hasSuffix("Converted 0 step definitions in 1 of 2 Swift files. Left 1 unchanged, 1 marked with #warning.\n"), run.output)
    }

    func testDryRunSaysHowManyItWouldMarkAndChangesNothing() throws {
        let source = convertible.replacingOccurrences(of: "use(count)", with: "use(match)")
        let steps = try write(source, to: "Steps.swift")
        let run = try ConverterTool.run(["--dry-run", folder.path])
        XCTAssertEqual(try read(steps), source)
        XCTAssertTrue(run.output.hasSuffix("Would convert 0 step definitions in 1 of 1 Swift file. Left 1 unchanged, 1 to mark with #warning.\n"), run.output)
    }

    func testSkipsBuildAndDependencyFolders() throws {
        let skipped = try ["Pods/Steps.swift", ".build/Steps.swift", "Carthage/Steps.swift", "A/DerivedData/Steps.swift"]
            .map { try write(convertible, to: $0) }
        let counted = try write(convertible, to: "Sources/Steps.swift")
        let run = try ConverterTool.run([folder.path])
        XCTAssertEqual(run.status, 0)
        XCTAssertEqual(try read(counted), converted)
        for url in skipped {
            XCTAssertEqual(try read(url), convertible, url.path)
        }
        XCTAssertTrue(run.output.hasSuffix("Converted 1 step definition in 1 of 1 Swift file. Left 0 unchanged.\n"), run.output)
    }

    func testConvertsAFileGivenByName() throws {
        let steps = try write(convertible, to: "Steps.swift")
        let run = try ConverterTool.run([steps.path])
        XCTAssertEqual(run.status, 0)
        XCTAssertEqual(try read(steps), converted)
    }

    func testCountsEachStepDefinitionInTheSummary() throws {
        _ = try write(convertible + "\n\n" + convertible, to: "A.swift")
        _ = try write("let a = 1\n", to: "B.swift")
        let run = try ConverterTool.run(["--dry-run", folder.path])
        XCTAssertTrue(run.output.hasSuffix("Would convert 2 step definitions in 1 of 2 Swift files. Left 0 unchanged.\n"), run.output)
    }
}

/// `--path`: one file, one folder or everything, alone or with the files of the targets.
extension MacroConversionTests {
    /// Three files in two folders, as a project's targets would hold them.
    private struct Project {
        let a: URL
        let b: URL
        let nested: URL
    }

    private func writeProject() throws -> Project {
        Project(a: try write(convertible, to: "Sources/A/A.swift"),
                b: try write(convertible, to: "Sources/B/B.swift"),
                nested: try write(convertible, to: "Sources/B/More/Nested.swift"))
    }

    func testPathConvertsOnlyThatFile() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let nested = project.nested
        let run = try ConverterTool.run(["--root", folder.path, "--path", "Sources/A/A.swift"])
        XCTAssertEqual(run.status, 0, run.output)
        XCTAssertEqual(try read(a), converted)
        XCTAssertEqual(try read(b), convertible)
        XCTAssertEqual(try read(nested), convertible)
        XCTAssertTrue(run.output.hasSuffix("Converted 1 step definition in 1 of 1 Swift file. Left 0 unchanged.\n"), run.output)
    }

    func testPathConvertsOnlyTheFilesUnderThatFolder() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let nested = project.nested
        let run = try ConverterTool.run(["--root", folder.path, "--path", "Sources/B"])
        XCTAssertEqual(run.status, 0, run.output)
        XCTAssertEqual(try read(a), convertible)
        XCTAssertEqual(try read(b), converted)
        XCTAssertEqual(try read(nested), converted)
        XCTAssertTrue(run.output.hasSuffix("Converted 2 step definitions in 2 of 2 Swift files. Left 0 unchanged.\n"), run.output)
    }

    func testPathIsRepeatableAndTakesAbsolutePaths() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let nested = project.nested
        let run = try ConverterTool.run(["--root", folder.path, "--path", a.path, "--path", "Sources/B/More"])
        XCTAssertEqual(run.status, 0, run.output)
        XCTAssertEqual(try read(a), converted)
        XCTAssertEqual(try read(b), convertible)
        XCTAssertEqual(try read(nested), converted)
    }

    func testWithoutPathItConvertsEveryFileItIsGiven() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let nested = project.nested
        let run = try ConverterTool.run(["--root", folder.path, folder.path])
        XCTAssertEqual(run.status, 0, run.output)
        for url in [a, b, nested] {
            XCTAssertEqual(try read(url), converted)
        }
        XCTAssertTrue(run.output.hasSuffix("Converted 3 step definitions in 3 of 3 Swift files. Left 0 unchanged.\n"), run.output)
    }

    func testDryRunWithPathReportsTheSameScopeAndChangesNothing() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let nested = project.nested
        let dry = try ConverterTool.run(["--dry-run", "--root", folder.path, "--path", "Sources/B"])
        XCTAssertEqual(dry.status, 0, dry.output)
        for url in [a, b, nested] {
            XCTAssertEqual(try read(url), convertible)
        }
        XCTAssertTrue(dry.output.hasSuffix("Would convert 2 step definitions in 2 of 2 Swift files. Left 0 unchanged.\n"), dry.output)
        XCTAssertFalse(dry.output.contains("A.swift"), dry.output)
        let real = try ConverterTool.run(["--root", folder.path, "--path", "Sources/B"])
        XCTAssertEqual(real.output.replacingOccurrences(of: "Converted", with: "Would convert"), dry.output)
    }

    func testAPathOutsideTheProjectIsAnErrorThatNamesItAndChangesNothing() throws {
        let project = try writeProject()
        let a = project.a
        let outside = FileManager.default.temporaryDirectory.appendingPathComponent("Outside-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outside) }
        let elsewhere = outside.appendingPathComponent("Elsewhere.swift")
        try convertible.write(to: elsewhere, atomically: true, encoding: .utf8)
        let run = try ConverterTool.run([
            "--root", folder.path, "--path", "Sources/A/A.swift",
            "--path", elsewhere.path, "--path", "../Escaped"
        ])
        XCTAssertEqual(run.status, 1)
        XCTAssertTrue(run.output.contains("\(elsewhere.path): is outside the package or project"), run.output)
        XCTAssertTrue(run.output.contains("../Escaped: is outside the package or project"), run.output)
        XCTAssertFalse(run.output.contains("Converted"), run.output)
        XCTAssertEqual(try read(a), convertible)
        XCTAssertEqual(try read(elsewhere), convertible)
    }

    func testAFolderNextToTheProjectWithTheSameNamePrefixIsOutside() throws {
        let sibling = URL(fileURLWithPath: folder.path + "-Other")
        try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: sibling) }
        let run = try ConverterTool.run(["--root", folder.path, "--path", sibling.path])
        XCTAssertEqual(run.status, 1)
        XCTAssertTrue(run.output.contains("\(sibling.path): is outside the package or project"), run.output)
    }

    func testAPathThatIsNotThereOrNotSwiftIsAnErrorThatNamesIt() throws {
        let project = try writeProject()
        let a = project.a
        _ = try write("# Notes\n", to: "README.md")
        let run = try ConverterTool.run([
            "--root", folder.path, "--path", "Sources/Missing", "--path", "README.md",
            "--path", "Sources/A/A.swift"
        ])
        XCTAssertEqual(run.status, 1)
        XCTAssertTrue(run.output.contains("Sources/Missing: no such file or folder"), run.output)
        XCTAssertTrue(run.output.contains("README.md: is not a Swift file or a folder"), run.output)
        XCTAssertEqual(try read(a), convertible, "a bad path must stop the run before any file changes")
    }

    func testPathWithTargetsConvertsOnlyTheChosenFilesThatBelongToThem() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let nested = project.nested
        // The way Xcode runs it: a target chosen in the dialog, and --path from its Arguments.
        let run = try ConverterTool.run([
            "--root", folder.path, "--path", "Sources", "--path", "Sources/B/More",
            folder.appendingPathComponent("Sources/B").path
        ])
        XCTAssertEqual(run.status, 0, run.output)
        XCTAssertEqual(try read(a), convertible, "A isn't in the target given, so a path that holds it doesn't convert it")
        XCTAssertEqual(try read(b), converted)
        XCTAssertEqual(try read(nested), converted)
        XCTAssertTrue(run.output.hasSuffix("Converted 2 step definitions in 2 of 2 Swift files. Left 0 unchanged.\n"), run.output)
    }

    func testPathWithTargetsConvertsOneFileOfTheTarget() throws {
        let project = try writeProject()
        let b = project.b
        let nested = project.nested
        let run = try ConverterTool.run([
            "--root", folder.path, "--path", "Sources/B/B.swift",
            folder.appendingPathComponent("Sources/B").path
        ])
        XCTAssertEqual(run.status, 0, run.output)
        XCTAssertEqual(try read(b), converted)
        XCTAssertEqual(try read(nested), convertible)
    }

    func testAPathOutsideTheTargetsChosenIsAnErrorThatNamesItAndChangesNothing() throws {
        let project = try writeProject()
        let a = project.a
        let b = project.b
        let run = try ConverterTool.run([
            "--root", folder.path, "--path", "Sources/B/B.swift", "--path", "Sources/A",
            folder.appendingPathComponent("Sources/B").path
        ])
        XCTAssertEqual(run.status, 1)
        XCTAssertTrue(run.output.contains("Sources/A: has no Swift files in the targets chosen"), run.output)
        XCTAssertFalse(run.output.contains("Sources/B/B.swift: has no"), run.output)
        XCTAssertEqual(try read(a), convertible)
        XCTAssertEqual(try read(b), convertible, "the run must stop before it changes a file")
    }

    func testDryRunWithTargetsAndPathReportsTheSameScope() throws {
        _ = try writeProject()
        let arguments = ["--root", folder.path, "--path", "Sources/B/More", folder.appendingPathComponent("Sources/B").path]
        let dry = try ConverterTool.run(["--dry-run"] + arguments)
        let real = try ConverterTool.run(arguments)
        XCTAssertTrue(dry.output.hasSuffix("Would convert 1 step definition in 1 of 1 Swift file. Left 0 unchanged.\n"), dry.output)
        XCTAssertEqual(real.output.replacingOccurrences(of: "Converted", with: "Would convert"), dry.output)
    }
}
#endif
