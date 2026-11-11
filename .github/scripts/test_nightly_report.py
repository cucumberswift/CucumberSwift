"""Unit tests for nightly_report.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

`gh` is replaced by a fake, so the tests need no network access or token. Only
the standard library is used.
"""
import json
import os
import re
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nightly_report  # noqa: E402

REPO = "cucumberswift/CucumberSwift"
RUN_URL = "https://github.com/cucumberswift/CucumberSwift/actions/runs/42"
ENVIRON = {
    "GITHUB_REPOSITORY": REPO,
    "GITHUB_RUN_ID": "42",
    "GITHUB_RUN_ATTEMPT": "1",
    "GITHUB_SERVER_URL": "https://github.com",
}
WORKFLOW = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "workflows", "CI.yml")


def job(name, conclusion, status="completed"):
    return {"name": name, "status": status, "conclusion": conclusion}


def issue(number, title=nightly_report.TITLE, author=nightly_report.AUTHOR, pull_request=None):
    return {"number": number, "title": title, "pull_request": pull_request, "author": author}


class FakeGh:
    """Answers the API calls from lists, as `--jq` prints them, and records every call."""

    def __init__(self, jobs, issues):
        self.jobs = jobs
        self.issues = issues
        self.calls = []

    def __call__(self, args, stdin=None):
        self.calls.append((args, stdin))
        if args[0] == "api" and "/jobs" in args[2]:
            return "".join(json.dumps(j) + "\n" for j in self.jobs)
        if args[0] == "api" and "/issues?" in args[2]:
            return "".join(json.dumps(i) + "\n" for i in self.issues)
        if args[:2] == ["issue", "create"]:
            return "https://github.com/cucumberswift/CucumberSwift/issues/700\n"
        if args[:2] == ["issue", "comment"]:
            return ""
        raise AssertionError(f"unexpected gh call: {args}")

    def writes(self):
        return [(args, stdin) for args, stdin in self.calls if args[0] == "issue"]


class ReportTests(unittest.TestCase):
    def test_a_failure_with_no_open_issue_opens_one_naming_each_failing_job(self):
        gh = FakeGh([job("Changed files", "success"), job("iOS tests", "failure"),
                     job("Bazel tests (oldest Bazel)", "timed_out"), job("Docs", "skipped"),
                     job("Report the nightly run", None, status="in_progress")], [])
        self.assertEqual(nightly_report.report(ENVIRON, gh),
                         "2 job(s) failed; opened https://github.com/cucumberswift/CucumberSwift/issues/700")
        [(args, body)] = gh.writes()
        self.assertEqual(args, ["issue", "create", "--repo", REPO, "--title", "Nightly CI run failed",
                                "--body-file", "-"])
        self.assertEqual(body, f"The nightly CI run failed: {RUN_URL}\n\nThese jobs failed:\n\n"
                               "- iOS tests\n- Bazel tests (oldest Bazel)\n")

    def test_a_failure_with_an_open_issue_comments_on_it_instead(self):
        gh = FakeGh([job("SwiftPM tests", "cancelled")], [issue(650)])
        self.assertEqual(nightly_report.report(ENVIRON, gh), "1 job(s) failed; commented on #650")
        [(args, body)] = gh.writes()
        self.assertEqual(args, ["issue", "comment", "650", "--repo", REPO, "--body-file", "-"])
        self.assertIn("- SwiftPM tests\n", body)
        self.assertIn(RUN_URL, body)

    def test_a_pass_with_an_open_issue_comments_that_it_can_be_closed(self):
        gh = FakeGh([job("iOS tests", "success"), job("Docs", "skipped")], [issue(650)])
        self.assertEqual(nightly_report.report(ENVIRON, gh), "Every job passed; commented on #650")
        [(args, body)] = gh.writes()
        self.assertEqual(args, ["issue", "comment", "650", "--repo", REPO, "--body-file", "-"])
        self.assertEqual(body, f"A later nightly CI run passed: {RUN_URL}\n\nA maintainer can close this issue.\n")

    def test_a_pass_with_no_open_issue_writes_nothing(self):
        gh = FakeGh([job("iOS tests", "success")], [])
        self.assertEqual(nightly_report.report(ENVIRON, gh), "Every job passed, and no issue is open.")
        self.assertEqual(gh.writes(), [])

    def test_it_never_closes_or_edits_an_issue(self):
        for jobs in ([job("iOS tests", "failure")], [job("iOS tests", "success")]):
            gh = FakeGh(jobs, [issue(650)])
            nightly_report.report(ENVIRON, gh)
            for args, _ in gh.writes():
                self.assertIn(args[1], {"create", "comment"})

    def test_only_an_open_issue_actions_opened_with_the_exact_title_counts(self):
        gh = FakeGh([job("iOS tests", "failure")], [
            issue(600, author="someone"),
            issue(601, title="Nightly CI run failed again"),
            issue(602, pull_request={"url": "x"}),
        ])
        self.assertTrue(nightly_report.report(ENVIRON, gh).endswith("opened https://github.com/"
                                                                    "cucumberswift/CucumberSwift/issues/700"))

    def test_the_oldest_of_several_open_issues_gets_the_comment(self):
        gh = FakeGh([job("iOS tests", "failure")], [issue(660), issue(650)])
        self.assertEqual(nightly_report.report(ENVIRON, gh), "1 job(s) failed; commented on #650")

    def test_the_title_can_be_changed_to_try_it_out(self):
        gh = FakeGh([job("iOS tests", "failure")], [issue(650)])
        nightly_report.report({**ENVIRON, "NIGHTLY_ISSUE_TITLE": "Try-out"}, gh)
        [(args, _)] = gh.writes()
        self.assertEqual(args[:2], ["issue", "create"])
        self.assertEqual(args[args.index("--title") + 1], "Try-out")

    def test_a_rerun_links_its_attempt_and_lists_its_jobs(self):
        gh = FakeGh([job("iOS tests", "failure")], [])
        nightly_report.report({**ENVIRON, "GITHUB_RUN_ATTEMPT": "2"}, gh)
        self.assertIn("actions/runs/42/attempts/2/jobs", gh.calls[0][0][2])
        self.assertIn(f"{RUN_URL}/attempts/2\n", gh.writes()[0][1])

    def test_a_job_name_reaches_gh_only_on_standard_input(self):
        name = 'Evil $(touch /tmp/x) `id` "; rm -rf ~'
        gh = FakeGh([job(name, "failure")], [])
        nightly_report.report(ENVIRON, gh)
        [(args, body)] = gh.writes()
        self.assertNotIn(name, " ".join(args))
        self.assertIn(f"- {name}\n", body)

    def test_a_failing_gh_call_fails_the_script(self):
        def broken(args, stdin=None):
            raise RuntimeError("gh api failed: HTTP 403")
        with self.assertRaises(RuntimeError):
            nightly_report.report(ENVIRON, broken)


class WorkflowTests(unittest.TestCase):
    """CI.yml's nightly_report job must wait for every other job, or it reports too early."""

    def setUp(self):
        with open(WORKFLOW, encoding="utf-8") as file:
            self.text = file.read()
        jobs = self.text[self.text.index("\njobs:\n"):]
        self.job_ids = re.findall(r"^  ([A-Za-z0-9_-]+):\s*$", jobs, flags=re.MULTILINE)
        start = jobs.index("\n  nightly_report:\n")
        following = re.search(r"^  [A-Za-z0-9_-]+:\s*$", jobs[start + 2:], flags=re.MULTILINE)
        self.job = jobs[start:start + 2 + following.start()] if following else jobs[start:]

    def test_it_needs_every_other_job(self):
        needs = re.search(r"^    needs: \[([^\]]*)\]", self.job, flags=re.MULTILINE)
        self.assertIsNotNone(needs, "nightly_report needs a one-line `needs: [...]` list")
        listed = {name.strip() for name in needs.group(1).split(",")}
        self.assertEqual(listed, set(self.job_ids) - {"nightly_report"})

    def test_it_runs_only_on_the_schedule_and_can_write_only_issues(self):
        self.assertIn("github.event_name == 'schedule'", self.job)
        permissions = re.search(r"^    permissions:\n((?:      .*\n)+)", self.job, flags=re.MULTILINE)
        self.assertEqual(sorted(permissions.group(1).split()),
                         sorted(["actions:", "read", "contents:", "read", "issues:", "write"]))


if __name__ == "__main__":
    unittest.main()
