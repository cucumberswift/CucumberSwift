"""Tests for the Gherkin highlighting for Xcode, in Tools/Xcode.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

They run gherkin-highlighting.sh install, status and uninstall with HOME set to
a temporary folder, never the real one, and check that the plug-in, the grammar
and the snippets are well formed and match "Highlight feature files" in the
"Running Tests in Xcode" article. They run on Linux and macOS. pgrep is
replaced with a fake that finds no Xcode, and where there is no PlistBuddy
(Linux), with a fake that reads the property list with plistlib.

Gherkin.xclangspec is an old-style property list, which plistlib cannot read,
so OldStylePlist below parses it. What only Xcode can tell, such as whether it
accepts the grammar's rules and how it colors them, is not tested. Its Match
patterns are ICU regular expressions; they are compiled with Python's re,
which accepts the simple patterns used.

Only the standard library is used.
"""
import os
import plistlib
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
import uuid

REPOSITORY = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TOOLS = os.path.join(REPOSITORY, "Tools", "Xcode")
SCRIPT = os.path.join(TOOLS, "gherkin-highlighting.sh")
PLUGIN = os.path.join(TOOLS, "Gherkin.ideplugin")
GRAMMAR = os.path.join(TOOLS, "Gherkin.xclangspec")
SNIPPETS = os.path.join(TOOLS, "Snippets")
ARTICLE = os.path.join(
    REPOSITORY, "Sources", "CucumberSwift", "CucumberSwift.docc", "Running-Tests-In-Xcode.md"
)
PLISTBUDDY = "/usr/libexec/PlistBuddy"
NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8}

# Prints one key of a property list, as `PlistBuddy -c 'Print :<key>' <file>` does.
FAKE_PLISTBUDDY = """\
import plistlib, sys
if len(sys.argv) != 4 or sys.argv[1] != "-c" or not sys.argv[2].startswith("Print :"):
    sys.exit("fake PlistBuddy: unexpected arguments %r" % sys.argv[1:])
with open(sys.argv[3], "rb") as handle:
    print(plistlib.load(handle)[sys.argv[2][len("Print :"):]])
"""


def snippet_paths():
    return sorted(
        os.path.join(SNIPPETS, name) for name in os.listdir(SNIPPETS) if name.endswith(".codesnippet")
    )


def load_plist(path):
    with open(path, "rb") as handle:
        return plistlib.load(handle)


def read(path):
    with open(path, "rb") as handle:
        return handle.read()


def tree(root):
    """Every folder, file and link under root, relative to it, with each file's bytes."""
    found = {}
    for folder, folders, files in os.walk(root):
        for name in folders + files:
            path = os.path.join(folder, name)
            relative = os.path.relpath(path, root)
            if os.path.islink(path):
                found[relative] = ("link", os.readlink(path))
            elif os.path.isdir(path):
                found[relative] = ("folder",)
            else:
                found[relative] = ("file", read(path))
    return found


def documented_items():
    """The installed paths and the number of snippets that the article lists."""
    with open(ARTICLE, encoding="utf-8") as handle:
        article = handle.read()
    section = article.split("### Highlight feature files", 1)[1].split("\n### ", 1)[0]
    listed = section.split("The script installs these items:", 1)[1].strip().split("\n\n", 1)[0]
    items = {}
    for line in listed.splitlines():
        path = re.search(r"`~/([^`]+)`", line).group(1)
        count = re.match(r"- (\w+) snippets in ", line)
        if count:
            items["snippets"] = (path, NUMBERS[count.group(1)])
        else:
            items[os.path.basename(path)] = path
    return items


class OldStylePlist:
    """A parser for old-style (OpenStep) property lists, such as .xclangspec files.

    Dictionaries are { key = value; ... }, arrays ( value, ... ) with an optional
    trailing comma, strings are quoted or bare, and // and /* */ are comments.
    It raises ValueError, with the line, for anything else.
    """

    SPACE = re.compile(r"(?:\s+|//[^\n]*|/\*.*?\*/)*", re.S)
    BARE = re.compile(r"[A-Za-z0-9_$+/:.-]+")
    ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\", "a": "\a", "b": "\b",
               "f": "\f", "v": "\v"}

    def __init__(self, text):
        self.text = text
        self.position = 0

    @classmethod
    def parse(cls, text):
        parser = cls(text)
        value = parser.value()
        parser.skip()
        if parser.position != len(text):
            parser.fail("text after the end of the property list")
        return value

    def fail(self, message):
        line = self.text.count("\n", 0, self.position) + 1
        raise ValueError(f"line {line}: {message}")

    def skip(self):
        self.position = self.SPACE.match(self.text, self.position).end()
        if self.text.startswith("/*", self.position):
            self.fail("unterminated comment")

    def peek(self):
        self.skip()
        return self.text[self.position:self.position + 1]

    def expect(self, char):
        if self.peek() != char:
            self.fail(f"expected {char!r}, found {self.peek() or 'the end'!r}")
        self.position += 1

    def value(self):
        char = self.peek()
        if char == "{":
            return self.dictionary()
        if char == "(":
            return self.array()
        return self.string()

    def dictionary(self):
        self.expect("{")
        result = {}
        while self.peek() != "}":
            key = self.string()
            if key in result:
                self.fail(f"duplicate key {key!r}")
            self.expect("=")
            result[key] = self.value()
            self.expect(";")
        self.position += 1
        return result

    def array(self):
        self.expect("(")
        result = []
        while self.peek() != ")":
            result.append(self.value())
            if self.peek() != ")":
                self.expect(",")
        self.position += 1
        return result

    def string(self):
        if self.peek() != '"':
            match = self.BARE.match(self.text, self.position)
            if not match:
                self.fail(f"expected a value, found {self.peek() or 'the end'!r}")
            self.position = match.end()
            return match.group()
        self.position += 1
        result = []
        while True:
            if self.position >= len(self.text):
                self.fail("unterminated string")
            char = self.text[self.position]
            self.position += 1
            if char == '"':
                return "".join(result)
            if char == "\\":
                escape = self.text[self.position:self.position + 1]
                if escape not in self.ESCAPES:
                    self.fail(f"unknown escape \\{escape}")
                result.append(self.ESCAPES[escape])
                self.position += 1
            else:
                result.append(char)


class OldStylePlistTests(unittest.TestCase):
    def test_parses_dictionaries_arrays_strings_and_comments(self):
        text = '// c\n( { A = "x\\"y\\n"; /* c */ B = ( b.c, "d", ); }, )'
        self.assertEqual(OldStylePlist.parse(text), [{"A": 'x"y\n', "B": ["b.c", "d"]}])

    def test_rejects_malformed_lists(self):
        for text in ['{ A = "x" }', '( "a" "b" )', '{ A = "x"; A = "y"; }', '( "a', "( a ) )",
                     "/* a", '( "\\q" )']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                OldStylePlist.parse(text)


class ScriptTests(unittest.TestCase):
    """install, status and uninstall, with HOME set to a temporary folder."""

    def setUp(self):
        temporary = tempfile.mkdtemp(prefix="gherkin-highlighting-")
        self.addCleanup(shutil.rmtree, temporary)
        self.home = os.path.join(temporary, "home")
        os.mkdir(self.home)
        self.xcode = os.path.join(self.home, "Library", "Developer", "Xcode")
        fakes = os.path.join(temporary, "bin")
        os.mkdir(fakes)
        self.write_fake(fakes, "pgrep", "#!/bin/sh\nexit 1\n")
        self.environment = dict(os.environ, HOME=self.home, PATH=fakes + os.pathsep + os.environ["PATH"])
        if not os.path.exists(PLISTBUDDY):
            self.environment["PLISTBUDDY"] = self.write_fake(
                fakes, "PlistBuddy", f"#!{sys.executable}\n{FAKE_PLISTBUDDY}"
            )
        else:
            self.environment.pop("PLISTBUDDY", None)

    @staticmethod
    def write_fake(folder, name, text):
        path = os.path.join(folder, name)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        os.chmod(path, stat.S_IRWXU)
        return path

    def run_script(self, *arguments, status=0):
        # Never the real home folder.
        self.assertTrue(self.environment["HOME"].startswith(tempfile.gettempdir()))
        result = subprocess.run(
            ["bash", SCRIPT, *arguments], env=self.environment, capture_output=True, text=True,
            timeout=60,
        )
        self.assertEqual(result.returncode, status, result.stdout + result.stderr)
        return result.stdout

    def expected_items(self):
        """Each installed path, relative to HOME, with the file or folder it copies."""
        items = {
            os.path.join("Library", "Developer", "Xcode", "Plug-ins", "Gherkin.ideplugin"): PLUGIN,
            os.path.join("Library", "Developer", "Xcode", "Specifications", "Gherkin.xclangspec"): GRAMMAR,
        }
        for snippet in snippet_paths():
            identifier = load_plist(snippet)["IDECodeSnippetIdentifier"]
            path = os.path.join("Library", "Developer", "Xcode", "UserData", "CodeSnippets")
            items[os.path.join(path, f"{identifier}.codesnippet")] = snippet
        return items

    def assert_installed(self):
        for relative, source in self.expected_items().items():
            installed = os.path.join(self.home, relative)
            if os.path.isdir(source):
                self.assertFalse(os.path.islink(installed))
                self.assertEqual(tree(installed), tree(source), relative)
            else:
                self.assertTrue(os.path.isfile(installed) and not os.path.islink(installed), relative)
                self.assertEqual(read(installed), read(source), relative)

    def test_install_copies_each_item_where_the_article_says(self):
        output = self.run_script("install")
        self.assert_installed()
        documented = documented_items()
        expected = self.expected_items()
        for name in ("Gherkin.ideplugin", "Gherkin.xclangspec"):
            self.assertIn(documented[name], expected)
        folder, count = documented["snippets"]
        self.assertEqual(
            sorted(path for path in expected if path.endswith(".codesnippet")),
            sorted(os.path.join(folder, name) for name in os.listdir(os.path.join(self.home, folder))),
        )
        self.assertEqual(count, len(snippet_paths()))
        for relative in expected:
            self.assertIn(f"  {os.path.join(self.home, relative)}\n", output)

    def test_install_adds_nothing_else(self):
        self.run_script("install")
        installed = set()
        for relative, source in self.expected_items().items():
            installed.add(relative)
            installed.update(os.path.join(relative, path) for path in tree(source))
            parent = os.path.dirname(relative)
            while parent:
                installed.add(parent)
                parent = os.path.dirname(parent)
        self.assertEqual(set(tree(self.home)), installed)

    def test_status_reports_each_item(self):
        paths = [os.path.join(self.home, relative) for relative in self.expected_items()]
        output = self.run_script("status")
        self.assertEqual(sorted(output.splitlines()), sorted(f"Not installed: {path}" for path in paths))
        self.assertEqual(tree(self.home), {})
        self.run_script("install")
        before = tree(self.home)
        output = self.run_script("status")
        self.assertEqual(sorted(output.splitlines()), sorted(f"Installed:     {path}" for path in paths))
        self.assertEqual(tree(self.home), before)

    def test_installing_again_replaces_the_installed_copy(self):
        self.run_script("install")
        plugin = os.path.join(self.xcode, "Plug-ins", "Gherkin.ideplugin")
        with open(os.path.join(plugin, "Contents", "Old.plist"), "w", encoding="utf-8") as handle:
            handle.write("left over")
        for relative, source in self.expected_items().items():
            if os.path.isfile(source):
                with open(os.path.join(self.home, relative), "w", encoding="utf-8") as handle:
                    handle.write("old")
        self.run_script("install")
        self.assert_installed()

    def test_install_replaces_links_without_writing_through_them(self):
        elsewhere = os.path.join(self.home, "elsewhere")
        os.makedirs(os.path.join(elsewhere, "Gherkin.ideplugin"))
        with open(os.path.join(elsewhere, "grammar"), "w", encoding="utf-8") as handle:
            handle.write("someone else's file")
        before = tree(elsewhere)
        os.makedirs(os.path.join(self.xcode, "Plug-ins"))
        os.makedirs(os.path.join(self.xcode, "Specifications"))
        os.symlink(os.path.join(elsewhere, "Gherkin.ideplugin"),
                   os.path.join(self.xcode, "Plug-ins", "Gherkin.ideplugin"))
        os.symlink(os.path.join(elsewhere, "grammar"),
                   os.path.join(self.xcode, "Specifications", "Gherkin.xclangspec"))
        self.run_script("install")
        self.assert_installed()
        self.assertEqual(tree(elsewhere), before)

    def test_uninstall_removes_exactly_what_install_added(self):
        others = {
            os.path.join("Plug-ins", "Other.ideplugin", "Contents", "Info.plist"): "other plug-in",
            os.path.join("Specifications", "Other.xclangspec"): "other grammar",
            os.path.join("UserData", "CodeSnippets", "other.codesnippet"): "other snippet",
            os.path.join("UserData", "FontAndColorThemes", "Theme.xccolortheme"): "theme",
        }
        for relative, text in others.items():
            path = os.path.join(self.xcode, relative)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(text)
        before = tree(self.home)
        self.run_script("install")
        output = self.run_script("uninstall")
        self.assertEqual(tree(self.home), before)
        for relative in self.expected_items():
            self.assertIn(f"Removed {os.path.join(self.home, relative)}\n", output)

    def test_uninstall_when_not_installed_changes_nothing(self):
        output = self.run_script("uninstall")
        self.assertEqual(output, "Gherkin highlighting is not installed.\n")
        self.assertEqual(tree(self.home), {})

    def test_an_unknown_command_prints_the_usage(self):
        for arguments in [(), ("remove",)]:
            with self.subTest(arguments=arguments):
                self.assertEqual(self.run_script(*arguments, status=64), "")
        self.assertEqual(tree(self.home), {})


class FileTests(unittest.TestCase):
    """The plug-in, the grammar and the snippets are well formed and agree."""

    @classmethod
    def setUpClass(cls):
        cls.plugin_data = load_plist(
            os.path.join(PLUGIN, "Contents", "Resources", "Gherkin.xcplugindata")
        )["plug-in"]["extensions"]
        cls.language = cls.plugin_data["Xcode.SourceCodeLanguage.Gherkin"]
        with open(GRAMMAR, encoding="utf-8") as handle:
            cls.grammar = OldStylePlist.parse(handle.read())

    def test_the_plugin_has_only_its_property_lists(self):
        self.assertEqual(
            sorted(tree(PLUGIN)),
            ["Contents", os.path.join("Contents", "Info.plist"), os.path.join("Contents", "Resources"),
             os.path.join("Contents", "Resources", "Gherkin.xcplugindata")],
        )
        info = load_plist(os.path.join(PLUGIN, "Contents", "Info.plist"))
        self.assertEqual(info["CFBundlePackageType"], "BNDL")
        self.assertEqual(info["CFBundleIdentifier"], "org.cucumberswift.xcode.gherkin")
        self.assertNotIn("CFBundleExecutable", info)

    def test_the_plugin_makes_feature_files_gherkin(self):
        detector = self.plugin_data["Xcode.FileDataTypeDetector.Gherkin"]
        file_type = self.plugin_data["Xcode.FileDataType.Gherkin"]
        self.assertEqual(detector["matchesExtension"], "feature")
        self.assertEqual(detector["detectedTypeIdentifier"], file_type["typeIdentifier"])
        self.assertEqual(self.language["fileDataType"], [{"identifier": file_type["typeIdentifier"]}])
        for identifier, extension in self.plugin_data.items():
            self.assertEqual(extension["id"], identifier)

    def test_each_snippet_has_the_fields_xcode_needs(self):
        identifiers = set()
        for path in snippet_paths():
            with self.subTest(snippet=os.path.basename(path)):
                snippet = load_plist(path)
                for key in ("IDECodeSnippetTitle", "IDECodeSnippetContents", "IDECodeSnippetSummary",
                            "IDECodeSnippetCompletionPrefix"):
                    self.assertIsInstance(snippet.get(key), str, key)
                    self.assertTrue(snippet[key].strip(), key)
                scopes = snippet.get("IDECodeSnippetCompletionScopes")
                self.assertIsInstance(scopes, list)
                self.assertTrue(scopes and all(isinstance(scope, str) and scope for scope in scopes))
                identifier = snippet["IDECodeSnippetIdentifier"]
                self.assertEqual(str(uuid.UUID(identifier)), identifier.lower())
                self.assertNotIn(identifier, identifiers)
                identifiers.add(identifier)
                self.assertEqual(snippet["IDECodeSnippetLanguage"], self.language["id"])
                self.assertIs(snippet["IDECodeSnippetUserSnippet"], True)
                self.assertIsInstance(snippet["IDECodeSnippetVersion"], int)
                self.assertTrue(snippet["IDECodeSnippetContents"].endswith("\n"))

    def test_the_grammar_defines_each_rule_it_uses(self):
        self.assertIsInstance(self.grammar, list)
        rules = {}
        for rule in self.grammar:
            self.assertIsInstance(rule, dict)
            self.assertNotIn(rule["Identifier"], rules)
            self.assertIsInstance(rule["Syntax"], dict)
            rules[rule["Identifier"]] = rule
        root = rules[self.language["languageSpecification"]]
        self.assertEqual(root["Name"], self.language["languageName"])
        used = set()
        for rule in rules.values():
            used.update(rule["Syntax"].get("IncludeRules", []))
        gherkin_rules = {name for name in rules if name.startswith("xcode.lang.gherkin.")}
        used_gherkin_rules = {name for name in used if name.startswith("xcode.lang.gherkin")}
        self.assertEqual(used_gherkin_rules, gherkin_rules, "a rule used but not defined, or defined but unused")

    def test_the_grammar_patterns_compile(self):
        for rule in self.grammar:
            for pattern in rule["Syntax"].get("Match", []):
                with self.subTest(rule=rule["Identifier"], pattern=pattern):
                    re.compile(pattern)

    def test_the_article_lists_every_item(self):
        documented = documented_items()
        self.assertEqual(
            sorted(documented),
            ["Gherkin.ideplugin", "Gherkin.xclangspec", "snippets"],
        )
        self.assertEqual(documented["snippets"][1], len(snippet_paths()))

    def test_a_change_to_the_article_runs_script_tests(self):
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import docs_only
        self.assertIn(os.path.relpath(ARTICLE, REPOSITORY), docs_only.SCRIPT_TESTED_DOCS)


if __name__ == "__main__":
    unittest.main()
