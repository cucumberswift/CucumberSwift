import CucumberSwiftTesting
import Testing

@Suite struct CucumberTagsTests {
    struct Case: Sendable {
        let filter: String?
        let tags: [String]
        let runs: Bool
    }

    @Test(arguments: [
        Case(filter: nil, tags: ["any"], runs: true),
        Case(filter: "big", tags: ["small", "big"], runs: true),
        Case(filter: "BIG", tags: ["big"], runs: true),
        Case(filter: "^sm", tags: ["small"], runs: true),
        Case(filter: "x,big", tags: ["big"], runs: true),
        Case(filter: "big", tags: ["small"], runs: false),
        // As in CucumberSwift, each entry is a regular expression as written, spaces included.
        Case(filter: "x, big", tags: ["big"], runs: false)
    ])
    func scenariosRunWhenAnyTagMatchesAnyEntry(_ testCase: Case) {
        let environment = testCase.filter.map { ["CUCUMBER_TAGS": $0] } ?? [:]
        #expect(CucumberTags.shouldRun(testCase.tags, environment: environment) == testCase.runs)
    }
}
