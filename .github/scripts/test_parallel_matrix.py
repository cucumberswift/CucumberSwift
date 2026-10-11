"""Unit tests for parallel_matrix.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

Only the standard library is used.
"""
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parallel_matrix  # noqa: E402


def names(matrix):
    return {(c["xcode"], c["platform"], c["kind"]) for c in matrix}


def every(xcodes=("16", "26"), platforms=("iOS", "tvOS", "macOS", "Catalyst"),
          kinds=("hostless", "hosted", "UI")):
    return {(x, p, k) for x in xcodes for p in platforms for k in kinds}


SMOKE = ("26", "macOS", "hostless")


class EventTests(unittest.TestCase):
    """Without inputs, each event runs what CI.yml ran before the inputs existed."""

    def test_a_pull_request_runs_the_hosted_tests_on_each_platform_with_xcode_26(self):
        matrix, smoke = parallel_matrix.build("pull_request")
        self.assertEqual(names(matrix), every(xcodes=("26",), kinds=("hosted",)))
        self.assertTrue(smoke)

    def test_a_push_leaves_out_xcode_16s_tvos_and_macos(self):
        matrix, smoke = parallel_matrix.build("push")
        expected = (every(xcodes=("26",)) | every(xcodes=("16",), platforms=("iOS", "Catalyst"))) - {SMOKE}
        self.assertEqual(names(matrix), expected)
        self.assertEqual(len(matrix), 17)
        self.assertTrue(smoke)

    def test_nightly_and_manual_runs_run_every_combination(self):
        for event in ["schedule", "workflow_dispatch"]:
            with self.subTest(event=event):
                matrix, smoke = parallel_matrix.build(event)
                self.assertEqual(names(matrix), every() - {SMOKE})
                self.assertEqual(len(matrix), 23)
                self.assertTrue(smoke)

    def test_the_smoke_combination_is_never_in_the_matrix(self):
        for event in ["pull_request", "push", "schedule", "workflow_dispatch"]:
            with self.subTest(event=event):
                self.assertNotIn(SMOKE, names(parallel_matrix.build(event)[0]))

    def test_all_and_empty_inputs_run_everything(self):
        full = parallel_matrix.build("workflow_dispatch")
        for value in ["all", "ALL", " all ", ""]:
            with self.subTest(value=value):
                self.assertEqual(parallel_matrix.build("workflow_dispatch", value, value, value), full)

    def test_inputs_are_ignored_on_other_events(self):
        for event in ["pull_request", "push", "schedule"]:
            with self.subTest(event=event):
                self.assertEqual(parallel_matrix.build(event, "nope", "nope", "nope"),
                                 parallel_matrix.build(event))


class InputTests(unittest.TestCase):
    def test_narrows_to_the_ui_tests_on_macos_and_catalyst(self):
        matrix, smoke = parallel_matrix.build("workflow_dispatch", "macOS,Catalyst", "UI")
        self.assertEqual(names(matrix), every(platforms=("macOS", "Catalyst"), kinds=("UI",)))
        self.assertFalse(smoke)

    def test_names_match_in_any_case_with_spaces(self):
        matrix, _ = parallel_matrix.build("workflow_dispatch", " macos , CATALYST", "ui,Hosted ", "26")
        self.assertEqual(names(matrix), every(xcodes=("26",), platforms=("macOS", "Catalyst"),
                                              kinds=("UI", "hosted")))

    def test_the_smoke_job_runs_when_the_inputs_include_it(self):
        matrix, smoke = parallel_matrix.build("workflow_dispatch", "macOS", "hostless")
        self.assertTrue(smoke)
        self.assertEqual(names(matrix), {("16", "macOS", "hostless")})

    def test_only_the_smoke_combination_leaves_the_matrix_empty(self):
        matrix, smoke = parallel_matrix.build("workflow_dispatch", "macOS", "hostless", "26")
        self.assertEqual(matrix, [])
        self.assertTrue(smoke)

    def test_one_xcode(self):
        matrix, smoke = parallel_matrix.build("workflow_dispatch", xcode="16")
        self.assertEqual(names(matrix), every(xcodes=("16",)))
        self.assertFalse(smoke)

    def test_matrix_entries_keep_the_check_names_values_in_order(self):
        matrix, _ = parallel_matrix.build("workflow_dispatch", "Catalyst,iOS", "UI,hostless", "all")
        self.assertEqual(matrix[0], {"xcode": "16", "platform": "iOS", "kind": "hostless"})
        self.assertEqual([(c["platform"], c["kind"]) for c in matrix[:4]],
                         [("iOS", "hostless"), ("iOS", "UI"), ("Catalyst", "hostless"), ("Catalyst", "UI")])

    def test_unknown_names_are_errors(self):
        for platforms, kinds, xcode, named in [
            ("macOS,Linux", "", "", "'Linux'"),
            ("Mac Catalyst", "", "", "'Mac Catalyst'"),
            ("macOS,", "", "", "''"),
            ("", "unit", "", "'unit'"),
            ("", "", "15", "'15'"),
        ]:
            with self.subTest(platforms=platforms, kinds=kinds, xcode=xcode), \
                    self.assertRaisesRegex(parallel_matrix.InputError, named):
                parallel_matrix.build("workflow_dispatch", platforms, kinds, xcode)

    def test_the_error_lists_the_allowed_names(self):
        with self.assertRaisesRegex(parallel_matrix.InputError,
                                    r"parallel_kinds .* not one of: all, hostless, hosted, UI\."):
            parallel_matrix.build("workflow_dispatch", kinds="unit")


class MainTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.output = os.path.join(directory.name, "output")

    def main(self, environ):
        with mock.patch.dict(os.environ, environ, clear=True), \
                redirect_stdout(io.StringIO()) as printed:
            status = parallel_matrix.main()
        return status, printed.getvalue()

    def written(self):
        with open(self.output, encoding="utf-8") as handle:
            return dict(line.split("=", 1) for line in handle.read().splitlines())

    def test_writes_the_matrix_as_json_and_the_smoke_decision(self):
        status, _ = self.main({"GITHUB_OUTPUT": self.output, "GITHUB_EVENT_NAME": "workflow_dispatch",
                               "PARALLEL_PLATFORMS": "macOS,Catalyst", "PARALLEL_KINDS": "UI"})
        self.assertEqual(status, 0)
        output = self.written()
        self.assertEqual(names(json.loads(output["parallel_matrix"])),
                         every(platforms=("macOS", "Catalyst"), kinds=("UI",)))
        self.assertEqual(output["parallel_smoke"], "false")

    def test_an_empty_matrix_is_an_empty_list(self):
        status, _ = self.main({"GITHUB_OUTPUT": self.output, "GITHUB_EVENT_NAME": "workflow_dispatch",
                               "PARALLEL_PLATFORMS": "macOS", "PARALLEL_KINDS": "hostless",
                               "PARALLEL_XCODE": "26"})
        self.assertEqual(status, 0)
        self.assertEqual(self.written(), {"parallel_matrix": "[]", "parallel_smoke": "true"})

    def test_an_unknown_name_fails_with_an_error_and_writes_nothing(self):
        status, printed = self.main({"GITHUB_OUTPUT": self.output, "GITHUB_EVENT_NAME": "workflow_dispatch",
                                     "PARALLEL_PLATFORMS": "visionOS"})
        self.assertEqual(status, 1)
        self.assertIn("::error::parallel_platforms has 'visionOS'", printed)
        self.assertFalse(os.path.exists(self.output))

    def test_no_output_file_fails(self):
        self.assertEqual(self.main({"GITHUB_EVENT_NAME": "push"})[0], 1)


if __name__ == "__main__":
    unittest.main()
