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
from contextlib import redirect_stderr, redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fixture_report  # noqa: E402


def feature(name, scenarios=1):
    return {"name": name, "uri": f"{name}.feature", "elements": [{"name": f"S{i}"} for i in range(scenarios)]}


class FixtureReportTests(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.root)
        os.makedirs(os.path.join(self.root, "Demo"))

    def write(self, kind, text):
        with open(os.path.join(self.root, "Demo", kind), "w", encoding="utf-8") as file:
            file.write(text)

    def run_main(self, *args, report=None):
        output = io.StringIO()
        with redirect_stdout(output):
            status = fixture_report.run(["fixture_report.py", *args], io.StringIO(report or ""), self.root)
        return status, output.getvalue()

    def run_main_with_errors(self, *args):
        """The status, the standard output and the standard error."""
        errors = io.StringIO()
        with redirect_stderr(errors):
            status, output = self.run_main(*args)
        return status, output, errors.getvalue()

    def check(self, expected, features, kind="expected-report"):
        self.write(kind, expected)
        return self.run_main("check", "Demo", kind, report=json.dumps(features))

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

    def test_a_report_that_is_not_a_list_of_features_or_not_json_fails(self):
        self.write("expected-report", "Cukes\n")
        status, output = self.run_main("check", "Demo", "expected-report", report='{"not": "a list"}')
        self.assertEqual(status, 1)
        self.assertIn("isn't a list of features", output)
        status, output = self.run_main("check", "Demo", "expected-report", report="")
        self.assertEqual(status, 1)
        self.assertIn("can't read the report", output)

    def test_the_rerun_file_gives_its_settings_and_its_features(self):
        self.write("expected-report-rerun", "# The rerun.\ntags: checkout\nonly-testing: Unit\nCheckout with XCTest\n")
        self.assertEqual(self.run_main("get", "Demo", "expected-report-rerun", "tags"), (0, "checkout\n"))
        self.assertEqual(self.run_main("get", "Demo", "expected-report-rerun", "only-testing"), (0, "Unit\n"))
        status, output = self.run_main("check", "Demo", "expected-report-rerun", report=json.dumps([feature("Checkout with XCTest")]))
        self.assertEqual(status, 0, output)
        self.assertIn("the 1 feature it lists", output)

    def test_a_fixture_that_ages_its_report_gives_the_marker_suffix(self):
        self.write("expected-report", "ages-report: .aged\nCukes\n")
        self.assertEqual(self.run_main("get", "Demo", "expected-report", "ages-report"), (0, ".aged\n"))

    def test_a_setting_a_file_does_not_have_is_an_error(self):
        self.write("expected-report", "Cukes\n")
        status, output, errors = self.run_main_with_errors("get", "Demo", "expected-report", "tags")
        self.assertEqual(status, 1)
        self.assertEqual(output, "")
        self.assertIn("no `tags:` setting", errors)

    def test_a_file_without_features_or_a_setting_value_is_an_error(self):
        for text in ("# Nothing.\n", "tags: x\n", "tags:\nCukes\n"):
            self.write("expected-report", text)
            path = fixture_report.expected_file("Demo", "expected-report", self.root)
            with self.assertRaises(ValueError):
                fixture_report.expectation(path)

    def test_only_a_fixture_in_the_folder_and_an_expected_file_are_found(self):
        self.write("expected-report", "Cukes\n")
        self.assertTrue(fixture_report.expected_file("Demo", "expected-report", self.root).endswith("Demo/expected-report"))
        for fixture, kind in (("Missing", "expected-report"), ("Demo", "report.json"), ("../Demo", "expected-report")):
            with self.assertRaises(ValueError):
                fixture_report.expected_file(fixture, kind, self.root)


if __name__ == "__main__":
    unittest.main()
