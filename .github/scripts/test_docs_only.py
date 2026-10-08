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


class KindTests(unittest.TestCase):
    def test_scripts_only_linux_jobs_run_are_scripts(self):
        for path in [
            ".github/scripts/docs_only.py",
            ".github/scripts/test_docs_only.py",
            ".github/scripts/release.py",
            ".github/scripts/test_release.py",
            ".github/scripts/test_check_lockfiles.py",
            ".github/scripts/test_gherkin_highlighting.py",
            ".github/scripts/publish-docs.sh",
        ]:
            with self.subTest(path=path):
                self.assertEqual(docs_only.kind(path), "script")

    def test_scripts_a_macos_job_runs_and_everything_else_are_code(self):
        for path in [
            ".github/scripts/xcode-test.sh",
            ".github/scripts/select-xcode.sh",
            ".github/scripts/parallel-fixture.sh",
            ".github/scripts/macros-trait-fixture.sh",
            ".github/scripts/check_lockfiles.py",
            ".github/scripts/new_script.py",
            ".github/scripts/__pycache__/release.cpython-313.pyc",
            ".github/workflows/CI.yml",
            ".github/workflows/release.yml",
            "scripts/release.py",
            "release.py",
            ".github/scripts/release.py.orig",
            "Package.swift",
            "Project.swift",
            "Sources/CucumberSwift/Runner/Cucumber.swift",
            "Tests/CucumberSwiftTests/Features/Basic.feature",
            "Fixtures/SwiftTestingPackage/Package.swift",
        ]:
            with self.subTest(path=path):
                self.assertEqual(docs_only.kind(path), "code")

    def test_documentation_is_docs(self):
        self.assertEqual(docs_only.kind("README.md"), "docs")
        self.assertEqual(docs_only.kind(".github/scripts/README.md"), "docs")


class SummaryTests(unittest.TestCase):
    def outputs(self, docs_only_, scripts_only, no_code, catalog=False):
        return {"docs_only": docs_only_, "scripts_only": scripts_only, "no_code": no_code,
                "catalog": catalog}

    def test_only_docs_is_docs_only(self):
        self.assertEqual(docs_only.summary(["README.md", f"{CATALOG}/Resources/a.png"]),
                         self.outputs(True, False, True, catalog=True))
        self.assertEqual(docs_only.summary(["README.md"]), self.outputs(True, False, True))

    def test_a_file_in_a_catalog_changes_the_catalog(self):
        for paths in [
            [f"{CATALOG}/Hooks.md"],
            ["README.md", f"{CATALOG}/Resources/Installation/StepDefinitions.swift"],
            ["Sources/CucumberSwift/Hooks.swift", f"{CATALOG}/Hooks.md"],
        ]:
            with self.subTest(paths=paths):
                self.assertTrue(docs_only.summary(paths)["catalog"])
        for paths in [["README.md"], ["Sources/CucumberSwift/Hooks.swift"], ["docs.docc"]]:
            with self.subTest(paths=paths):
                self.assertFalse(docs_only.summary(paths)["catalog"])

    def test_docs_that_script_tests_checks_are_not_docs_only(self):
        for paths in [
            [f"{CATALOG}/Running-Tests-In-Xcode.md"],
            ["README.md", f"{CATALOG}/Running-Tests-In-Xcode.md"],
        ]:
            with self.subTest(paths=paths):
                self.assertEqual(docs_only.summary(paths), self.outputs(False, False, True, True))

    def test_only_linux_scripts_is_scripts_only(self):
        self.assertEqual(docs_only.summary([".github/scripts/release.py", ".github/scripts/test_release.py"]),
                         self.outputs(False, True, True))

    def test_docs_and_linux_scripts_is_no_code(self):
        self.assertEqual(docs_only.summary(["README.md", ".github/scripts/release.py"]),
                         self.outputs(False, False, True))

    def test_one_code_file_is_code(self):
        for paths in [
            ["README.md", "Package.swift"],
            [".github/scripts/release.py", ".github/scripts/xcode-test.sh"],
            ["README.md", ".github/scripts/release.py", ".github/workflows/CI.yml"],
        ]:
            with self.subTest(paths=paths):
                self.assertEqual(docs_only.summary(paths), self.outputs(False, False, False))

    def test_no_files_is_code(self):
        self.assertEqual(docs_only.summary([]), self.outputs(False, False, False, catalog=True))
        self.assertEqual(docs_only.FULL_RUN, self.outputs(False, False, False, catalog=True))


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
        # Git sets GIT_DIR, GIT_INDEX_FILE and others when it runs a hook, and the git hooks
        # run these tests. Left set, they would point this test's git commands at the
        # repository being committed to. The patcher puts them back afterwards.
        for name in self.git("rev-parse", "--local-env-vars").split():
            os.environ.pop(name, None)
        self.git("init", "-q", "-b", "main")
        self.write("README.md", "# CucumberSwift\n")
        self.write("Sources/CucumberSwift/Cucumber.swift", "public class Cucumber {}\n")
        self.root = self.commit("root")

    def git(self, *args):
        return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout.strip()

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

    def decide(self, event_name, event, output="docs_only"):
        """One of the run's outputs, docs_only unless named."""
        return self.outputs(event_name, event)[output]

    def outputs(self, event_name, event):
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

    def test_a_path_cannot_print_a_line_of_its_own(self):
        head = self.branch(("docs/a\n::warning::forged\u2028.md", "text\n"))
        self.assertTrue(self.decide("pull_request", self.pull_request(self.root, head)))
        self.assertIn("docs  docs/a\\n::warning::forged\\u2028.md\n", self.output)
        self.assertNotIn("\n::warning::", self.output)

    def test_a_pull_request_changing_only_the_release_script_skips_the_macos_jobs(self):
        head = self.branch((".github/scripts/release.py", "print()\n"), (".github/scripts/test_release.py", "\n"))
        self.assertEqual(self.outputs("pull_request", self.pull_request(self.root, head)),
                         {"docs_only": False, "scripts_only": True, "no_code": True, "catalog": False})
        self.assertIn("script  .github/scripts/release.py", self.output)
        self.assertIn("Linux-run scripts only", self.output)

    def test_a_pull_request_changing_a_script_a_macos_job_runs_is_code(self):
        head = self.branch((".github/scripts/release.py", "print()\n"), (".github/scripts/xcode-test.sh", "#!/bin/sh\n"))
        self.assertEqual(self.outputs("pull_request", self.pull_request(self.root, head)),
                         {"docs_only": False, "scripts_only": False, "no_code": False, "catalog": False})
        self.assertIn("code  .github/scripts/xcode-test.sh", self.output)
        self.assertIn("the full CI runs", self.output)

    def test_renaming_code_to_a_linux_script_is_code(self):
        self.git("switch", "-q", "-c", "topic", self.root)
        os.makedirs(".github/scripts")
        self.git("mv", "Sources/CucumberSwift/Cucumber.swift", ".github/scripts/release.py")
        head = self.commit("rename")
        self.assertFalse(self.decide("pull_request", self.pull_request(self.root, head), "no_code"))

    def test_a_pull_request_with_no_changed_files_is_not_docs_only(self):
        head = self.branch()
        self.assertFalse(self.decide("pull_request", self.pull_request(self.root, head)))


class MergeGroupTests(Repository):
    def merge_group(self, base, head):
        return {"merge_group": {"base_sha": base, "head_sha": head}}

    def test_a_docs_only_queue_entry_is_docs_only(self):
        head = self.branch(("LICENSE", "MIT\n"), (".github/ISSUE_TEMPLATE/bug.md", "bug\n"))
        self.assertTrue(self.decide("merge_group", self.merge_group(self.root, head)))

    def test_a_queue_entry_changing_only_linux_scripts_has_no_code(self):
        head = self.branch((".github/scripts/release.py", "print()\n"))
        self.assertTrue(self.decide("merge_group", self.merge_group(self.root, head), "scripts_only"))
        self.assertTrue(self.decide("merge_group", self.merge_group(self.root, head), "no_code"))

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
                self.assertEqual(self.outputs(event_name, event), docs_only.FULL_RUN)
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
                self.assertEqual(self.outputs(event_name, event), docs_only.FULL_RUN)
                self.assertIn("::warning::Running the full CI", self.output)

    def test_a_commit_missing_from_the_checkout_runs_everything(self):
        head = self.branch(("README.md", "# Changed\n"))
        self.assertFalse(self.decide("pull_request", self.pull_request("a" * 40, head)))
        self.assertIn("::warning::Running the full CI", self.output)

    def test_an_unreadable_event_runs_everything(self):
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(docs_only.decide("pull_request", os.path.join(self.tmp.name, "missing.json")),
                             docs_only.FULL_RUN)
        self.assertIn("::warning::Running the full CI", out.getvalue())
        path = os.path.join(self.tmp.name, "bad.json")
        self.write(path, "{not json")
        with redirect_stdout(io.StringIO()):
            self.assertEqual(docs_only.decide("pull_request", path), docs_only.FULL_RUN)


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

    def test_a_docs_only_run_writes_docs_only_and_no_code(self):
        head = self.branch(("README.md", "# Changed\n"))
        self.assertEqual(self.run_main("pull_request", self.pull_request(self.root, head)),
                         (0, "docs_only=true\nscripts_only=false\nno_code=true\ncatalog=false\n"))

    def test_a_scripts_only_run_writes_scripts_only_and_no_code(self):
        head = self.branch((".github/scripts/release.py", "print()\n"))
        self.assertEqual(self.run_main("merge_group", {"merge_group": {"base_sha": self.root, "head_sha": head}}),
                         (0, "docs_only=false\nscripts_only=true\nno_code=true\ncatalog=false\n"))

    def test_a_code_run_writes_false_and_a_full_run_changes_the_catalog(self):
        head = self.branch(("Package.swift", "// swift-tools-version:5.5\n"))
        code = (0, "docs_only=false\nscripts_only=false\nno_code=false\ncatalog=false\n")
        self.assertEqual(self.run_main("pull_request", self.pull_request(self.root, head)), code)
        self.assertEqual(self.run_main("push", {}),
                         (0, "docs_only=false\nscripts_only=false\nno_code=false\ncatalog=true\n"))

    def test_no_output_file_fails(self):
        with mock.patch.dict(os.environ, {"GITHUB_EVENT_NAME": "push"}), redirect_stdout(io.StringIO()):
            os.environ.pop("GITHUB_OUTPUT", None)
            self.assertEqual(docs_only.main(), 1)


if __name__ == "__main__":
    unittest.main()
