"""Unit tests for queue_checked.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The GitHub API is replaced by a fake, so the tests need no network access or
token. Only the standard library is used.
"""
import io
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import queue_checked  # noqa: E402

SHA = "6e88c33aaf89c11754c26881b4f2c815aa24a007"
OTHER_SHA = "e2b2501b" + "0" * 32
PUSH_TO_MAIN = {
    "GITHUB_EVENT_NAME": "push",
    "GITHUB_REF": "refs/heads/main",
    "GITHUB_SHA": SHA,
    "GITHUB_REPOSITORY": "cucumberswift/CucumberSwift",
    "GITHUB_WORKFLOW_REF": "cucumberswift/CucumberSwift/.github/workflows/CI.yml@refs/heads/main",
}


def run(head_sha=SHA, event="merge_group", conclusion="success", run_id=37933711065, status=None):
    return {"id": run_id, "head_sha": head_sha, "event": event, "conclusion": conclusion,
            "status": status or ("completed" if conclusion else "in_progress")}


class FakeApi:
    """Answers every call with one response, and records the paths asked for."""

    def __init__(self, response=None, error=None):
        self.response = response
        self.error = error
        self.paths = []

    def __call__(self, path):
        self.paths.append(path)
        if self.error:
            raise queue_checked.QueueLookupError(self.error)
        return self.response


def decide(environ, api):
    with redirect_stdout(io.StringIO()) as output:
        result = queue_checked.decide(environ, api)
    return result, output.getvalue()


class WorkflowFileTests(unittest.TestCase):
    def test_the_file_name_comes_from_the_workflow_ref(self):
        self.assertEqual(queue_checked.workflow_file(PUSH_TO_MAIN["GITHUB_WORKFLOW_REF"]), "CI.yml")

    def test_a_ref_that_names_no_workflow_file_is_an_error(self):
        for ref in ["", "CI.yml", "cucumberswift/CucumberSwift/CI.yml@refs/heads/main",
                    "cucumberswift/CucumberSwift/.github/workflows/../CI.yml@refs/heads/main"]:
            with self.subTest(ref=ref), self.assertRaises(queue_checked.QueueLookupError):
                queue_checked.workflow_file(ref)


class QueueCheckedTests(unittest.TestCase):
    def test_a_commit_that_passed_the_queue_is_checked(self):
        api = FakeApi({"workflow_runs": [run()]})
        result, output = decide(PUSH_TO_MAIN, api)
        self.assertTrue(result)
        self.assertIn("37933711065", output)
        self.assertEqual(api.paths, [
            f"repos/cucumberswift/CucumberSwift/actions/workflows/CI.yml/runs"
            f"?head_sha={SHA}&event=merge_group&per_page=100"
        ])

    def test_a_commit_with_no_queue_run_is_not_checked(self):
        result, output = decide(PUSH_TO_MAIN, FakeApi({"total_count": 0, "workflow_runs": []}))
        self.assertFalse(result)
        self.assertIn("the full CI runs", output)

    def test_runs_that_do_not_match_the_query_are_ignored(self):
        for other in [run(head_sha=OTHER_SHA), run(event="push"), run(event="pull_request"),
                      run(conclusion="failure"), run(conclusion="cancelled"),
                      run(conclusion="timed_out"), run(conclusion="skipped"), "not a run"]:
            with self.subTest(run=other):
                result, _ = decide(PUSH_TO_MAIN, FakeApi({"workflow_runs": [other]}))
                self.assertFalse(result)

    def test_a_queue_run_still_going_counts(self):
        for status in ["queued", "in_progress", "waiting", "pending", "requested"]:
            with self.subTest(status=status):
                result, _ = decide(PUSH_TO_MAIN, FakeApi({"workflow_runs": [run(conclusion=None, status=status)]}))
                self.assertTrue(result)

    def test_a_completed_run_with_no_conclusion_does_not_count(self):
        result, _ = decide(PUSH_TO_MAIN, FakeApi({"workflow_runs": [run(conclusion=None, status="completed")]}))
        self.assertFalse(result)

    def test_one_passing_run_among_others_is_enough(self):
        api = FakeApi({"workflow_runs": [run(conclusion="failure", run_id=1), run(run_id=2)]})
        result, output = decide(PUSH_TO_MAIN, api)
        self.assertTrue(result)
        self.assertIn("run 2 ", output)


class NotAPushToMainTests(unittest.TestCase):
    def test_other_events_and_branches_never_look_anything_up(self):
        for changes in [
            {"GITHUB_EVENT_NAME": "pull_request", "GITHUB_REF": "refs/pull/380/merge"},
            {"GITHUB_EVENT_NAME": "merge_group", "GITHUB_REF": "refs/heads/gh-readonly-queue/main/pr-380-x"},
            {"GITHUB_EVENT_NAME": "schedule"},
            {"GITHUB_EVENT_NAME": "workflow_dispatch"},
            {"GITHUB_REF": "refs/heads/support/5.x"},
            {"GITHUB_REF": "refs/tags/6.4.0"},
            {"GITHUB_EVENT_NAME": ""},
        ]:
            with self.subTest(changes=changes):
                api = FakeApi({"workflow_runs": [run()]})
                result, _ = decide({**PUSH_TO_MAIN, **changes}, api)
                self.assertFalse(result)
                self.assertEqual(api.paths, [])


class ErrorTests(unittest.TestCase):
    def test_bad_inputs_run_everything_with_a_warning(self):
        for changes in [
            {"GITHUB_SHA": "6e88c33a"},
            {"GITHUB_SHA": SHA + "&event=push"},
            {"GITHUB_REPOSITORY": "cucumberswift"},
            {"GITHUB_REPOSITORY": "cucumberswift/CucumberSwift/actions"},
            {"GITHUB_WORKFLOW_REF": ""},
        ]:
            with self.subTest(changes=changes):
                api = FakeApi({"workflow_runs": [run()]})
                result, output = decide({**PUSH_TO_MAIN, **changes}, api)
                self.assertFalse(result)
                self.assertIn("::warning::Running the full CI", output)
                self.assertEqual(api.paths, [])

    def test_an_api_failure_runs_everything_with_a_warning(self):
        result, output = decide(PUSH_TO_MAIN, FakeApi(error="HTTP 403"))
        self.assertFalse(result)
        self.assertIn("::warning::Running the full CI", output)
        self.assertIn("HTTP 403", output)

    def test_an_unexpected_response_runs_everything(self):
        for response in [None, [], {}, {"workflow_runs": None}, {"workflow_runs": "x"}]:
            with self.subTest(response=response):
                result, output = decide(PUSH_TO_MAIN, FakeApi(response))
                self.assertFalse(result)
                self.assertIn("::warning::", output)

    def test_gh_failing_or_printing_no_json_is_a_lookup_error(self):
        failed = mock.Mock(returncode=1, stdout="", stderr="gh: Not Found (HTTP 404)")
        garbage = mock.Mock(returncode=0, stdout="not json", stderr="")
        for completed in [failed, garbage]:
            with self.subTest(stdout=completed.stdout), \
                    mock.patch.object(queue_checked.subprocess, "run", return_value=completed), \
                    self.assertRaises(queue_checked.QueueLookupError):
                queue_checked.gh_api("repos/x/y")


class MainTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.output = os.path.join(directory.name, "output")

    def main(self, environ, checked):
        with mock.patch.dict(os.environ, environ, clear=True), \
                mock.patch.object(queue_checked, "decide", return_value=checked), \
                redirect_stdout(io.StringIO()):
            return queue_checked.main()

    def test_writes_true_when_checked_and_false_otherwise(self):
        for checked, written in [(True, "queue_checked=true\n"), (False, "queue_checked=false\n")]:
            with self.subTest(checked=checked):
                if os.path.exists(self.output):
                    os.remove(self.output)
                self.assertEqual(self.main({"GITHUB_OUTPUT": self.output}, checked), 0)
                with open(self.output, encoding="utf-8") as handle:
                    self.assertEqual(handle.read(), written)

    def test_no_output_file_fails(self):
        self.assertEqual(self.main({}, True), 1)


if __name__ == "__main__":
    unittest.main()
