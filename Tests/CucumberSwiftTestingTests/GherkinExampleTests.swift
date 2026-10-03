import CucumberSwiftTesting
import Foundation
import Testing

@Suite struct GherkinExampleTests {
    struct EncodedArgument: Encodable {
        let example: GherkinExample

        func encode(to encoder: Encoder) throws {
            try example.encodeTestArgument(to: encoder)
        }
    }

    let example = GherkinExample(GherkinScenario(
        featureTitle: "F",
        featureTags: [],
        title: "Eat 5 (left: 7)",
        tags: [],
        file: "/F.feature",
        line: 12,
        column: 7,
        steps: []))

    @Test func anExampleIsNamedAsCucumberSwiftNamesItsScenario() {
        #expect(example.testDescription == "Eat 5 (left: 7)")
    }

    @Test func anExampleIsIdentifiedByItsLineOnly() throws {
        let encoded = try JSONEncoder().encode(EncodedArgument(example: example))
        #expect(String(bytes: encoded, encoding: .utf8) == "12")
    }
}
