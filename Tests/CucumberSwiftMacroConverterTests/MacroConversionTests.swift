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
#endif
