"""Unit tests for sonar_coverage.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

xccov is replaced with a fake, so the tests need no Xcode. main() runs in a
temporary directory, since its paths are fixed relative to the working one. Only the standard
library is used.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sonar_coverage  # noqa: E402


def lines_of(xml_text):
    """{path: {line: covered}} read back from the generic coverage XML."""
    top = ET.fromstring(xml_text)
    return {
        node.get("path"): {int(line.get("lineNumber")): line.get("covered") == "true"
                           for line in node}
        for node in top
    }


class XccovTests(unittest.TestCase):
    def test_keeps_only_executable_lines(self):
        report = {"/r/Sources/A.swift": [
            {"line": 1, "isExecutable": False},
            {"line": 2, "isExecutable": True, "executionCount": 3},
            {"line": 3, "isExecutable": True, "executionCount": 0},
        ]}
        self.assertEqual(sonar_coverage.from_xccov(report),
                         {"/r/Sources/A.swift": {2: True, 3: False}})

    def test_executable_line_without_a_count_is_not_covered(self):
        report = {"/r/A.swift": [{"line": 4, "isExecutable": True}]}
        self.assertEqual(sonar_coverage.from_xccov(report), {"/r/A.swift": {4: False}})


class LcovTests(unittest.TestCase):
    def test_reads_line_records(self):
        text = "TN:\nSF:/r/Sources/A.swift\nDA:1,0\nDA:2,5,abc123\nLH:1\nend_of_record\n"
        self.assertEqual(sonar_coverage.from_lcov(text),
                         {"/r/Sources/A.swift": {1: False, 2: True}})

    def test_a_line_covered_in_any_record_stays_covered(self):
        text = ("SF:/r/A.swift\nDA:1,0\nDA:2,1\nend_of_record\n"
                "SF:/r/A.swift\nDA:1,2\nDA:2,0\nend_of_record\n")
        self.assertEqual(sonar_coverage.from_lcov(text), {"/r/A.swift": {1: True, 2: True}})

    def test_ignores_line_records_outside_a_file(self):
        self.assertEqual(sonar_coverage.from_lcov("DA:1,1\nend_of_record\n"), {})


class RootTests(unittest.TestCase):
    def test_keeps_files_under_root_with_relative_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = os.path.join(tmp, "repo")
            coverage = {
                os.path.join(root, "Sources", "My File.swift"): {1: True},
                os.path.join(tmp, "repo-other", "B.swift"): {1: True},
                os.path.join(tmp, "elsewhere", "C.swift"): {1: False},
            }
            self.assertEqual(sonar_coverage.relative_to_root(coverage, root),
                             {os.path.join("Sources", "My File.swift"): {1: True}})

    def test_include_keeps_only_files_under_those_folders(self):
        with tempfile.TemporaryDirectory() as tmp:
            coverage = {
                os.path.join(tmp, "Sources", "A.swift"): {1: True},
                os.path.join(tmp, "SourcesOld", "B.swift"): {1: True},
                os.path.join(tmp, "Tests", "C.swift"): {1: True},
                os.path.join(tmp, ".build", "runner.swift"): {1: False},
            }
            self.assertEqual(sonar_coverage.relative_to_root(coverage, tmp, ["Sources"]),
                             {os.path.join("Sources", "A.swift"): {1: True}})


class XmlTests(unittest.TestCase):
    def test_writes_generic_coverage(self):
        xml_text = sonar_coverage.to_xml({"Sources/B.swift": {3: False, 1: True},
                                          "Sources/A&B.swift": {2: True}})
        top = ET.fromstring(xml_text)
        self.assertEqual((top.tag, top.get("version")), ("coverage", "1"))
        self.assertEqual([node.get("path") for node in top],
                         ["Sources/A&B.swift", "Sources/B.swift"])
        self.assertEqual([line.get("lineNumber") for line in top[1]], ["1", "3"])
        self.assertEqual(lines_of(xml_text), {"Sources/A&B.swift": {2: True},
                                              "Sources/B.swift": {1: True, 3: False}})


class MainTests(unittest.TestCase):
    """main() run in a temporary repository root."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = os.path.realpath(self.tmp.name)
        cwd = os.getcwd()
        os.chdir(self.root)
        self.addCleanup(os.chdir, cwd)

    def run_main(self, *args):
        with redirect_stdout(StringIO()) as out:
            sonar_coverage.main(list(args))
        return out.getvalue()

    def assert_fails(self, *args, code=1):
        with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
            with self.assertRaises(SystemExit) as raised:
                sonar_coverage.main(list(args))
        self.assertEqual(raised.exception.code, code)
        self.assertFalse(os.path.exists(sonar_coverage.OUTPUT))

    def output(self):
        with open(sonar_coverage.OUTPUT, encoding="utf-8") as handle:
            return lines_of(handle.read())

    def make_bundle(self, name):
        path = os.path.join(self.root, "fastlane", "test_output", name)
        os.makedirs(path)
        return path

    def test_converts_info_lcov_keeping_only_sources(self):
        source = os.path.join(self.root, "Sources", "A.swift")
        test = os.path.join(self.root, "Tests", "ATests.swift")
        with open("info.lcov", "w", encoding="utf-8") as handle:
            handle.write(f"SF:{source}\nDA:1,1\nDA:2,0\nend_of_record\n"
                         f"SF:{test}\nDA:1,1\nend_of_record\n")
        printed = self.run_main("lcov")
        self.assertEqual(self.output(), {os.path.join("Sources", "A.swift"): {1: True, 2: False}})
        self.assertIn("1 files (2 lines)", printed)

    def test_converts_the_result_bundle_through_xccov(self):
        bundle = self.make_bundle("CucumberSwift.xcresult")
        source = os.path.join(self.root, "Sources", "A.swift")
        report = {source: [{"line": 7, "isExecutable": True, "executionCount": 1}]}
        done = subprocess.CompletedProcess([], 0, stdout=json.dumps(report), stderr="")
        with mock.patch.object(sonar_coverage.subprocess, "run", return_value=done) as run:
            self.run_main("xcresult")
        self.assertEqual(run.call_args.args[0],
                         ["xcrun", "xccov", "view", "--archive", "--json", bundle])
        self.assertEqual(self.output(), {os.path.join("Sources", "A.swift"): {7: True}})

    def test_fails_unless_there_is_exactly_one_result_bundle(self):
        with mock.patch.object(sonar_coverage.subprocess, "run") as run:
            self.assert_fails("xcresult")
            self.make_bundle("A.xcresult")
            self.make_bundle("B.xcresult")
            self.assert_fails("xcresult")
        run.assert_not_called()

    def test_fails_when_xccov_fails(self):
        self.make_bundle("CucumberSwift.xcresult")
        failed = subprocess.CompletedProcess([], 1, stdout="", stderr="bad bundle")
        with mock.patch.object(sonar_coverage.subprocess, "run", return_value=failed):
            self.assert_fails("xcresult")

    def test_fails_when_info_lcov_is_missing(self):
        self.assert_fails("lcov")

    def test_fails_when_no_file_is_under_sources(self):
        with open("info.lcov", "w", encoding="utf-8") as handle:
            handle.write("SF:/nowhere/A.swift\nDA:1,1\nend_of_record\n")
        self.assert_fails("lcov")

    def test_rejects_any_other_argument(self):
        self.assert_fails("info.lcov", code=2)
        self.assert_fails("lcov", "--output", "x.xml", code=2)


if __name__ == "__main__":
    unittest.main()
