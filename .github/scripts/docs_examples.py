#!/usr/bin/env python3
"""Compile every Swift example in the DocC catalog against this checkout's CucumberSwift.

Examples are the ```swift blocks in the catalog's articles (*.md) and the Swift files under
its Resources folder, which the tutorials show with @Code. Each one is compiled on its own,
so that an example stops compiling the moment the API it shows changes.

By default a block is a whole Swift file, compiled as a target of its own. A Package.swift
(a block that starts with `// swift-tools-version`) is checked with
`swift package dump-package` instead. Any other block says how to compile it with a marker
comment on the line before its fence:

    <!-- swift-example: steps -->
    ```swift
    Given("I have {int} cukes") { match, _ in ... }
    ```

The marker is an HTML comment, which DocC leaves out of the page. Its kinds:

  file                    a whole Swift file, the default; mark it only to give options
  steps                   statements, compiled as the body of setupSteps()
  members                 members, compiled inside `extension Cucumber: StepImplementation`
  package-target          a target in a Package.swift's `targets:` list
  target-arguments        arguments to a target in a Package.swift, after its name
  fragment: <reason>      not compiled, for the reason given

After the kind, a marker can list options:

  swift6                  compile in the Swift 6 language mode, rather than Swift 5
  bare-slash-regex        turn on BareSlashRegexLiterals, as the article tells you to
  features                give the target a Features folder as a resource, as a test target
                          has, so that SwiftPM generates `Bundle.module`

What every Swift example gets:

  - The imports a test file starts with, when the block has no import of its own:
    Foundation, XCTest and CucumberSwiftMacros (which re-exports CucumberSwift), or
    Foundation, Testing and CucumberSwiftTestingMacros for the Swift Testing runner. A block
    that imports CucumberSwiftTesting or CucumberSwiftTestingMacros uses that runner.
  - The stubs in Tests/DocumentationExamples, which declare the reader's own code that the
    examples use, such as `basket`, in a module of their own that each example imports. An
    example's own declaration of the same name takes precedence over the stub.
  - The rest of `extension Cucumber: StepImplementation`, when the block declares it but
    leaves out a requirement for brevity ("bundle and setupSteps() as usual").
  - macOS 13, for regex literals, and the Macros trait.

A fragment is listed in FRAGMENTS below, so that opting a block out shows up in review: the
script fails when the markers in the catalog and the list differ. Keep the list short.

Run from the repository root, with Swift 6.1 or later (Xcode 16.3 or later):

  python3 .github/scripts/docs_examples.py              # compile every example
  python3 .github/scripts/docs_examples.py --list       # list the examples and how each compiles

It writes a package with one target per example to .build/documentation-examples and builds
it with `swift build`. CI's SwiftPM tests job runs it.

Only the standard library is used.
"""
import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

CATALOG = pathlib.Path("Sources/CucumberSwift/CucumberSwift.docc")
STUBS = pathlib.Path("Tests/DocumentationExamples")
# The stub modules, one for each runner: {runner: (module, library product)}.
STUB_MODULES = {
    "xctest": ("XCTestStubs", "CucumberSwiftMacros"),
    "testing": ("SwiftTestingStubs", "CucumberSwiftTestingMacros"),
}
OUTPUT = pathlib.Path(".build/documentation-examples")

# Every block marked as a fragment: (article, reason), as the marker gives the reason.
FRAGMENTS = [
    ("Checking-Step-Definitions.md",
     "a Tuist Project.swift, which needs Tuist; Fixtures/SwiftTestingAndXCTestMacrosTuist builds one"),
    ("CucumberSwift+UIUTest.md",
     "needs the UIUTest package and your app, and UIKit, which a macOS build doesn't have"),
    ("Hooks.md",
     "uses UIKit, which a macOS build doesn't have"),
]

KINDS = ("file", "steps", "members", "manifest", "package-target", "target-arguments", "fragment")
OPTIONS = ("swift6", "bare-slash-regex", "features")

MARKER = re.compile(r"^\s*<!--\s*swift-example:\s*(?P<body>.*?)\s*-->\s*$")
FENCE_OPEN = re.compile(r"^(?P<indent>\s*)```swift\s*$")
IMPORT = re.compile(r"^\s*(?:@\w+\s+)*import\s+(?P<module>\w+)", re.MULTILINE)
CONFORMANCE = re.compile(r"extension\s+Cucumber\s*:\s*(?:@retroactive\s+)?StepImplementation\b")
TESTING_MODULES = {"CucumberSwiftTesting", "CucumberSwiftTestingMacros"}


class ExampleError(Exception):
    """The catalog's examples or markers are malformed."""


class Example:
    """One Swift example: where it is, its code, and how to compile it."""

    def __init__(self, path, line, code, kind="file", options=(), reason=None):
        self.path = path
        self.line = line
        self.code = code
        self.kind = kind
        self.options = tuple(options)
        self.reason = reason

    @property
    def location(self):
        return f"{self.path}:{self.line}"

    @property
    def target(self):
        """A target name, unique in the catalog: the file's name and the fence's line."""
        stem = re.sub(r"\W", "_", pathlib.PurePath(self.path).stem)
        return f"{stem}_{self.line}"

    @property
    def runner(self):
        """`testing` for CucumberSwiftTesting, `xctest` for CucumberSwift."""
        modules = set(IMPORT.findall(self.code))
        return "testing" if modules & TESTING_MODULES else "xctest"

    @property
    def is_manifest(self):
        return self.kind in ("manifest", "package-target", "target-arguments")


def parse_marker(body, location):
    """The kind, options and reason in a marker's body."""
    kind, _, rest = body.partition(":") if body.startswith("fragment") else (body, "", "")
    if kind.strip() == "fragment":
        reason = rest.strip()
        if not reason:
            raise ExampleError(f"{location}: a fragment marker needs a reason: "
                               "<!-- swift-example: fragment: <reason> -->")
        return "fragment", (), reason
    words = body.split()
    if not words or words[0] not in KINDS or words[0] == "manifest":
        raise ExampleError(f"{location}: unknown swift-example kind in '{body}'. Use one of: "
                           "file, steps, members, package-target, target-arguments, "
                           "fragment: <reason>")
    unknown = [word for word in words[1:] if word not in OPTIONS]
    if unknown:
        raise ExampleError(f"{location}: unknown swift-example option {', '.join(unknown)}. "
                           f"Use: {', '.join(OPTIONS)}")
    return words[0], words[1:], None


def blocks_in_article(path, text):
    """The Swift examples in one article."""
    examples = []
    lines = text.split("\n")
    index = 0
    pending = None  # (kind, options, reason, line) of a marker waiting for its fence
    while index < len(lines):
        line = lines[index]
        marker = MARKER.match(line)
        fence = FENCE_OPEN.match(line)
        if marker:
            if pending:
                raise ExampleError(f"{path}:{pending[3]}: a swift-example marker must be "
                                   "followed by a ```swift block")
            pending = (*parse_marker(marker.group("body"), f"{path}:{index + 1}"), index + 1)
        elif fence:
            indent = fence.group("indent")
            start = index + 1
            body = []
            index += 1
            while index < len(lines) and lines[index].strip() != "```":
                body.append(lines[index][len(indent):] if lines[index].startswith(indent)
                            else lines[index].lstrip())
                index += 1
            if index == len(lines):
                raise ExampleError(f"{path}:{start}: the ```swift block is never closed")
            code = "\n".join(body) + "\n"
            if pending:
                kind, options, reason, _ = pending
                pending = None
            elif code.lstrip().startswith("// swift-tools-version"):
                kind, options, reason = "manifest", (), None
            else:
                kind, options, reason = "file", (), None
            examples.append(Example(path, start, code, kind, options, reason))
        elif pending and line.strip():
            raise ExampleError(f"{path}:{pending[3]}: a swift-example marker must be on the "
                               "line before a ```swift block")
        index += 1
    if pending:
        raise ExampleError(f"{path}:{pending[3]}: a swift-example marker must be followed by "
                           "a ```swift block")
    return examples


def find_examples(catalog=CATALOG):
    """Every Swift example in the catalog, articles first, then the tutorials' code files."""
    examples = []
    for article in sorted(catalog.rglob("*.md")):
        examples += blocks_in_article(str(article), article.read_text(encoding="utf-8"))
    for source in sorted(catalog.rglob("*.swift")):
        examples.append(Example(str(source), 1, source.read_text(encoding="utf-8")))
    return examples


def check_fragments(examples, expected=FRAGMENTS):
    """Fails unless the fragments marked in the catalog are exactly the expected ones."""
    marked = sorted((pathlib.PurePath(e.path).name, e.reason)
                    for e in examples if e.kind == "fragment")
    if marked != sorted(expected):
        extra = [f"  {name}: {reason}" for name, reason in marked if (name, reason) not in expected]
        missing = [f"  {name}: {reason}" for name, reason in expected if (name, reason) not in marked]
        message = ["The fragments marked in the catalog differ from FRAGMENTS in "
                   ".github/scripts/docs_examples.py."]
        if extra:
            message += ["Marked, but not in FRAGMENTS:"] + extra
        if missing:
            message += ["In FRAGMENTS, but not marked:"] + missing
        raise ExampleError("\n".join(message))


def default_imports(runner):
    if runner == "testing":
        return "import Foundation\nimport Testing\nimport CucumberSwiftTestingMacros\n"
    return "import Foundation\nimport XCTest\nimport CucumberSwiftMacros\n"


def completion(example, code):
    """The StepImplementation requirements a block that declares the conformance leaves out."""
    if not CONFORMANCE.search(code):
        return ""
    members = []
    if not re.search(r"\bfunc\s+setupSteps\s*\(", code):
        members.append("    public func setupSteps() {}")
    if example.runner == "xctest" and not re.search(r"\bvar\s+bundle\s*:", code):
        members.append("    public var bundle: Bundle { Bundle.main }")
    if not members:
        return ""
    return ("// Supplied by docs_examples.py: what the example leaves out as usual.\n"
            f"{default_imports(example.runner)}\nextension Cucumber {{\n"
            + "\n".join(members) + "\n}\n")


def indented(code, spaces):
    return "".join((" " * spaces + line) if line.strip() else line
                   for line in code.splitlines(keepends=True))


def swift_sources(example):
    """The files of an example's target, as {file name: contents}."""
    code = example.code
    has_imports = bool(IMPORT.search(code))
    retroactive = "@retroactive " if "swift6" in example.options else ""
    if example.kind == "steps":
        code = (f"extension Cucumber: {retroactive}StepImplementation {{\n"
                "    public func setupSteps() {\n"
                f"{indented(code, 8)}    }}\n}}\n")
    elif example.kind == "members":
        code = f"extension Cucumber: {retroactive}StepImplementation {{\n{indented(code, 4)}}}\n"
    header = f"// {example.location}\nimport {STUB_MODULES[example.runner][0]}\n"
    if not has_imports:
        header += default_imports(example.runner)
    sources = {"Example.swift": header + code}
    extra = completion(example, code)
    if extra:
        sources["Completion.swift"] = extra
    return sources


def manifest_source(example):
    """An example's Package.swift."""
    if example.kind == "manifest":
        return example.code
    if example.kind == "target-arguments":
        target = f'.target(\n    name: "Example",\n{indented(example.code, 4).rstrip()}\n)\n'
    else:
        target = example.code
    return ("// swift-tools-version:6.1\n"
            f"// {example.location}\n"
            "import PackageDescription\n\n"
            "let package = Package(\n"
            '    name: "Example",\n'
            "    dependencies: [\n"
            '        .package(url: "https://github.com/cucumberswift/CucumberSwift.git", from: "6.0.0")\n'
            "    ],\n"
            "    targets: [\n"
            f"{indented(target, 8).rstrip()}\n"
            "    ]\n"
            ")\n")


def target(name, dependencies, path, settings=(), features=False):
    return ("        .target(\n"
            f'            name: "{name}",\n'
            f"            dependencies: [{', '.join(dependencies)}],\n"
            f'            path: "{path}"'
            + (',\n            resources: [.copy("Features")]' if features else "")
            + (f",\n            swiftSettings: [{', '.join(settings)}]" if settings else "")
            + ")")


def product(name):
    return f'.product(name: "{name}", package: "CucumberSwift")'


def package_manifest(examples, root):
    """The Package.swift of the package that compiles every Swift example."""
    targets = [target(module, [product(library)], f"Stubs/{module}")
               for module, library in STUB_MODULES.values()]
    for example in examples:
        module, library = STUB_MODULES[example.runner]
        settings = []
        if "swift6" in example.options:
            settings.append(".swiftLanguageMode(.v6)")
        if "bare-slash-regex" in example.options:
            settings.append('.enableUpcomingFeature("BareSlashRegexLiterals")')
        targets.append(target(example.target, [f'"{module}"', product(library)],
                              f"Examples/{example.target}", settings,
                              features="features" in example.options))
    return ("// swift-tools-version:6.1\n"
            "// Generated by .github/scripts/docs_examples.py. Do not edit.\n"
            "import PackageDescription\n\n"
            "let package = Package(\n"
            '    name: "DocumentationExamples",\n'
            "    platforms: [.macOS(.v13)],\n"
            "    dependencies: [\n"
            f'        .package(name: "CucumberSwift", path: {swift_string(root)}, traits: ["Macros"])\n'
            "    ],\n"
            "    targets: [\n"
            + ",\n".join(targets) + "\n"
            "    ],\n"
            "    swiftLanguageModes: [.v5]\n"
            ")\n")


def swift_string(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_package(examples, root, output):
    """Writes the package of Swift examples and the manifest examples' packages."""
    if output.exists():
        for child in output.iterdir():
            if child.name != ".build":
                shutil.rmtree(child) if child.is_dir() else child.unlink()
    output.mkdir(parents=True, exist_ok=True)
    swift = [e for e in examples if e.kind != "fragment" and not e.is_manifest]
    for example in swift:
        folder = output / "Examples" / example.target
        folder.mkdir(parents=True)
        for name, contents in swift_sources(example).items():
            (folder / name).write_text(contents, encoding="utf-8")
        if "features" in example.options:
            (folder / "Features").mkdir()
            (folder / "Features" / "Example.feature").write_text(
                "Feature: Example\n", encoding="utf-8")
    for module, _ in STUB_MODULES.values():
        folder = output / "Stubs" / module
        folder.mkdir(parents=True)
        shutil.copy(root / STUBS / f"{module}.swift", folder)
    (output / "Package.swift").write_text(package_manifest(swift, root), encoding="utf-8")
    for example in examples:
        if example.is_manifest:
            folder = output / "Manifests" / example.target
            folder.mkdir(parents=True)
            (folder / "Package.swift").write_text(manifest_source(example), encoding="utf-8")


def check_manifest(folder):
    result = subprocess.run(["swift", "package", "dump-package", "--package-path", str(folder)],
                            capture_output=True, text=True, check=False)
    return result.returncode, result.stdout + result.stderr


def compile_examples(examples, root, output):
    """Builds every example. Returns whether all of them compiled."""
    write_package(examples, root, output)
    ok = True
    manifests = [e for e in examples if e.is_manifest]
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        results = pool.map(lambda e: check_manifest(output / "Manifests" / e.target), manifests)
        for example, (status, log) in zip(manifests, results):
            if status != 0:
                ok = False
                print(f"error: {example.location}: the Package.swift example doesn't compile\n{log}")
    print(f"Checked {len(manifests)} Package.swift examples with `swift package dump-package`.",
          flush=True)
    swift = [e for e in examples if e.kind != "fragment" and not e.is_manifest]
    build = subprocess.run(["swift", "build", "--package-path", str(output)], check=False)
    if build.returncode != 0:
        ok = False
        print("error: a Swift example in the documentation doesn't compile. Each target in "
              f"{output}/Examples is named after the article and the line of its ```swift block.")
    else:
        print(f"Compiled {len(swift)} Swift examples.")
    return ok


def describe(example):
    if example.kind == "fragment":
        return f"fragment ({example.reason})"
    details = [example.kind]
    if not example.is_manifest:
        details.append("Swift Testing" if example.runner == "testing" else "XCTest")
    details += example.options
    return ", ".join(details)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--list", action="store_true",
                        help="list the examples and how each compiles, without compiling")
    args = parser.parse_args(argv)
    root = pathlib.Path.cwd()
    try:
        examples = find_examples(root / CATALOG)
        check_fragments(examples)
    except ExampleError as error:
        print(f"error: {error}")
        return 1
    for example in examples:
        print(f"{os.path.relpath(example.path, root)}:{example.line}: {describe(example)}")
    print(f"{len(examples)} examples, {sum(e.kind == 'fragment' for e in examples)} of them fragments.",
          flush=True)
    if args.list:
        return 0
    return 0 if compile_examples(examples, root, root / OUTPUT) else 1


if __name__ == "__main__":
    sys.exit(main())
