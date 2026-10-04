"""Unit tests for docs_only.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The event tests build a small git repository of their own in a temporary
directory, so they need git but no network access or checkout. Only the
standard library is used.
"""
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import docs_only  # noqa: E402

CATALOG = "Sources/CucumberSwift/CucumberSwift.docc"


class IsDocsTests(unittest.TestCase):
    def test_documentation_files_are_docs(self):
        for path in [
            "README.md",
            "CONTRIBUTING.md",
            "Fixtures/StepDefinitionMacrosPackage/README.md",
            ".github/pull_request_template.md",
            "NOTES.MD",
            f"{CATALOG}/CucumberSwift.md",
            f"{CATALOG}/Tutorials/GettingStarted.tutorial",
            f"{CATALOG}/Resources/Installation/Cartfile",
            f"{CATALOG}/Resources/GettingStarted/Sample.swift",
            f"{CATALOG}/Resources/image@2x.png",
            "LICENSE",
            ".github/ISSUE_TEMPLATE/bug_report.md",
            ".github/ISSUE_TEMPLATE/config.yml",
        ]:
            with self.subTest(path=path):
                self.assertTrue(docs_only.is_docs(path))

    def test_everything_else_is_code(self):
        for path in [
            "Sources/CucumberSwift/Runner/Cucumber.swift",
            ".github/workflows/CI.yml",
            ".github/scripts/docs_only.py",
            "Package.swift",
            "Package@swift-6.1.swift",
            "Package.resolved",
            "Project.swift",
            ".mise.toml",
            ".swiftlint.yml",
            "Fixtures/StepDefinitionMacrosPackage/Package.swift",
            "Tests/CucumberSwiftTests/Features/Basic.feature",
            "CucumberSwift.xcodeproj/project.pbxproj",
            "Sources/CucumberSwift/Info.plist",
            "MODULE.bazel",
            "README.md.orig",
            "LICENSE.txt",
            "Fixtures/LICENSE",
            "Sources/notes.docc",
            "Sources/CucumberSwift.doccarchive/data.json",
            ".github/ISSUE_TEMPLATES/bug_report.yml",
            ".github/CODEOWNERS",
        ]:
            with self.subTest(path=path):
                self.assertFalse(docs_only.is_docs(path))


class DocsOnlyTests(unittest.TestCase):
    def test_only_docs_is_docs_only(self):
        self.assertTrue(docs_only.docs_only(["README.md", f"{CATALOG}/Resources/a.png"]))

    def test_one_code_file_is_not_docs_only(self):
        self.assertFalse(docs_only.docs_only(["README.md", "Package.swift"]))

    def test_no_files_is_not_docs_only(self):
        self.assertFalse(docs_only.docs_only([]))


class Repository(unittest.TestCase):
    """A git repository with main at `base` and a branch at `head`, both from `root`."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cwd = os.getcwd()
        os.chdir(self.tmp.name)
        self.addCleanup(os.chdir, self.cwd)
        env = {"GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.com",
               "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.com",
               "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"}
        patcher = mock.patch.dict(os.environ, env)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.git("init", "-q", "-b", "main")
        self.write("README.md", "# CucumberSwift\n")
        self.write("Sources/CucumberSwift/Cucumber.swift", "public class Cucumber {}\n")
        self.root = self.commit("root")

    def git(self, *args):
        return subprocess.run(("git",) + args, check=True, capture_output=True, text=True).stdout.strip()

    def write(self, path, text):
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)

    def commit(self, message):
        self.git("add", "-A")
        self.git("commit", "-q", "--allow-empty", "-m", message)
        return self.git("rev-parse", "HEAD")

    def branch(self, *changes):
        """Commit each change, a path and its text (None deletes it), on a new branch."""
        self.git("switch", "-q", "-c", "topic", self.root)
        for path, text in changes:
            if text is None:
                self.git("rm", "-q", path)
            else:
                self.write(path, text)
        head = self.commit("topic")
        self.git("switch", "-q", "main")
        return head

    def pull_request(self, base, head):
        return {"pull_request": {"base": {"sha": base}, "head": {"sha": head}}}

    def decide(self, event_name, event):
        path = os.path.join(self.tmp.name, "event.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(event, handle)
        out = io.StringIO()
        with redirect_stdout(out):
            result = docs_only.decide(event_name, path)
        self.output = out.getvalue()
        return result


class PullRequestTests(Repository):
    def test_a_docs_only_pull_request_is_docs_only(self):
        head = self.branch(("README.md", "# Changed\n"), (f"{CATALOG}/Resources/a.png", "png"))
        self.assertTrue(self.decide("pull_request", self.pull_request(self.root, head)))
        self.assertIn("docs  README.md", self.output)

    def test_a_pull_request_changing_code_is_not_docs_only(self):
        head = self.branch(("README.md", "# Changed\n"), ("Package.swift", "// swift-tools-version:5.5\n"))
        self.assertFalse(self.decide("pull_request", self.pull_request(self.root, head)))
        self.assertIn("code  Package.swift", self.output)

    def test_code_that_landed_on_the_base_since_the_branch_does_not_count(self):
        head = self.branch(("README.md", "# Changed\n"))
        self.write("Sources/CucumberSwift/Cucumber.swift", "public final class Cucumber {}\n")
        base = self.commit("code on main")
        self.assertTrue(self.decide("pull_request", self.pull_request(base, head)))
        self.assertNotIn("Cucumber.swift", self.output)

    def test_deleting_code_is_not_docs_only(self):
        head = self.branch(("Sources/CucumberSwift/Cucumber.swift", None))
        self.assertFalse(self.decide("pull_request", self.pull_request(self.root, head)))

    def test_renaming_code_to_markdown_is_not_docs_only(self):
        self.git("switch", "-q", "-c", "topic", self.root)
        self.git("mv", "Sources/CucumberSwift/Cucumber.swift", "Cucumber.md")
        head = self.commit("rename")
        self.assertFalse(self.decide("pull_request", self.pull_request(self.root, head)))
        self.assertIn("code  Sources/CucumberSwift/Cucumber.swift", self.output)

    def test_a_path_with_unusual_characters_is_read_as_it_is(self):
        head = self.branch(("docs/naïve \"quoted\".md", "text\n"))
        self.assertTrue(self.decide("pull_request", self.pull_request(self.root, head)))
        self.assertIn('docs  docs/naïve "quoted".md', self.output)

    def test_a_pull_request_with_no_changed_files_is_not_docs_only(self):
        head = self.branch()
        self.assertFalse(self.decide("pull_request", self.pull_request(self.root, head)))


class MergeGroupTests(Repository):
    def merge_group(self, base, head):
        return {"merge_group": {"base_sha": base, "head_sha": head}}

    def test_a_docs_only_queue_entry_is_docs_only(self):
        head = self.branch(("LICENSE", "MIT\n"), (".github/ISSUE_TEMPLATE/bug.md", "bug\n"))
        self.assertTrue(self.decide("merge_group", self.merge_group(self.root, head)))

    def test_a_queue_entry_changing_code_is_not_docs_only(self):
        head = self.branch(("README.md", "# Changed\n"), (".github/workflows/CI.yml", "name: CI\n"))
        self.assertFalse(self.decide("merge_group", self.merge_group(self.root, head)))


class FullRunTests(Repository):
    def test_other_events_always_run_everything(self):
        head = self.branch(("README.md", "# Changed\n"))
        for event_name in ["push", "workflow_dispatch", "schedule", "pull_request_target", ""]:
            with self.subTest(event_name=event_name):
                event = self.pull_request(self.root, head)
                event.update({"before": self.root, "after": head})
                self.assertFalse(self.decide(event_name, event))
                self.assertIn("always runs the full CI", self.output)

    def test_an_event_without_its_commits_runs_everything(self):
        for event_name, event in [
            ("pull_request", {}),
            ("pull_request", {"pull_request": {"base": {"sha": self.root}, "head": {}}}),
            ("pull_request", {"pull_request": {"base": {"sha": self.root}, "head": {"sha": 7}}}),
            ("merge_group", {"merge_group": {"head_sha": self.root}}),
            ("merge_group", []),
            ("merge_group", {"merge_group": {"base_sha": "--output=/tmp/x", "head_sha": self.root}}),
            ("merge_group", {"merge_group": {"base_sha": "HEAD~1", "head_sha": self.root}}),
            ("merge_group", {"merge_group": {"base_sha": self.root[:12], "head_sha": self.root}}),
            ("merge_group", {"merge_group": {"base_sha": self.root.upper(), "head_sha": self.root}}),
        ]:
            with self.subTest(event=event):
                self.assertFalse(self.decide(event_name, event))
                self.assertIn("::warning::Running the full CI", self.output)

    def test_a_commit_missing_from_the_checkout_runs_everything(self):
        head = self.branch(("README.md", "# Changed\n"))
        self.assertFalse(self.decide("pull_request", self.pull_request("a" * 40, head)))
        self.assertIn("::warning::Running the full CI", self.output)

    def test_an_unreadable_event_runs_everything(self):
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertFalse(docs_only.decide("pull_request", os.path.join(self.tmp.name, "missing.json")))
        self.assertIn("::warning::Running the full CI", out.getvalue())
        path = os.path.join(self.tmp.name, "bad.json")
        self.write(path, "{not json")
        with redirect_stdout(io.StringIO()):
            self.assertFalse(docs_only.decide("pull_request", path))


class MainTests(Repository):
    def run_main(self, event_name, event):
        event_path = os.path.join(self.tmp.name, "event.json")
        with open(event_path, "w", encoding="utf-8") as handle:
            json.dump(event, handle)
        # GITHUB_OUTPUT is appended to, so each run gets a file of its own.
        handle, output = tempfile.mkstemp(dir=self.tmp.name)
        os.close(handle)
        env = {"GITHUB_EVENT_NAME": event_name, "GITHUB_EVENT_PATH": event_path, "GITHUB_OUTPUT": output}
        with mock.patch.dict(os.environ, env), redirect_stdout(io.StringIO()):
            status = docs_only.main()
        with open(output, encoding="utf-8") as handle:
            return status, handle.read()

    def test_a_docs_only_run_writes_true(self):
        head = self.branch(("README.md", "# Changed\n"))
        self.assertEqual(self.run_main("pull_request", self.pull_request(self.root, head)),
                         (0, "docs_only=true\n"))

    def test_any_other_run_writes_false(self):
        head = self.branch(("Package.swift", "// swift-tools-version:5.5\n"))
        self.assertEqual(self.run_main("pull_request", self.pull_request(self.root, head)),
                         (0, "docs_only=false\n"))
        self.assertEqual(self.run_main("push", {}), (0, "docs_only=false\n"))

    def test_no_output_file_fails(self):
        with mock.patch.dict(os.environ, {"GITHUB_EVENT_NAME": "push"}), redirect_stdout(io.StringIO()):
            os.environ.pop("GITHUB_OUTPUT", None)
            self.assertEqual(docs_only.main(), 1)


if __name__ == "__main__":
    unittest.main()
