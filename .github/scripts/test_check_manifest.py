"""Unit tests for check_manifest.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

Each test passes dump-package output in, so the tests need no Swift toolchain.
Only the standard library is used.
"""
import contextlib
import io
import json
import os
import re
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_manifest  # noqa: E402


def dump(version, products=("CucumberSwift",), targets=("CucumberSwift",)):
    return json.dumps({"toolsVersion": {"_version": version},
                       "products": [{"name": name, "type": {"library": ["automatic"]}}
                                    for name in products],
                       "targets": [{"name": name} for name in targets]})


class CheckManifestTests(unittest.TestCase):
    def test_the_declared_tools_version_passes(self):
        ok, message = check_manifest.check("Package.swift", "// swift-tools-version:6.1\n",
                                           dump("6.1.0", ("CucumberSwift", "CucumberSwiftMacros")))
        self.assertTrue(ok, message)
        self.assertIn("read Package.swift (tools version 6.1.0)", message)
        self.assertIn("CucumberSwiftMacros (library)", message)

    def test_a_product_named_like_its_target_passes(self):
        ok, message = check_manifest.check("Package.swift", "// swift-tools-version:6.1\n",
                                           dump("6.1", ("CucumberSwift", "cucumberswift-cli"),
                                                ("CucumberSwift", "CucumberSwiftCommand")))
        self.assertTrue(ok, message)

    def test_names_that_differ_only_in_case_fail(self):
        # #603: a cucumberswift product shared the CucumberSwift target's build folder in Xcode.
        ok, message = check_manifest.check("Package.swift", "// swift-tools-version:6.1\n",
                                           dump("6.1", ("CucumberSwift", "cucumberswift"),
                                                ("CucumberSwift", "CucumberSwiftCommand")))
        self.assertFalse(ok)
        self.assertIn("differ only in case: CucumberSwift and cucumberswift.", message)

    def test_this_package_has_no_names_that_differ_only_in_case(self):
        names = set()
        for path in ("Package.swift", "Package@swift-6.0.swift"):
            with open(path, encoding="utf-8") as handle:
                names.update(re.findall(r'^\s*name: "([^"]+)"', handle.read(), re.MULTILINE))
        folded = {}
        for name in names:
            folded.setdefault(name.casefold(), set()).add(name)
        self.assertEqual([group for group in folded.values() if len(group) > 1], [])

    def test_another_manifest_fails(self):
        ok, message = check_manifest.check("Package@swift-6.0.swift", "// swift-tools-version:6.0\n",
                                           dump("6.1.0"))
        self.assertFalse(ok)
        self.assertIn("tools version 6.1.0, not Package@swift-6.0.swift (tools version 6.0)", message)

    def test_the_line_may_have_a_space(self):
        ok, _ = check_manifest.check("Package.swift", "// swift-tools-version: 6.0.2\n", dump("6.0.2"))
        self.assertTrue(ok)

    def test_a_manifest_without_the_line_is_an_error(self):
        output = dump("6.1.0")
        with self.assertRaises(ValueError):
            check_manifest.check("Package.swift", "import PackageDescription\n", output)

    def test_only_the_package_manifests_are_read(self):
        with contextlib.redirect_stderr(io.StringIO()) as error:
            status = check_manifest.main(["check_manifest.py", "../Package.swift"])
        self.assertEqual(status, 2)
        self.assertIn("is not one of this package's manifests", error.getvalue())


if __name__ == "__main__":
    unittest.main()
