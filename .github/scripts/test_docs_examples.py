"""Unit tests for docs_examples.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

They check how examples are found, marked and wrapped, without compiling anything, so they
need no Swift toolchain. The last test reads the real catalog. Only the standard library is
used.
"""
import os
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import docs_examples  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]


def article(*lines):
    return "\n".join(lines) + "\n"


class BlocksInArticleTests(unittest.TestCase):
    def test_an_unmarked_block_is_a_file(self):
        [example] = docs_examples.blocks_in_article("A.md", article(
            "Text", "```swift", "import CucumberSwift", "```"))
        self.assertEqual(example.kind, "file")
        self.assertEqual(example.line, 2)
        self.assertEqual(example.code, "import CucumberSwift\n")

    def test_a_package_manifest_is_found_without_a_marker(self):
        [example] = docs_examples.blocks_in_article("A.md", article(
            "```swift", "// swift-tools-version:6.1", "import PackageDescription", "```"))
        self.assertEqual(example.kind, "manifest")

    def test_a_marker_gives_the_kind_and_options(self):
        [example] = docs_examples.blocks_in_article("A.md", article(
            "<!-- swift-example: steps bare-slash-regex -->", "```swift", "When(/x/) { _, _ in }",
            "```"))
        self.assertEqual(example.kind, "steps")
        self.assertEqual(example.options, ("bare-slash-regex",))

    def test_a_fragment_keeps_its_reason(self):
        [example] = docs_examples.blocks_in_article("A.md", article(
            "<!-- swift-example: fragment: uses UIKit -->", "```swift", "UIView()", "```"))
        self.assertEqual(example.kind, "fragment")
        self.assertEqual(example.reason, "uses UIKit")

    def test_an_indented_block_loses_its_indent(self):
        [example] = docs_examples.blocks_in_article("A.md", article(
            "- Item:", "", "  <!-- swift-example: members -->", "  ```swift",
            "  public var verbose: Bool { true }", "  ```"))
        self.assertEqual(example.kind, "members")
        self.assertEqual(example.code, "public var verbose: Bool { true }\n")

    def test_longer_fences_and_tildes_are_found(self):
        examples = docs_examples.blocks_in_article("A.md", article(
            "````swift", "let a = 1", "```", "let b = 2", "````",
            "~~~ Swift", "let c = 3", "~~~~"))
        self.assertEqual([e.code for e in examples],
                         ["let a = 1\n```\nlet b = 2\n", "let c = 3\n"])
        self.assertEqual([e.line for e in examples], [1, 6])

    def test_only_a_fence_opens_a_block(self):
        self.assertEqual(docs_examples.open_fence("  ````swift "),
                         {"indent": "  ", "fence": "````", "info": "swift "})
        for line in ["``swift", "    ```swift", "```swift `x`", "text ```swift", ""]:
            with self.subTest(line=line):
                self.assertIsNone(docs_examples.open_fence(line))

    def test_a_swift_fence_inside_another_block_is_not_an_example(self):
        self.assertEqual(docs_examples.blocks_in_article("A.md", article(
            "````markdown", "```swift", "not code", "```", "````")), [])

    def test_other_languages_are_not_examples(self):
        self.assertEqual(docs_examples.blocks_in_article("A.md", article(
            "```gherkin", "Given a step", "```", "```bash", "swift test", "```")), [])

    def test_bad_markers_fail(self):
        for text in [
            article("<!-- swift-example: statements -->", "```swift", "x", "```"),
            article("<!-- swift-example: steps loud -->", "```swift", "x", "```"),
            article("<!-- swift-example: fragment: -->", "```swift", "x", "```"),
            article("<!-- swift-example: steps -->", "Text", "```swift", "x", "```"),
            article("<!-- swift-example: steps -->", "```gherkin", "x", "```"),
            article("<!-- swift-example: steps -->"),
            article("```swift", "x"),
        ]:
            with self.subTest(text=text):
                with self.assertRaises(docs_examples.ExampleError):
                    docs_examples.blocks_in_article("A.md", text)


class FragmentTests(unittest.TestCase):
    def fragment(self, reason):
        return docs_examples.Example("Docs/A.md", 1, "", "fragment", reason=reason)

    def test_matching_fragments_pass(self):
        docs_examples.check_fragments([self.fragment("why")], expected=[("A.md", "why")])

    def test_an_unlisted_fragment_fails(self):
        fragments = [self.fragment("why")]
        with self.assertRaises(docs_examples.ExampleError):
            docs_examples.check_fragments(fragments, expected=[])

    def test_a_listed_fragment_that_is_not_marked_fails(self):
        with self.assertRaises(docs_examples.ExampleError):
            docs_examples.check_fragments([], expected=[("A.md", "why")])


class SwiftSourcesTests(unittest.TestCase):
    def test_steps_become_the_body_of_setup_steps(self):
        example = docs_examples.Example("A.md", 3, 'Given("x") { _, _ in }\n', "steps")
        sources = docs_examples.swift_sources(example)
        code = sources["Example.swift"]
        self.assertIn("import XCTestStubs\n", code)
        self.assertIn("import CucumberSwiftMacros\n", code)
        self.assertIn("extension Cucumber: StepImplementation {\n    public func setupSteps() {\n"
                      '        Given("x") { _, _ in }\n', code)
        self.assertIn("public var bundle: Bundle", sources["Completion.swift"])
        self.assertNotIn("setupSteps", sources["Completion.swift"])

    def test_a_block_with_imports_keeps_only_its_own(self):
        example = docs_examples.Example("A.md", 1, "import CucumberSwiftTesting\n\nlet x = 1\n")
        code = docs_examples.swift_sources(example)["Example.swift"]
        self.assertEqual(example.runner, "testing")
        self.assertIn("import SwiftTestingStubs\n", code)
        self.assertNotIn("import Testing\n", code)

    def test_members_get_the_requirements_they_leave_out(self):
        example = docs_examples.Example("A.md", 1, "public var verbose: Bool { true }\n", "members")
        sources = docs_examples.swift_sources(example)
        self.assertIn("extension Cucumber: StepImplementation {\n    public var verbose",
                      sources["Example.swift"])
        self.assertIn("public func setupSteps() {}", sources["Completion.swift"])
        self.assertIn("public var bundle: Bundle", sources["Completion.swift"])

    def test_swift6_marks_the_conformance_retroactive(self):
        example = docs_examples.Example("A.md", 1, "public var verbose: Bool { true }\n", "members",
                                        options=["swift6"])
        self.assertIn("extension Cucumber: @retroactive StepImplementation",
                      docs_examples.swift_sources(example)["Example.swift"])

    def test_a_complete_implementation_needs_nothing_more(self):
        example = docs_examples.Example("A.md", 1, (
            "extension Cucumber: StepImplementation {\n"
            "    public var bundle: Bundle { .main }\n"
            "    public func setupSteps() {}\n}\n"))
        self.assertNotIn("Completion.swift", docs_examples.swift_sources(example))


class ManifestTests(unittest.TestCase):
    def test_a_target_goes_in_the_targets_list(self):
        example = docs_examples.Example("A.md", 1, '.testTarget(name: "T")\n', "package-target")
        manifest = docs_examples.manifest_source(example)
        self.assertTrue(manifest.startswith("// swift-tools-version:6.1\n"))
        self.assertIn('    targets: [\n        .testTarget(name: "T")\n    ]', manifest)

    def test_target_arguments_follow_a_name(self):
        example = docs_examples.Example("A.md", 1, "swiftSettings: []\n", "target-arguments")
        self.assertIn('.target(\n            name: "Example",\n            swiftSettings: []\n        )',
                      docs_examples.manifest_source(example))

    def test_a_whole_manifest_is_left_alone(self):
        code = "// swift-tools-version:6.1\nimport PackageDescription\n"
        example = docs_examples.Example("A.md", 1, code, "manifest")
        self.assertEqual(docs_examples.manifest_source(example), code)


class PackageTests(unittest.TestCase):
    def test_each_example_gets_a_target_with_its_settings(self):
        examples = [
            docs_examples.Example("Docs/A.md", 3, "x\n", "steps", options=["swift6", "features"]),
            docs_examples.Example("Docs/B.md", 7, "import CucumberSwiftTestingMacros\n"),
        ]
        manifest = docs_examples.package_manifest(examples, pathlib.Path("/repo"))
        self.assertIn('.package(name: "CucumberSwift", path: "/repo", traits: ["Macros"])', manifest)
        self.assertIn('name: "A_3"', manifest)
        self.assertIn('resources: [.copy("Features")]', manifest)
        self.assertIn("swiftSettings: [.swiftLanguageMode(.v6)]", manifest)
        self.assertIn('dependencies: ["SwiftTestingStubs", .product(name: '
                      '"CucumberSwiftTestingMacros", package: "CucumberSwift")]', manifest)

    def test_write_package_lays_out_every_example(self):
        examples = docs_examples.find_examples(ROOT / docs_examples.CATALOG)
        with tempfile.TemporaryDirectory() as output:
            output = pathlib.Path(output)
            docs_examples.write_package(examples, ROOT, output)
            swift = [e for e in examples if e.kind != "fragment" and not e.is_manifest]
            manifests = [e for e in examples if e.is_manifest]
            self.assertEqual(len(list((output / "Examples").iterdir())), len(swift))
            self.assertEqual(len(list((output / "Manifests").iterdir())), len(manifests))
            self.assertTrue((output / "Stubs/XCTestStubs/XCTestStubs.swift").exists())


class CatalogTests(unittest.TestCase):
    def test_the_catalog_matches_the_fragment_list(self):
        examples = docs_examples.find_examples(ROOT / docs_examples.CATALOG)
        docs_examples.check_fragments(examples)
        self.assertEqual(len({e.target for e in examples}), len(examples))
        self.assertTrue(any(e.path.endswith(".swift") for e in examples))


if __name__ == "__main__":
    unittest.main()
