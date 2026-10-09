//
//  SetupAdviceTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// What the command says when the project isn't set up for the macros, for each kind of project, and that it
/// then changes nothing. The tool says the same with the trait off, from the same code.
final class SetupAdviceTests: XCTestCase {
    private var folder = FileManager.default.temporaryDirectory

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("SetupAdviceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: folder)
    }

    @discardableResult
    private func create(_ path: String, _ text: String = "") throws -> URL {
        let url = folder.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func message(root: String? = nil) throws -> String {
        try ConverterTool.run(["--explain-setup", root ?? folder.path]).output
    }

    func testAPackageGetsTheChangeToItsManifest() throws {
        try create("Package.swift", "// swift-tools-version:6.1\nimport PackageDescription\n")
        let text = try message()
        XCTAssertTrue(text.contains("changed nothing"), text)
        XCTAssertTrue(text.contains("traits: [\"Macros\"]"), text)
        XCTAssertTrue(text.contains(".product(name: \"CucumberSwiftMacros\", package: \"CucumberSwift\")"), text)
        XCTAssertFalse(text.contains("raise it"), text)
        XCTAssertFalse(text.contains("Tuist"), text)
        XCTAssertFalse(text.contains("Xcode project"), text)
    }

    func testAPackageBeforeSwift61IsToldToRaiseItsToolsVersion() throws {
        try create("Package.swift", "// swift-tools-version: 5.9\nimport PackageDescription\n")
        let text = try message()
        XCTAssertTrue(text.contains("swift-tools-version is 5.9"), text)
        XCTAssertTrue(text.contains("// swift-tools-version:6.1"), text)
    }

    func testAPackageThatMentionsTheTraitAlreadyIsToldToCheckIt() throws {
        try create("Package.swift", "// swift-tools-version:6.1\n.package(path: \"../CucumberSwift\", traits: [\"Macros\"])\n")
        let text = try message()
        XCTAssertTrue(text.contains("already mentions \"Macros\""), text)
    }

    func testATuistProjectGetsTheChangeToProjectSwift() throws {
        try create("Project.swift")
        try create("Tuist.swift")
        let text = try message()
        XCTAssertTrue(text.contains("Project.swift"), text)
        XCTAssertTrue(text.contains(".package(product: \"CucumberSwiftMacros\")"), text)
        XCTAssertTrue(text.contains("Xcode 26.4 or later"), text)
        XCTAssertFalse(text.contains("Package.swift"), text)
    }

    func testAnXcodeProjectGetsBothWaysOfTurningTheTraitOn() throws {
        try create("App.xcodeproj/project.pbxproj")
        let text = try message()
        XCTAssertTrue(text.contains("Xcode 26.4 or later"), text)
        XCTAssertTrue(text.contains("MacrosTrait"), text)
        XCTAssertFalse(text.contains("Project.swift"), text)
        XCTAssertFalse(text.contains("Package.swift"), text)
    }

    func testAFolderWithSeveralKindsOfProjectListsEveryWay() throws {
        try create("Package.swift", "// swift-tools-version:6.1\n")
        try create("App.xcodeproj/project.pbxproj")
        let text = try message()
        XCTAssertTrue(text.contains("can't tell"), text)
        XCTAssertTrue(text.contains("In a Swift package"), text)
        XCTAssertTrue(text.contains("In an Xcode project"), text)
        XCTAssertTrue(text.contains("In a Tuist project"), text)
    }

    func testAFolderWithNoProjectListsEveryWay() throws {
        let text = try message(root: folder.appendingPathComponent("Empty").path)
        XCTAssertTrue(text.contains("can't tell"), text)
        XCTAssertTrue(text.contains("In a Tuist project"), text)
    }

    func testLooksForTheProjectInTheFoldersAboveTheTarget() throws {
        try create("Package.swift", "// swift-tools-version:6.1\n")
        try create("Tests/AppTests/Steps.swift")
        let text = try message(root: folder.appendingPathComponent("Tests/AppTests").path)
        XCTAssertTrue(text.contains("In a Swift package"), text)
        XCTAssertFalse(text.contains("can't tell"), text)
    }

    func testATargetWithoutTheMacrosProductChangesNothing() throws {
        try create("Package.swift", "// swift-tools-version:6.1\n")
        let source = "import CucumberSwift\n\nGiven(\"I have {int} cukes\") { match, _ in\n    let count = try match.first(\\.int)\n    use(count)\n}\n"
        let steps = try create("Tests/AppTests/Steps.swift", source)
        let run = try ConverterTool.run(["--root", folder.path, "--missing-macros", "AppTests=CucumberSwiftMacros", folder.path])
        XCTAssertEqual(run.status, 2)
        XCTAssertEqual(try String(contentsOf: steps, encoding: .utf8), source)
        XCTAssertTrue(run.output.contains("changed nothing"), run.output)
        XCTAssertTrue(run.output.contains("AppTests depends on the CucumberSwift runner, but not on CucumberSwiftMacros"), run.output)
        XCTAssertTrue(run.output.contains("add `.product(name: \"CucumberSwiftMacros\", package: \"CucumberSwift\")`"), run.output)
    }

    func testTheSwiftTestingRunnerNeedsItsOwnMacrosProduct() throws {
        let run = try ConverterTool.run(["--root", folder.path, "--missing-macros", "AppTests=CucumberSwiftTestingMacros", folder.path])
        XCTAssertEqual(run.status, 2)
        XCTAssertTrue(run.output.contains("not on CucumberSwiftTestingMacros"), run.output)
    }

    func testATargetThatHasTheMacrosProductIsConverted() throws {
        let steps = try create("Tests/AppTests/Steps.swift", "import CucumberSwift\n\nGiven(\"I log in\") { _, _ in }\n")
        let run = try ConverterTool.run(["--root", folder.path, folder.path])
        XCTAssertEqual(run.status, 0)
        XCTAssertTrue(try String(contentsOf: steps, encoding: .utf8).contains("#Given(\"I log in\")"))
    }
}
#endif
