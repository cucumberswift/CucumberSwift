"""Unit tests for sonar_coverage.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

xccov is replaced with a fake, so the tests need no Xcode. Only the standard
library is used.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from contextlib import redirect_stdout
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
    def run_main(self, *args):
        with redirect_stdout(StringIO()) as out:
            sonar_coverage.main(list(args))
        return out.getvalue()

    def test_converts_an_lcov_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "Sources", "A.swift")
            lcov = os.path.join(tmp, "info.lcov")
            output = os.path.join(tmp, "out.xml")
            with open(lcov, "w", encoding="utf-8") as handle:
                handle.write(f"SF:{source}\nDA:1,1\nDA:2,0\nend_of_record\n")
            printed = self.run_main("--lcov", lcov, "--root", tmp, "--include", "Sources",
                                    "--output", output)
            with open(output, encoding="utf-8") as handle:
                self.assertEqual(lines_of(handle.read()),
                                 {os.path.join("Sources", "A.swift"): {1: True, 2: False}})
            self.assertIn("1 files (2 lines)", printed)

    def test_converts_an_xcresult_through_xccov(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = os.path.join(tmp, "Sources", "A.swift")
            output = os.path.join(tmp, "out.xml")
            report = {source: [{"line": 7, "isExecutable": True, "executionCount": 1}]}
            done = subprocess.CompletedProcess([], 0, stdout=json.dumps(report), stderr="")
            with mock.patch.object(sonar_coverage.subprocess, "run", return_value=done) as run:
                self.run_main("--xcresult", "T.xcresult", "--root", tmp, "--output", output)
            self.assertEqual(run.call_args.args[0],
                             ["xcrun", "xccov", "view", "--archive", "--json", "T.xcresult"])
            with open(output, encoding="utf-8") as handle:
                self.assertEqual(lines_of(handle.read()),
                                 {os.path.join("Sources", "A.swift"): {7: True}})

    def test_fails_when_xccov_fails(self):
        failed = subprocess.CompletedProcess([], 1, stdout="", stderr="bad bundle")
        with mock.patch.object(sonar_coverage.subprocess, "run", return_value=failed):
            with self.assertRaises(SystemExit) as raised:
                self.run_main("--xcresult", "T.xcresult", "--root", ".", "--output", "o.xml")
        self.assertEqual(raised.exception.code, 1)

    def test_fails_when_no_file_is_under_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            lcov = os.path.join(tmp, "info.lcov")
            with open(lcov, "w", encoding="utf-8") as handle:
                handle.write("SF:/nowhere/A.swift\nDA:1,1\nend_of_record\n")
            with self.assertRaises(SystemExit) as raised:
                self.run_main("--lcov", lcov, "--root", tmp,
                              "--output", os.path.join(tmp, "out.xml"))
            self.assertEqual(raised.exception.code, 1)
            self.assertFalse(os.path.exists(os.path.join(tmp, "out.xml")))


if __name__ == "__main__":
    unittest.main()
