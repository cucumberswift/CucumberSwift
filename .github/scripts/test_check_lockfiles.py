"""Unit tests for check_lockfiles.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

Each test writes its own manifests and lockfiles to a temporary directory, and
swift, xcodebuild and git are replaced with fakes, so the tests need no
network access, toolchain or checkout. Only the standard library is used.
"""
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_lockfiles  # noqa: E402

EXPRESSIONS = "https://github.com/cucumberswift/CucumberSwiftExpressions.git"
DOCC = "https://github.com/apple/swift-docc-plugin"
SYMBOLKIT = "https://github.com/swiftlang/swift-docc-symbolkit"
JSONSCHEMA = "https://github.com/kylef/JSONSchema.swift"
EXPRESSIONS_120 = "4c9c0794b422f6338264013f739711b484155373"
EXPRESSIONS_130 = "b" * 40
DOCC_150 = "647c708be89f834fa6a6d4945442793a77ddf5b6"


def package_swift(expressions="from: \"1.2.0\"", docc="from: \"1.5.0\""):
    return f"""// swift-tools-version:5.5
// A comment with a URL: https://example.com/not-a-dependency.git
import PackageDescription

let package = Package(
    name: "CucumberSwift",
    dependencies: [
        .package(url: "{EXPRESSIONS}", {expressions}), // trailing comment
        .package(url: "{DOCC}", {docc})
    ],
    targets: [
        .target(name: "CucumberSwift", dependencies: ["CucumberSwiftExpressions"])
    ]
)
"""


def pbxproj(expressions="kind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = 1.2.0;"):
    return f"""// !$*UTF8*$!
{{
/* Begin XCRemoteSwiftPackageReference section */
		7D521228B8A5D759E92E06F9 /* XCRemoteSwiftPackageReference "CucumberSwiftExpressions" */ = {{
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "{EXPRESSIONS}";
			requirement = {{
				{expressions}
			}};
		}};
		AD3E8E4A6C3684CD29E6B6B4 /* XCRemoteSwiftPackageReference "JSONSchema.swift" */ = {{
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "{JSONSCHEMA}";
			requirement = {{
				kind = upToNextMajorVersion;
				minimumVersion = 0.6.0;
			}};
		}};
/* End XCRemoteSwiftPackageReference section */
}}
"""


def resolved_v1(pins):
    """A SwiftPM lockfile, format 1. `pins` is a list of (name, url, version, revision)."""
    return json.dumps({"object": {"pins": [
        {"package": name, "repositoryURL": url,
         "state": {"branch": None, "revision": revision, "version": version}}
        for name, url, version, revision in pins]}, "version": 1}, indent=2)


def resolved_v3(pins):
    """An Xcode lockfile, format 3. `pins` is a list of (name, url, version, revision)."""
    state = lambda version, revision: (  # noqa: E731
        {"revision": revision, "version": version} if version
        else {"branch": "main", "revision": revision})
    return json.dumps({"originHash": "0" * 64, "pins": [
        {"identity": check_lockfiles.identity(url), "kind": "remoteSourceControl",
         "location": url, "state": state(version, revision)}
        for _, url, version, revision in pins], "version": 3}, indent=2)


SWIFTPM_PINS = [
    ("CucumberSwiftExpressions", EXPRESSIONS, "1.2.0", EXPRESSIONS_120),
    ("SwiftDocCPlugin", DOCC, "1.5.0", DOCC_150),
    ("SymbolKit", SYMBOLKIT, "1.0.0", "c" * 40),
]
XCODE_PINS = [
    ("CucumberSwiftExpressions", EXPRESSIONS, "1.2.0", EXPRESSIONS_120),
    ("JSONSchema", JSONSCHEMA, "0.6.0", "d" * 40),
    ("PathKit", "https://github.com/kylef/PathKit.git", "1.0.1", "e" * 40),
]


class Repository(unittest.TestCase):
    """A temporary working directory holding the four files, as on main."""

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.previous = os.getcwd()
        os.chdir(self.directory.name)
        self.addCleanup(os.chdir, self.previous)
        self.write(check_lockfiles.PACKAGE_SWIFT, package_swift())
        self.write(check_lockfiles.PACKAGE_RESOLVED, resolved_v1(SWIFTPM_PINS))
        self.write(check_lockfiles.PBXPROJ, pbxproj())
        self.write(check_lockfiles.XCODE_RESOLVED, resolved_v3(XCODE_PINS))

    def write(self, path, text):
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)

    def main(self, *argv):
        out = io.StringIO()
        with redirect_stdout(out):
            status = check_lockfiles.main(list(argv))
        return status, out.getvalue()

    def errors(self, output):
        return [line for line in output.splitlines() if line.startswith("::error::")]


class PassingTests(Repository):
    def test_the_files_as_on_main_pass(self):
        status, output = self.main()
        self.assertEqual(status, 0)
        self.assertEqual(self.errors(output), [])
        self.assertIn("Every manifest agrees with its lockfile", output)

    def test_a_package_in_only_one_lockfile_passes(self):
        # JSONSchema and PathKit are only in the Xcode lockfile, SymbolKit only in
        # the SwiftPM one. Only packages in both are compared.
        self.assertEqual(check_lockfiles.check_files(), [])


class LowerBoundTests(Repository):
    def test_a_swiftpm_lower_bound_below_its_pin_fails(self):
        self.write(check_lockfiles.PACKAGE_SWIFT, package_swift(docc='from: "1.0.0"'))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(f"Package.swift requires {DOCC} from 1.0.0, but Package.resolved pins 1.5.0", error)
        self.assertIn("Set the lower bound in Package.swift to 1.5.0", error)
        self.assertIn("swift package resolve", error)

    def test_an_xcode_lower_bound_below_its_pin_fails(self):
        self.write(check_lockfiles.PBXPROJ,
                   pbxproj("kind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = 1.0.0;"))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(f"Project.swift requires {EXPRESSIONS} from 1.0.0, but "
                      f"{check_lockfiles.XCODE_RESOLVED} pins 1.2.0", error)
        self.assertIn("mise run generate", error)

    def test_a_dependency_missing_from_its_lockfile_fails(self):
        self.write(check_lockfiles.PACKAGE_RESOLVED, resolved_v1(SWIFTPM_PINS[1:]))
        [error] = check_lockfiles.check_files()
        self.assertIn(f"Package.resolved has no pin for {EXPRESSIONS}, which Package.swift requires", error)

    def test_a_dependency_pinned_to_a_branch_fails(self):
        self.write(check_lockfiles.XCODE_RESOLVED, resolved_v3(
            [("CucumberSwiftExpressions", EXPRESSIONS, None, EXPRESSIONS_120)] + XCODE_PINS[1:]))
        # The branch pin also no longer matches Package.resolved's 1.2.0.
        branch, shared = check_lockfiles.check_files()
        self.assertIn(f"pins {EXPRESSIONS} to a branch or revision, not a version", branch)
        self.assertIn(f"The lockfiles disagree on {EXPRESSIONS}", shared)

    def test_a_requirement_without_a_version_fails(self):
        self.write(check_lockfiles.PACKAGE_SWIFT, package_swift(docc='branch: "main"'))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(f"{DOCC} has no version requirement this check can read", error)

    def test_an_xcode_branch_requirement_fails(self):
        self.write(check_lockfiles.PBXPROJ, pbxproj("branch = main;\n\t\t\t\tkind = branch;"))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn("has a `branch` requirement, not a version range", error)


SYNTAX = "https://github.com/swiftlang/swift-syntax.git"


def versioned_package_swift(syntax='"601.0.0"..<"603.0.0"', docc='from: "1.5.0"'):
    """Package@swift-6.1.swift: Package.swift's dependencies, and swift-syntax as a range."""
    return package_swift(docc=docc).replace(
        f'.package(url: "{DOCC}", {docc})',
        f'.package(url: "{DOCC}", {docc}),\n        .package(url: "{SYNTAX}", {syntax})')


class VersionedManifestTests(Repository):
    """A version-specific manifest is checked against Package.resolved, as Package.swift is."""

    def setUp(self):
        super().setUp()
        self.write("Package@swift-6.1.swift", versioned_package_swift())
        self.write(check_lockfiles.PACKAGE_RESOLVED,
                   resolved_v1(SWIFTPM_PINS + [("swift-syntax", SYNTAX, "602.0.0", "f" * 40)]))

    def test_a_pin_inside_a_range_passes(self):
        status, output = self.main()
        self.assertEqual(status, 0, output)

    def test_a_pin_at_an_exclusive_upper_bound_fails(self):
        self.write("Package@swift-6.1.swift", versioned_package_swift(syntax='"601.0.0"..<"602.0.0"'))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn("Package@swift-6.1.swift requires " + SYNTAX + " from 601.0.0 to 602.0.0, "
                      "but Package.resolved pins 602.0.0, outside that range.", error)

    def test_a_pin_at_an_inclusive_upper_bound_passes(self):
        self.write("Package@swift-6.1.swift", versioned_package_swift(syntax='"601.0.0"..."602.0.0"'))
        status, output = self.main()
        self.assertEqual(status, 0, output)

    def test_a_pin_below_a_range_fails(self):
        self.write("Package@swift-6.1.swift", versioned_package_swift(syntax='"602.0.1"..<"603.0.0"'))
        status, output = self.main()
        self.assertEqual(status, 1)
        self.assertEqual(len(self.errors(output)), 1)

    def test_a_lower_bound_in_the_versioned_manifest_is_checked(self):
        self.write("Package@swift-6.1.swift", versioned_package_swift(docc='from: "1.0.0"'))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn("Package@swift-6.1.swift requires " + DOCC + " from 1.0.0", error)

    def test_swift_syntax_without_a_pin_passes(self):
        # SwiftPM does not pin a dependency only a trait uses in the root package's lockfile.
        self.write(check_lockfiles.PACKAGE_RESOLVED, resolved_v1(SWIFTPM_PINS))
        status, output = self.main()
        self.assertEqual(status, 0, output)

    def test_another_dependency_missing_from_the_lockfile_names_the_versioned_manifest(self):
        other = "https://github.com/example/Other.git"
        self.write("Package@swift-6.1.swift", versioned_package_swift().replace(
            f'.package(url: "{SYNTAX}"', f'.package(url: "{other}", from: "1.0.0"),\n        .package(url: "{SYNTAX}"'))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn("Package.resolved has no pin for " + other + ", which Package@swift-6.1.swift requires", error)
        self.assertIn("swift package resolve", error)


class SharedPackageTests(Repository):
    def test_lockfiles_pinning_different_versions_fail(self):
        # What a Dependabot bump of CucumberSwiftExpressions alone would leave:
        # Package.swift and Package.resolved move, the Xcode lockfile does not.
        self.write(check_lockfiles.PACKAGE_SWIFT, package_swift(expressions='from: "1.3.0"'))
        self.write(check_lockfiles.PACKAGE_RESOLVED, resolved_v1(
            [("CucumberSwiftExpressions", EXPRESSIONS, "1.3.0", EXPRESSIONS_130)] + SWIFTPM_PINS[1:]))
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(f"The lockfiles disagree on {EXPRESSIONS}: Package.resolved pins 1.3.0 "
                      f"({EXPRESSIONS_130}), {check_lockfiles.XCODE_RESOLVED} pins 1.2.0 "
                      f"({EXPRESSIONS_120})", error)
        self.assertIn("xcodebuild -resolvePackageDependencies", error)

    def test_lockfiles_pinning_different_revisions_fail(self):
        self.write(check_lockfiles.XCODE_RESOLVED, resolved_v3(
            [("CucumberSwiftExpressions", EXPRESSIONS, "1.2.0", EXPRESSIONS_130)] + XCODE_PINS[1:]))
        [error] = check_lockfiles.check_files()
        self.assertIn(f"The lockfiles disagree on {EXPRESSIONS}", error)

    def test_urls_that_differ_only_in_case_and_git_suffix_are_the_same_package(self):
        other = "https://github.com/CucumberSwift/cucumberswiftexpressions"
        self.write(check_lockfiles.XCODE_RESOLVED, resolved_v3(
            [("CucumberSwiftExpressions", other, "1.2.1", EXPRESSIONS_130)] + XCODE_PINS[1:]))
        errors = check_lockfiles.check_files()
        self.assertTrue(any("The lockfiles disagree" in error for error in errors), errors)


class RepositoryURLTests(Repository):
    def test_a_pin_from_another_owner_with_the_same_identity_fails(self):
        fork = "https://github.com/someone-else/CucumberSwiftExpressions.git"
        self.write(check_lockfiles.PACKAGE_RESOLVED, resolved_v1(
            [("CucumberSwiftExpressions", fork, "1.2.0", EXPRESSIONS_120)] + SWIFTPM_PINS[1:]))
        errors = check_lockfiles.check_files()
        self.assertTrue(any(f"Package.swift requires {EXPRESSIONS}, but Package.resolved pins "
                            f"{fork}, a different repository" in error for error in errors), errors)

    def test_lockfiles_pinning_another_host_with_the_same_identity_fail(self):
        # Same version and revision, so only the URL tells them apart.
        mirror = "https://gitlab.com/cucumberswift/CucumberSwiftExpressions.git"
        self.write(check_lockfiles.XCODE_RESOLVED, resolved_v3(
            [("CucumberSwiftExpressions", mirror, "1.2.0", EXPRESSIONS_120)] + XCODE_PINS[1:]))
        errors = check_lockfiles.check_files()
        self.assertTrue(any("The lockfiles pin different repositories with the same package "
                            f"identity: Package.resolved pins {EXPRESSIONS}" in error
                            for error in errors), errors)
        self.assertFalse(any("The lockfiles disagree" in error for error in errors), errors)


class ParsingTests(unittest.TestCase):
    def test_every_version_requirement_form_gives_its_bounds(self):
        for requirement, bound, upper in [
            ('from: "1.2.0"', "1.2.0", None),
            ('.upToNextMajor(from: "1.2.0")', "1.2.0", None),
            ('.upToNextMinor(from: "1.2.0")', "1.2.0", None),
            ('exact: "1.2.0"', "1.2.0", None),
            ('.exact("1.2.0")', "1.2.0", None),
            ('"1.2.0"..<"2.0.0"', "1.2.0", ("2.0.0", False)),
            ('"1.2.0"..."1.9.9"', "1.2.0", ("1.9.9", True)),
        ]:
            with self.subTest(requirement):
                parsed = check_lockfiles.parse_package_swift(package_swift(expressions=requirement))
                self.assertEqual(parsed["cucumberswiftexpressions"], (EXPRESSIONS, bound, upper))

    def test_a_named_package_and_a_local_package(self):
        text = """
        dependencies: [
            .package(name: "Foo", url: "https://example.com/Foo.git", .upToNextMajor(from: "2.0.0")),
            .package(path: "../Local")
        ]
        """
        self.assertEqual(check_lockfiles.parse_package_swift(text),
                         {"foo": ("https://example.com/Foo.git", "2.0.0", None)})

    def test_a_dependency_in_a_block_comment_is_ignored(self):
        # A commented-out dependency has no pin, and must not be reported as missing one.
        for comment in [
            '/* .package(url: "https://example.com/Gone.git", from: "1.0.0"), */',
            '/* outer /* nested */ .package(url: "https://example.com/Gone.git", from: "1.0.0"), */',
            '/*\n        .package(url: "https://example.com/Gone.git", from: "1.0.0"),\n        */',
        ]:
            with self.subTest(comment):
                text = package_swift().replace("dependencies: [", "dependencies: [\n        " + comment)
                self.assertEqual(sorted(check_lockfiles.parse_package_swift(text)),
                                 ["cucumberswiftexpressions", "swift-docc-plugin"])

    def test_comment_markers_inside_a_string_are_not_comments(self):
        text = 'let x = "/* not a comment"\n.package(url: "https://example.com/Foo.git", from: "1.0.0") // done'
        self.assertEqual(check_lockfiles.parse_package_swift(text),
                         {"foo": ("https://example.com/Foo.git", "1.0.0", None)})

    def test_a_raw_string_before_a_dependency_does_not_hide_it(self):
        # `#"C:\"#` ends at `"#`; the `\"` inside it is not an escape.
        for declaration in ['let path = #"C:\\"#', 'let path = ##"a "# b"##', 'let path = #"a \\#"q"#']:
            with self.subTest(declaration):
                text = declaration + '\n.package(url: "https://example.com/Foo.git", from: "1.0.0")'
                self.assertEqual(check_lockfiles.parse_package_swift(text),
                                 {"foo": ("https://example.com/Foo.git", "1.0.0", None)})

    def test_a_parenthesis_inside_a_string_does_not_end_the_call(self):
        text = '.package(name: "Odd)Name", url: "https://example.com/Foo.git", from: "1.0.0")'
        self.assertEqual(check_lockfiles.parse_package_swift(text),
                         {"foo": ("https://example.com/Foo.git", "1.0.0", None)})

    def test_a_dependency_whose_url_is_not_a_literal_fails(self):
        # Treating it as local would leave a remote dependency unchecked.
        for call in ['.package(url: expressionsURL, from: "1.2.0")',
                     '.package(id: "cucumberswift.expressions", from: "1.2.0")']:
            with self.subTest(call):
                with self.assertRaises(check_lockfiles.CheckError) as raised:
                    check_lockfiles.parse_package_swift(call)
                self.assertIn("this check cannot read the URL of", str(raised.exception))

    def test_an_exact_xcode_requirement_gives_its_version(self):
        parsed = check_lockfiles.parse_pbxproj(pbxproj("kind = exactVersion;\n\t\t\t\tversion = 1.2.0;"))
        self.assertEqual(parsed["cucumberswiftexpressions"], (EXPRESSIONS, "1.2.0", None))

    def test_an_unreadable_lockfile_fails_with_its_path(self):
        with self.assertRaises(check_lockfiles.CheckError) as raised:
            check_lockfiles.parse_resolved('{"version": 3}', "Some/Package.resolved")
        self.assertIn("Some/Package.resolved is not a Package.resolved file", str(raised.exception))


class MissingFileTests(Repository):
    def test_a_missing_lockfile_fails(self):
        os.remove(check_lockfiles.XCODE_RESOLVED)
        status, output = self.main()
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(check_lockfiles.XCODE_RESOLVED, error)


class ResolveTests(Repository):
    """--resolve, with swift, xcodebuild and git replaced by a fake."""

    def resolve(self, failing=(), resolved=None):
        """Run main with --resolve. Each command whose first two words are in
        `failing` exits 1; every other command exits 0. `swift package resolve`
        rewrites Package.resolved to `resolved`, when given."""
        self.commands = []

        def fake_run(args, **kwargs):
            self.commands.append(list(args))
            key = " ".join(args[:2]) if args[0] != "git" else f"git diff {args[-1]}"
            if key == "swift package" and resolved is not None and key not in failing:
                self.write(check_lockfiles.PACKAGE_RESOLVED, resolved)
            return subprocess.CompletedProcess(args, 1 if key in failing else 0)

        with mock.patch.object(check_lockfiles.subprocess, "run", side_effect=fake_run):
            return self.main("--resolve")

    def test_fresh_lockfiles_pass(self):
        status, output = self.resolve()
        self.assertEqual(status, 0)
        self.assertEqual(self.errors(output), [])
        self.assertEqual(self.commands, [
            ["swift", "package", "resolve"],
            ["xcodebuild", "-resolvePackageDependencies", "-project", "CucumberSwift.xcodeproj",
             "-disableAutomaticPackageResolution"],
            ["git", "diff", "--exit-code", "--", check_lockfiles.XCODE_RESOLVED],
        ])

    def test_a_swiftpm_lockfile_that_cannot_resolve_fails(self):
        status, output = self.resolve(failing={"swift package"})
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn("`swift package resolve` failed, so Package.resolved cannot satisfy Package.swift", error)
        self.assertNotIn(["git", "diff", "--", "Package.resolved"], self.commands)

    def test_a_stale_swiftpm_lockfile_fails(self):
        changed = [pin if pin[0] != "SymbolKit" else ("SymbolKit", SYMBOLKIT, "1.0.1", "e" * 40)
                   for pin in SWIFTPM_PINS]
        status, output = self.resolve(resolved=resolved_v1(changed))
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn("Package.resolved is stale: `swift package resolve` changed it", error)
        self.assertIn(["git", "diff", "--", "Package.resolved"], self.commands)

    def test_a_swift_syntax_pin_that_resolving_adds_or_removes_is_not_stale(self):
        # Swift 6.1.2 pins a dependency only a trait uses; Swift 6.2.3 does not.
        syntax = ("swift-syntax", "https://github.com/swiftlang/swift-syntax.git", "602.0.0", "f" * 40)
        for before, after in [(SWIFTPM_PINS, SWIFTPM_PINS + [syntax]),
                              (SWIFTPM_PINS + [syntax], SWIFTPM_PINS)]:
            with self.subTest(before=len(before), after=len(after)):
                self.write(check_lockfiles.PACKAGE_RESOLVED, resolved_v3(before))
                status, output = self.resolve(resolved=resolved_v3(after))
                self.assertEqual(status, 0, output)
                self.assertNotIn(["git", "diff", "--", "Package.resolved"], self.commands)

    def test_a_lockfile_that_resolving_reformats_is_not_stale(self):
        # The same pins in another format, as when SwiftPM upgrades it, are not a change.
        status, output = self.resolve(resolved=resolved_v3(SWIFTPM_PINS))
        self.assertEqual(status, 0, output)

    def test_an_xcode_lockfile_that_does_not_satisfy_the_project_fails(self):
        status, output = self.resolve(failing={"xcodebuild -resolvePackageDependencies"})
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(f"{check_lockfiles.XCODE_RESOLVED} does not satisfy "
                      f"{check_lockfiles.PBXPROJ}", error)
        self.assertIn("mise run generate", error)

    def test_a_stale_xcode_lockfile_fails(self):
        status, output = self.resolve(failing={f"git diff {check_lockfiles.XCODE_RESOLVED}"})
        self.assertEqual(status, 1)
        [error] = self.errors(output)
        self.assertIn(f"{check_lockfiles.XCODE_RESOLVED} is stale: xcodebuild changed it", error)

    def test_file_errors_and_resolve_errors_are_all_reported(self):
        self.write(check_lockfiles.PACKAGE_SWIFT, package_swift(docc='from: "1.0.0"'))
        status, output = self.resolve(failing={"xcodebuild -resolvePackageDependencies"})
        self.assertEqual(status, 1)
        self.assertEqual(len(self.errors(output)), 2)


if __name__ == "__main__":
    unittest.main()
