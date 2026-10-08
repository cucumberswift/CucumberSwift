//
//  ConverterTestCase.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

/// What the converter's tests share: the source they convert, and the two outcomes they check.
class ConverterTestCase: XCTestCase {
    /// What the converter writes before a step definition it leaves.
    static let marker = "#warning(\"Convert to Gherkin Macros by hand: "

    let header = """
        import CucumberSwift
        import CucumberSwiftMacros

        """

    /// The source, with the macros' module imported, converted.
    func convert(_ body: String, header: String? = nil) -> ConverterTool.Result {
        convert(source: (header ?? self.header) + body)
    }

    func convert(source: String) -> ConverterTool.Result {
        do {
            return try ConverterTool.convert(source)
        } catch {
            XCTFail("\(error)")
            return ConverterTool.Result(source: source, converted: [], leftUnchanged: [])
        }
    }

    func assertConverts(_ before: String,
                        to after: String,
                        header: String? = nil,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let result = convert(before, header: header)
        XCTAssertEqual(result.source, (header ?? self.header) + after, file: file, line: line)
        XCTAssertEqual(result.leftUnchanged, [], file: file, line: line)
        XCTAssertFalse(result.converted.isEmpty, file: file, line: line)
    }

    func assertLeftUnchanged(_ source: String,
                             because reason: String,
                             header: String? = nil,
                             marked: Bool = true,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        let result = convert(source, header: header)
        let lines = result.source.components(separatedBy: "\n")
        let withoutMarkers = lines.filter { !$0.contains(Self.marker) }.joined(separator: "\n")
        XCTAssertEqual(withoutMarkers, (header ?? self.header) + source, file: file, line: line)
        XCTAssertEqual(lines.count - withoutMarkers.components(separatedBy: "\n").count, marked ? 1 : 0, file: file, line: line)
        XCTAssertEqual(result.converted, [], file: file, line: line)
        XCTAssertEqual(result.leftUnchanged.count, 1, file: file, line: line)
        let actual = result.leftUnchanged.first?.reason ?? "no reason"
        XCTAssertTrue(actual.contains(reason), "\(actual) doesn't contain: \(reason)", file: file, line: line)
    }
}
#endif
