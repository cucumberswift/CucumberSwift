"""Unit tests for check_manifest.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

Each test passes dump-package output in, so the tests need no Swift toolchain.
Only the standard library is used.
"""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_manifest  # noqa: E402


def dump(version, products=("CucumberSwift",)):
    return json.dumps({"toolsVersion": {"_version": version},
                       "products": [{"name": name, "type": {"library": ["automatic"]}}
                                    for name in products]})


class CheckManifestTests(unittest.TestCase):
    def test_the_declared_tools_version_passes(self):
        ok, message = check_manifest.check("Package.swift", "// swift-tools-version:6.1\n",
                                           dump("6.1.0", ("CucumberSwift", "CucumberSwiftMacros")))
        self.assertTrue(ok, message)
        self.assertIn("read Package.swift (tools version 6.1.0)", message)
        self.assertIn("CucumberSwiftMacros (library)", message)

    def test_another_manifest_fails(self):
        ok, message = check_manifest.check("Package@swift-6.0.swift", "// swift-tools-version:6.0\n",
                                           dump("6.1.0"))
        self.assertFalse(ok)
        self.assertIn("tools version 6.1.0, not Package@swift-6.0.swift (tools version 6.0)", message)

    def test_the_line_may_have_a_space(self):
        ok, _ = check_manifest.check("Package.swift", "// swift-tools-version: 6.0.2\n", dump("6.0.2"))
        self.assertTrue(ok)

    def test_a_manifest_without_the_line_is_an_error(self):
        with self.assertRaises(ValueError):
            check_manifest.check("Package.swift", "import PackageDescription\n", dump("6.1.0"))


if __name__ == "__main__":
    unittest.main()
