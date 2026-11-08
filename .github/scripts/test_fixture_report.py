"""Unit tests for fixture_report.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

Only the standard library is used.
"""
import io
import json
import os
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fixture_report  # noqa: E402


def feature(name, scenarios=1):
    return {"name": name, "uri": f"{name}.feature", "elements": [{"name": f"S{i}"} for i in range(scenarios)]}


class FixtureReportTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.folder)

    def write(self, name, text):
        path = os.path.join(self.folder, name)
        with open(path, "w", encoding="utf-8") as file:
            file.write(text)
        return path

    def run_main(self, *args):
        output = io.StringIO()
        with redirect_stdout(output):
            status = fixture_report.main(["fixture_report.py", *args])
        return status, output.getvalue()

    def check(self, expected, features):
        return self.run_main("check", self.write("expected-report", expected),
                             self.write("report.json", json.dumps(features)))

    def test_a_report_with_each_feature_of_both_runners_passes(self):
        status, output = self.check("# Both targets.\nCheckout with XCTest\n\nCukes\n",
                                    [feature("Checkout with XCTest", 2), feature("Cukes", 3)])
        self.assertEqual(status, 0, output)
        self.assertIn("the 2 features it lists", output)

    def test_a_report_that_lost_a_runners_features_fails(self):
        status, output = self.check("Checkout with XCTest\nCukes\n", [feature("Cukes")])
        self.assertEqual(status, 1)
        self.assertIn("no feature 'Checkout with XCTest'", output)

    def test_a_feature_an_earlier_run_left_fails(self):
        status, output = self.check("Checkout with XCTest\n", [feature("Checkout with XCTest"), feature("Cukes")])
        self.assertEqual(status, 1)
        self.assertIn("a feature it shouldn't: 'Cukes'", output)

    def test_a_feature_without_scenarios_fails(self):
        status, output = self.check("Cukes\n", [feature("Cukes", 0)])
        self.assertEqual(status, 1)
        self.assertIn("has no scenarios", output)

    def test_a_missing_or_broken_report_fails(self):
        expected = self.write("expected-report", "Cukes\n")
        status, output = self.run_main("check", expected, os.path.join(self.folder, "missing.json"))
        self.assertEqual(status, 1)
        self.assertIn("can't read the report", output)
        status, output = self.run_main("check", expected, self.write("report.json", "{\"not\": \"a list\"}"))
        self.assertEqual(status, 1)
        self.assertIn("isn't a list of features", output)

    def test_the_rerun_file_gives_its_settings_and_its_features(self):
        path = self.write("expected-report-rerun", "# The rerun.\ntags: checkout\nonly-testing: Unit\nCheckout with XCTest\n")
        self.assertEqual(self.run_main("get", path, "tags"), (0, "checkout\n"))
        self.assertEqual(self.run_main("get", path, "only-testing"), (0, "Unit\n"))
        status, output = self.run_main("check", path, self.write("report.json", json.dumps([feature("Checkout with XCTest")])))
        self.assertEqual(status, 0, output)
        self.assertIn("the 1 feature it lists", output)

    def test_a_report_the_fixture_should_have_aged_needs_its_marker(self):
        expected = self.write("expected-report", "ages-report: .aged\nCukes\n")
        report = self.write("report.json", json.dumps([feature("Cukes")]))
        status, output = self.run_main("check", expected, report)
        self.assertEqual(status, 1)
        self.assertIn("didn't age the report", output)
        self.write("report.json.aged", "")
        status, output = self.run_main("check", expected, report)
        self.assertEqual(status, 0, output)

    def test_a_setting_a_file_does_not_have_is_an_error(self):
        status, output = self.run_main("get", self.write("expected-report", "Cukes\n"), "tags")
        self.assertEqual(status, 1)
        self.assertIn("no `tags:` setting", output)

    def test_a_file_without_features_or_a_setting_value_is_an_error(self):
        with self.assertRaises(ValueError):
            fixture_report.expectation(self.write("empty", "# Nothing.\n"))
        with self.assertRaises(ValueError):
            fixture_report.expectation(self.write("only-settings", "tags: x\n"))
        with self.assertRaises(ValueError):
            fixture_report.expectation(self.write("no-value", "tags:\nCukes\n"))


if __name__ == "__main__":
    unittest.main()
