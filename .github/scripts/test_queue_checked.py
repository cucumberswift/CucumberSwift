"""Unit tests for queue_checked.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The GitHub API is replaced by a fake, so the tests need no network access or
token. Only the standard library is used.
"""
import base64
import io
import os
import re
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import queue_checked  # noqa: E402
import release  # noqa: E402

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


PARENT_SHA = "de265cf6" + "1" * 32
GRANDPARENT_SHA = "7a8b6c73" + "2" * 32
REPO = "repos/cucumberswift/CucumberSwift"
SCRIPTS = os.path.dirname(os.path.abspath(__file__))
RELEASE_YML = os.path.join(SCRIPTS, "..", "workflows", "release.yml")


def plist(version, extra=""):
    return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<plist version=\"1.0\">\n<dict>\n"
            f"\t<key>CFBundleName</key>\n\t<string>CucumberSwift{extra}</string>\n"
            f"\t<key>CFBundleShortVersionString</key>\n\t<string>{version}</string>\n"
            f"\t<key>CFBundleVersion</key>\n\t<string>{version}</string>\n</dict>\n</plist>\n")


def contents(text):
    return {"encoding": "base64", "content": base64.b64encode(text.encode("utf-8")).decode()}


def version_commit(sha=SHA, parent=PARENT_SHA, version="6.4.1", message=None,
                   login=queue_checked.RELEASE_BOT, name=queue_checked.RELEASE_BOT,
                   files=(queue_checked.VERSION_FILE,)):
    """A commit as GET repos/{repo}/commits/{sha} returns it, trimmed to what is read."""
    return {
        "sha": sha,
        "commit": {"message": release.VERSION_MESSAGE.format(version) if message is None else message,
                   "author": {"name": name}},
        "author": {"login": login, "type": "Bot"},
        "parents": [{"sha": parent}],
        "files": [{"filename": f, "status": "modified"} for f in files],
    }


class RoutedApi:
    """Answers each path from a dict. A path it does not know has no runs, is a
    commit that is not a version commit, or is a file that does not exist.
    Records the paths asked for."""

    def __init__(self, responses):
        self.responses = responses
        self.paths = []

    def __call__(self, path):
        self.paths.append(path)
        if path in self.responses:
            return self.responses[path]
        if "/actions/workflows/" in path:
            return {"workflow_runs": []}
        if "/commits/" in path:
            return {"commit": {"message": "fix: something (#1)"}}
        raise queue_checked.QueueLookupError(f"HTTP 404 for {path}")


def runs_path(sha):
    return f"{REPO}/actions/workflows/CI.yml/runs?head_sha={sha}&event=merge_group&per_page=100"


def release_push(commit=None, before="6.4.0", after="6.4.1", parent_runs=None, extra_routes=None):
    """The API as a release's push to main sees it: a version commit on PARENT_SHA,
    which a merge queue run passed unless parent_runs says otherwise."""
    routes = {
        f"{REPO}/commits/{SHA}": commit or version_commit(),
        f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={PARENT_SHA}": contents(plist(before)),
        f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={SHA}": contents(plist(after)),
        runs_path(PARENT_SHA): {"workflow_runs": [run(head_sha=PARENT_SHA)] if parent_runs is None else parent_runs},
    }
    routes.update(extra_routes or {})
    return RoutedApi(routes)


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


class VersionCommitTests(unittest.TestCase):
    def test_a_release_version_commit_on_a_checked_parent_skips_everything(self):
        api = release_push()
        result, output = decide(PUSH_TO_MAIN, api)
        self.assertEqual(result, queue_checked.VERSION)
        self.assertIn(f"version commit on {PARENT_SHA}", output)
        self.assertIn("Nothing runs", output)
        self.assertEqual(api.paths[0], runs_path(SHA))
        self.assertEqual(api.paths[-1], runs_path(PARENT_SHA))

    def test_a_version_commit_that_changes_another_file_runs_everything(self):
        api = release_push(version_commit(files=(queue_checked.VERSION_FILE, "Sources/CucumberSwift/Runner/Cucumber.swift")))
        result, output = decide(PUSH_TO_MAIN, api)
        self.assertFalse(result)
        self.assertIn(f"it changes more than {queue_checked.VERSION_FILE}", output)
        self.assertNotIn(runs_path(PARENT_SHA), api.paths)

    def test_a_version_commit_that_changes_only_another_file_runs_everything(self):
        result, _ = decide(PUSH_TO_MAIN, release_push(version_commit(files=("Package.swift",))))
        self.assertFalse(result)

    def test_a_version_commit_that_changes_more_than_the_version_keys_runs_everything(self):
        for before, after in [(plist("6.4.0"), plist("6.4.1", extra="X")),
                              (plist("6.4.0"), plist("6.4.2")),
                              (plist("6.4.0").replace("<key>CFBundleVersion</key>\n\t<string>6.4.0</string>\n", ""),
                               plist("6.4.1").replace("<key>CFBundleVersion</key>\n\t<string>6.4.1</string>\n", ""))]:
            with self.subTest(after=after):
                result, output = decide(PUSH_TO_MAIN, release_push(extra_routes=self.files(before, after)))
                self.assertFalse(result)
                self.assertIn("more than the version keys", output)

    @staticmethod
    def files(before, after):
        return {f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={PARENT_SHA}": contents(before),
                f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={SHA}": contents(after)}

    def test_a_version_like_message_from_someone_else_runs_everything(self):
        for commit in [version_commit(login="ianhlavats", name="Ian Hlavats"),
                       version_commit(login="ianhlavats"),
                       version_commit(name="Ian Hlavats"),
                       version_commit(login="github-actions[bot]", name="github-actions[bot]")]:
            with self.subTest(commit=commit["author"]):
                api = release_push(commit)
                result, output = decide(PUSH_TO_MAIN, api)
                self.assertFalse(result)
                self.assertIn(f"its author is not {queue_checked.RELEASE_BOT}", output)
                self.assertNotIn(runs_path(PARENT_SHA), api.paths)

    def test_a_commit_with_no_author_on_github_runs_everything(self):
        commit = version_commit()
        commit["author"] = None
        result, _ = decide(PUSH_TO_MAIN, release_push(commit))
        self.assertFalse(result)

    def test_other_messages_are_not_version_commits(self):
        for message in ["fix: something (#1)", "chore: set version 6.4", "chore: set version 6.4.1 and more",
                        "[ci skip] Apply automatic changes", "Revert \"chore: set version 6.4.1\""]:
            with self.subTest(message=message):
                result, _ = decide(PUSH_TO_MAIN, release_push(version_commit(message=message)))
                self.assertFalse(result)

    def test_the_version_in_the_message_must_be_the_one_set(self):
        result, _ = decide(PUSH_TO_MAIN, release_push(version_commit(version="6.5.0")))
        self.assertFalse(result)

    def test_a_merge_commit_runs_everything(self):
        commit = version_commit()
        commit["parents"].append({"sha": GRANDPARENT_SHA})
        result, output = decide(PUSH_TO_MAIN, release_push(commit))
        self.assertFalse(result)
        self.assertIn("exactly one parent", output)

    def test_a_parent_that_was_not_checked_runs_everything(self):
        for runs in [[], [run(head_sha=PARENT_SHA, conclusion="failure")],
                     [run(head_sha=PARENT_SHA, conclusion="cancelled")]]:
            with self.subTest(runs=runs):
                result, output = decide(PUSH_TO_MAIN, release_push(parent_runs=runs))
                self.assertFalse(result)
                self.assertIn("the full CI runs", output)

    def test_a_parent_whose_queue_run_is_still_going_counts(self):
        result, _ = decide(PUSH_TO_MAIN, release_push(parent_runs=[run(head_sha=PARENT_SHA, conclusion=None)]))
        self.assertEqual(result, queue_checked.VERSION)

    def test_a_version_commit_on_a_checked_version_commit_counts(self):
        api = release_push(parent_runs=[], extra_routes={
            f"{REPO}/commits/{PARENT_SHA}": version_commit(sha=PARENT_SHA, parent=GRANDPARENT_SHA, version="6.4.0"),
            f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={GRANDPARENT_SHA}": contents(plist("6.3.0")),
            runs_path(GRANDPARENT_SHA): {"workflow_runs": [run(head_sha=GRANDPARENT_SHA)]},
        })
        result, _ = decide(PUSH_TO_MAIN, api)
        self.assertEqual(result, queue_checked.VERSION)

    def test_a_chain_of_version_commits_stops_at_the_limit(self):
        shas = [SHA] + [f"{i:040x}" for i in range(1, queue_checked.MAX_VERSION_COMMITS + 2)]
        routes = {}
        for i, (sha, parent) in enumerate(zip(shas, shas[1:])):
            routes[f"{REPO}/commits/{sha}"] = version_commit(sha=sha, parent=parent, version=f"6.{9 - i}.0")
            routes[f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={sha}"] = contents(plist(f"6.{9 - i}.0"))
        routes[f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={shas[-1]}"] = contents(plist(f"6.{9 - len(shas) + 1}.0"))
        routes[runs_path(shas[-1])] = {"workflow_runs": [run(head_sha=shas[-1])]}
        api = RoutedApi(routes)
        result, _ = decide(PUSH_TO_MAIN, api)
        self.assertFalse(result)
        self.assertNotIn(runs_path(shas[-1]), api.paths)

    def test_a_lookup_failure_runs_everything_with_a_warning(self):
        api = release_push()
        del api.responses[f"{REPO}/contents/{queue_checked.VERSION_FILE}?ref={SHA}"]
        result, output = decide(PUSH_TO_MAIN, api)
        self.assertFalse(result)
        self.assertIn("::warning::", output)

    def test_a_version_commit_is_never_looked_up_off_main(self):
        api = release_push()
        result, _ = decide(dict(PUSH_TO_MAIN, GITHUB_REF="refs/heads/support/5.x"), api)
        self.assertFalse(result)
        self.assertEqual(api.paths, [])


class AgreesWithReleaseTests(unittest.TestCase):
    """queue_checked.py recognises what release.py and release.yml make."""

    def setUp(self):
        with open(RELEASE_YML, encoding="utf-8") as handle:
            self.workflow = handle.read()

    def test_the_version_message_is_a_version_commit(self):
        self.assertTrue(release.VERSION_COMMIT.match(release.VERSION_MESSAGE.format("6.4.1")))

    def test_the_version_file_is_the_one_the_release_sets(self):
        self.assertEqual(re.findall(r"^  PLIST: (\S+)$", self.workflow, re.MULTILINE), [queue_checked.VERSION_FILE])

    def test_the_release_bot_is_the_release_apps_bot(self):
        # release.py makes the version commit as RELEASE_BOT, the bot of the app whose token pushes it.
        self.assertEqual(re.findall(r"^ +RELEASE_BOT: (.+)$", self.workflow, re.MULTILINE),
                         ["${{ steps.app.outputs.app-slug }}[bot]"])
        self.assertIn("RELEASE_APP_CLIENT_ID", self.workflow)

    def test_the_latest_version_commit_in_the_history_is_by_the_release_bot(self):
        # Needs the history, so it runs in a full clone and is skipped in a shallow one.
        log = subprocess.run(["git", "-C", SCRIPTS, "log", "-1", "--format=%an%x00%s", "--fixed-strings",
                              f"--grep={release.VERSION_MESSAGE.format('')}"],
                             capture_output=True, text=True)
        if log.returncode != 0 or not log.stdout.strip():
            self.skipTest("no version commit in this checkout's history")
        author, subject = log.stdout.strip().split("\0", 1)
        self.assertTrue(subject.startswith(release.VERSION_MESSAGE.format("")))
        self.assertEqual(author, queue_checked.RELEASE_BOT)


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
        for checked, written in [(queue_checked.QUEUE, "queue_checked=true\nversion_commit=false\n"),
                                 (queue_checked.VERSION, "queue_checked=true\nversion_commit=true\n"),
                                 (queue_checked.NOT_CHECKED, "queue_checked=false\nversion_commit=false\n")]:
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
