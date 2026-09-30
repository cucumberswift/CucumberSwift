"""Unit tests for release.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The GitHub API, git and the gh CLI are replaced with fakes, so the tests need no
network access or git history. Only the standard library is used.
"""
import base64
import copy
import difflib
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
import release  # noqa: E402

REPO = "cucumberswift/CucumberSwift"
OTHER_REPO = "cucumberswift/CucumberSwiftExpressions"
SHA = "a" * 40
MERGED_AT = "2026-09-01T00:00:00Z"
ZWSP = "\u200b"


class Status:
    """An HTTP error status returned by a fake API call."""

    def __init__(self, code):
        self.code = code


class Pages:
    """A list the API returns one page at a time."""

    def __init__(self, *pages):
        self.pages = pages


class Fake:
    """GitHub, git and the gh CLI, as release.py sees them."""

    def __init__(self):
        self.responses = {}   # (method, path) -> value, Status, Pages, or a function of the body
        self.calls = []       # (method, path, body, paginate)
        self.tokens = []      # (path, token) for every API call
        self.tags = []        # every tag in the repository
        self.merged = []      # tags reachable from SHA
        self.support = {}     # remote support branch -> tags it contains
        self.commits = []     # (sha, subject), oldest first
        self.graphql = {}     # pull request number -> pullRequest node
        self.runs = []        # every run() call
        self.processes = []   # every subprocess.run() call

    # release.api
    def api(self, path, method="GET", body=None, allow=(), paginate=False, token=None):
        self.calls.append((method, path, copy.deepcopy(body), paginate))
        self.tokens.append((path, token))
        if (method, path) not in self.responses:
            raise AssertionError(f"unexpected API call: {method} {path}")
        value = self.responses[(method, path)]
        if callable(value):
            value = value(body)
        if isinstance(value, Status):
            if value.code in allow:
                return None
            release.fail(f"GitHub API {method} {path.split('?')[0]} failed (HTTP {value.code}).")
        if isinstance(value, Pages):
            # Without --paginate, gh api returns only the first page.
            pages = value.pages if paginate else value.pages[:1]
            return [copy.deepcopy(item) for page in pages for item in page]
        return copy.deepcopy(value)

    def called(self, method, path):
        return [call for call in self.calls if call[0] == method and call[1] == path]

    # release.run
    def run(self, *args):
        self.runs.append(args)
        if args == ("git", "tag", "--list"):
            return "".join(f"{tag}\n" for tag in self.tags)
        if args == ("git", "tag", "--merged", SHA):
            return "".join(f"{tag}\n" for tag in self.merged)
        if args[:4] == ("git", "rev-list", "--reverse", "--no-merges"):
            return "".join(f"{sha}\n" for sha, _ in self.commits)
        if args[:4] == ("git", "log", "-1", "--format=%s"):
            return dict(self.commits)[args[4]] + "\n"
        if args[:3] == ("gh", "api", "graphql"):
            number = int(next(a for a in args if a.startswith("number="))[len("number="):])
            return json.dumps({"data": {"repository": {"pullRequest": self.graphql[number]}}})
        raise AssertionError(f"unexpected command: {args}")

    # release.succeeds
    def succeeds(self, *args):
        remote = "refs/remotes/origin/"
        if args[:4] == ("git", "rev-parse", "--verify", "-q"):
            return args[4].startswith(remote) and args[4][len(remote):] in self.support
        if args[:3] == ("git", "merge-base", "--is-ancestor"):
            tag, branch = args[3], args[4]
            return (tag.startswith("refs/tags/") and branch.startswith(remote)
                    and tag[len("refs/tags/"):] in self.support.get(branch[len(remote):], ()))
        raise AssertionError(f"unexpected command: {args}")

    # subprocess.run, used directly only for `gh release create`
    def process(self, args, **kwargs):
        self.processes.append(list(args))
        if list(args[:3]) != ["gh", "release", "create"]:
            raise AssertionError(f"unexpected process: {args}")
        return subprocess.CompletedProcess(args, 0, "", "")

    # Scenario helpers
    def no_rulesets(self, branch):
        self.responses.setdefault(("GET", f"repos/{REPO}/rules/branches/{branch}?per_page=100"), Pages([]))
        self.responses.setdefault(("GET", f"repos/{REPO}/rulesets?includes_parents=true&per_page=100"), Pages([]))

    def commit(self, sha, subject, pulls=()):
        self.commits.append((sha, subject))
        self.responses[("GET", f"repos/{REPO}/commits/{sha}/pulls")] = list(pulls)

    def merge(self, number, title, issues=(), login="alice", user_type="User", base="main", sha=None):
        """A pull request merged into `base` with one commit, closing `issues`."""
        self.commit(sha or f"{number:040x}", title, [pull(number, login, user_type, base)])
        self.graphql[number] = {"number": number, "title": title,
                                "closingIssuesReferences": {"nodes": list(issues)}}


def pull(number, login="alice", user_type="User", base="main", repo=REPO, merged=True, merge_commit=None):
    return {"number": number, "merged_at": MERGED_AT if merged else None, "merge_commit_sha": merge_commit,
            "base": {"ref": base, "repo": {"full_name": repo}},
            "user": {"login": login, "type": user_type}}


# An issue body with a migration section, as every breaking issue needs.
MIGRATION = "Some context.\n\n## Migration\n\nCall `run()` instead.\n\n## Details\n\nMore."


def issue(number, title, kind="Task", labels=(), repo=REPO, state="COMPLETED", body=""):
    return {"number": number, "title": title, "body": body, "stateReason": state,
            "repository": {"nameWithOwner": repo},
            "issueType": {"name": kind} if kind else None,
            "labels": {"nodes": [{"name": label} for label in labels]}}


class ReleaseTestCase(unittest.TestCase):
    """Runs each test in a temporary directory, with the fakes in place and only
    the environment the workflow provides."""

    def setUp(self):
        self.fake = Fake()
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.output = os.path.join(directory.name, "github_output")
        self.summary = os.path.join(directory.name, "step_summary")
        for path in (self.output, self.summary):
            open(path, "w", encoding="utf-8").close()
        cwd = os.getcwd()
        os.chdir(directory.name)
        self.addCleanup(os.chdir, cwd)
        patches = [
            mock.patch.object(release, "api", self.fake.api),
            mock.patch.object(release, "run", self.fake.run),
            mock.patch.object(release, "succeeds", self.fake.succeeds),
            mock.patch.object(release.subprocess, "run", self.fake.process),
            mock.patch.dict(os.environ, {"GITHUB_REPOSITORY": REPO, "RELEASE_SHA": SHA,
                                         "GITHUB_OUTPUT": self.output,
                                         "GITHUB_STEP_SUMMARY": self.summary}, clear=True),
        ]
        for patch in patches:
            patch.start()
            self.addCleanup(patch.stop)

    def call(self, function, *args):
        """Run `function` and return what it printed."""
        out = io.StringIO()
        try:
            with redirect_stdout(out):
                function(*args)
        except SystemExit:
            self.fail(f"The run stopped: {out.getvalue().strip()}")
        return out.getvalue()

    def fails(self, function, *args):
        """Run `function`, check that it stopped the run, and return the error."""
        out = io.StringIO()
        with redirect_stdout(out), self.assertRaises(SystemExit) as raised:
            function(*args)
        self.assertEqual(raised.exception.code, 1)
        errors = [line[len("::error::"):] for line in out.getvalue().splitlines()
                  if line.startswith("::error::")]
        self.assertEqual(len(errors), 1, out.getvalue())
        return errors[0]

    def read(self, path):
        with open(path, encoding="utf-8") as handle:
            return handle.read()

    def outputs(self):
        return dict(line.split("=", 1) for line in self.read(self.output).splitlines())


# plan: version --------------------------------------------------------------

class PlanTestCase(ReleaseTestCase):
    def setUp(self):
        super().setUp()
        # 4.2.1 was released from support/4.x, so main does not reach it.
        self.fake.tags = ["4.2.0", "4.2.1", "5.0.9", "5.0.10", "v1.0.0", "5.0.10-beta", "latest"]
        self.fake.merged = ["4.2.0", "5.0.9", "5.0.10", "v1.0.0", "5.0.10-beta", "latest"]

    def on_support(self, major, merged):
        self.fake.merged = merged
        return f"support/{major}.x"

    def plan(self, bump, branch="main"):
        os.environ.update(BRANCH=branch, BUMP=bump)
        self.fake.no_rulesets(branch)
        self.call(release.plan)
        return self.outputs()

    def plan_fails(self, bump, branch="main"):
        os.environ.update(BRANCH=branch, BUMP=bump)
        self.fake.no_rulesets(branch)
        return self.fails(release.plan)


class VersionTests(PlanTestCase):
    def test_patch_minor_and_major_from_main(self):
        self.fake.support = {"support/5.x": {"5.0.10"}}
        for bump, version in (("patch", "5.0.11"), ("minor", "5.1.0"), ("major", "6.0.0")):
            with self.subTest(bump):
                open(self.output, "w").close()
                self.assertEqual(self.plan(bump), {"version": version, "latest": "true"})

    def test_last_release_is_the_highest_version_not_the_last_in_text_order(self):
        self.fake.tags = self.fake.merged = ["5.0.9", "5.0.10", "5.0.8"]
        self.assertEqual(self.plan("patch")["version"], "5.0.11")

    def test_patch_and_minor_from_a_support_branch_are_never_latest(self):
        branch = self.on_support(4, ["4.2.0", "4.2.1"])
        for bump, version in (("patch", "4.2.2"), ("minor", "4.3.0")):
            with self.subTest(bump):
                open(self.output, "w").close()
                self.assertEqual(self.plan(bump, branch), {"version": version, "latest": "false"})

    def test_a_support_branch_release_is_not_latest_even_when_it_is_the_highest(self):
        # No 2.x yet: 1.2.4 would be the highest release, but it comes from support/1.x.
        self.fake.tags = ["1.2.3"]
        branch = self.on_support(1, ["1.2.3"])
        self.assertEqual(self.plan("patch", branch), {"version": "1.2.4", "latest": "false"})
        self.assertIn("Marked Latest: no", self.read(self.summary))

    def test_a_support_branch_counts_only_its_own_major(self):
        # A support branch can reach tags of an older major through its history.
        branch = self.on_support(5, ["4.2.0", "5.0.9", "5.0.10"])
        self.fake.tags += ["6.0.0"]
        self.assertEqual(self.plan("patch", branch)["version"], "5.0.11")

    def test_major_is_refused_on_a_support_branch(self):
        branch = self.on_support(4, ["4.2.0", "4.2.1"])
        self.assertEqual(self.plan_fails("major", branch),
                         "A major release cannot come from support/4.x. Release majors from main.")

    def test_a_version_not_higher_than_the_highest_release_is_refused(self):
        # 5.1.0 exists but main does not reach it.
        self.fake.tags += ["5.1.0"]
        self.assertEqual(self.plan_fails("patch"),
                         "5.0.11 is not higher than the highest release, 5.1.0.")

    def test_an_existing_tag_is_refused(self):
        self.fake.tags += ["4.2.2"]
        branch = self.on_support(4, ["4.2.0", "4.2.1"])
        self.assertEqual(self.plan_fails("patch", branch), "The tag 4.2.2 already exists.")

    def test_a_major_needs_the_support_branch_of_the_current_major(self):
        error = self.plan_fails("major")
        self.assertTrue(error.startswith("Releasing 6.0.0 needs support/5.x, created from 5.0.10."), error)
        self.assertIn("git push origin '5.0.10^{commit}:refs/heads/support/5.x'", error)

    def test_a_major_needs_the_support_branch_to_contain_the_last_release(self):
        self.fake.support = {"support/5.x": {"5.0.9"}}
        self.assertIn("needs support/5.x", self.plan_fails("major"))

    def test_leaving_0x_needs_no_support_branch(self):
        self.fake.tags = self.fake.merged = ["0.0.8", "0.0.9"]
        self.assertEqual(self.plan("major"), {"version": "1.0.0", "latest": "true"})
        self.assertFalse([r for r in self.fake.runs if "merge-base" in r])

    def test_a_branch_with_no_release_is_refused(self):
        branch = self.on_support(3, ["4.2.0"])
        self.assertEqual(self.plan_fails("patch", branch),
                         "No release found on support/3.x. Create the first release of a line by hand.")

    def test_an_unknown_bump_is_refused(self):
        self.assertEqual(self.plan_fails("prerelease"), "bump must be patch, minor or major.")

    def test_an_unexpected_branch_is_refused(self):
        for branch in ("feature/x", "support/5", "support/05.x", "support/5.x; true", "Main"):
            with self.subTest(branch=branch):
                self.assertEqual(self.plan_fails("patch", branch), "Unexpected branch.")

    def test_outputs_summary_and_notes_file(self):
        self.plan("patch")
        self.assertEqual(self.read(self.output), "version=5.0.11\nlatest=true\n")
        notes = self.read("notes.md")
        self.assertEqual(notes, "No changes since 5.0.10.\n\n**Full list of changes:** "
                                f"https://github.com/{REPO}/compare/5.0.10...5.0.11\n")
        summary = self.read(self.summary)
        self.assertTrue(summary.startswith("## This run releases 5.0.11\n"), summary)
        self.assertIn("- Branch: `main`\n- Last release on this line: `5.0.10`\n- Kind: `patch`\n"
                      "- Marked Latest: yes\n", summary)
        self.assertTrue(summary.endswith("### Release notes\n\n" + notes), summary)

    def test_changes_are_read_from_the_last_release_to_the_released_commit(self):
        self.plan("patch")
        self.assertIn(("git", "rev-list", "--reverse", "--no-merges", f"refs/tags/5.0.10..{SHA}"),
                      self.fake.runs)


# plan: bump check -----------------------------------------------------------

class BumpCheckTests(PlanTestCase):
    def setUp(self):
        super().setUp()
        self.fake.support = {"support/5.x": {"5.0.10"}}

    def at_0x(self):
        self.fake.tags = self.fake.merged = ["0.3.0", "0.3.1"]

    def test_breaking_needs_major(self):
        self.fake.merge(40, "Remove API", [issue(12, "Remove API", "Task", ["breaking"], body=MIGRATION)])
        for bump in ("patch", "minor"):
            with self.subTest(bump):
                self.assertEqual(self.plan_fails(bump),
                                 f"{bump} is too low: #12 is labelled breaking, which needs at least major. "
                                 "Choose a higher bump, or fix the labels and run again.")
        self.assertEqual(self.plan("major")["version"], "6.0.0")

    def test_breaking_needs_at_least_minor_below_1_0_0(self):
        self.at_0x()
        self.fake.merge(40, "Remove API", [issue(12, "Remove API", "Bug", ["breaking"], body=MIGRATION)])
        self.assertIn("which needs at least minor", self.plan_fails("patch"))
        self.assertEqual(self.plan("minor")["version"], "0.4.0")

    def test_a_feature_needs_at_least_minor(self):
        self.fake.merge(40, "Add tags", [issue(13, "Add tags", "Feature")])
        self.assertEqual(self.plan_fails("patch"),
                         "patch is too low: #13 is a Feature, which needs at least minor. "
                         "Choose a higher bump, or fix the labels and run again.")
        self.assertEqual(self.plan("minor")["version"], "5.1.0")

    def test_a_feature_needs_no_minor_below_1_0_0(self):
        self.at_0x()
        self.fake.merge(40, "Add tags", [issue(13, "Add tags", "Feature")])
        self.assertEqual(self.plan("patch")["version"], "0.3.2")

    def test_a_higher_bump_is_always_allowed(self):
        self.fake.merge(40, "Fix crash", [issue(12, "Fix crash", "Bug")])
        self.fake.merge(41, "Add tags", [issue(13, "Add tags", "Feature")])
        for bump, version in (("patch", None), ("minor", "5.1.0"), ("major", "6.0.0")):
            with self.subTest(bump):
                open(self.output, "w").close()
                if version is None:
                    self.plan_fails(bump)
                else:
                    self.assertEqual(self.plan(bump)["version"], version)

    def test_every_reason_is_listed(self):
        self.fake.merge(40, "Add tags", [issue(13, "Add tags", "Feature"),
                                         issue(12, "Remove API", "Task", ["breaking"])])
        self.assertIn("#12 is labelled breaking, #13 is a Feature, which needs at least major",
                      self.plan_fails("minor"))

    def test_issues_from_other_repositories_are_ignored(self):
        self.fake.merge(40, "Adopt the new parser", [issue(12, "Parser rewrite", "Feature", ["breaking"],
                                                           repo=OTHER_REPO)])
        self.plan("patch")
        notes = self.read("notes.md")
        self.assertNotIn("Parser rewrite", notes)
        # With no issue of its own, the pull request is listed by itself.
        self.assertIn("- Adopt the new parser (#40 by @alice)", notes)

    def test_issues_closed_as_not_planned_or_duplicate_are_ignored(self):
        self.fake.merge(40, "Try something", [issue(12, "Idea", "Feature", ["breaking"], state="NOT_PLANNED"),
                                              issue(13, "Same idea", "Feature", state="DUPLICATE")])
        self.plan("patch")
        self.assertNotIn("Idea", self.read("notes.md"))

    def test_pull_requests_into_other_branches_or_repositories_or_not_merged_are_ignored(self):
        self.fake.graphql[40] = {"number": 40, "title": "Add tags", "closingIssuesReferences": {
            "nodes": [issue(13, "Add tags", "Feature")]}}
        self.fake.commit("b" * 40, "Add tags", [pull(40, base="support/4.x"),
                                                pull(40, base="support/4.x", merge_commit="c" * 40),
                                                pull(40, repo="someone/CucumberSwift"),
                                                pull(40, merged=False)])
        self.plan("patch")
        self.assertIn("- Add tags (bbbbbbb)", self.read("notes.md"))
        self.assertFalse([r for r in self.fake.runs if r[:3] == ("gh", "api", "graphql")])

    def test_a_stacked_pull_request_is_found_by_its_merge_commit(self):
        # A stack merge squashes each layer onto main, but a layer keeps the base it had in the
        # stack: the branch of the layer below it.
        self.fake.merge(40, "Report errors at the step definition", [issue(12, "Report errors", "Bug")])
        self.fake.graphql[41] = {"number": 41, "title": "Report expression errors too", "closingIssuesReferences": {
            "nodes": [issue(13, "Report expression errors", "Feature")]}}
        self.fake.commit("d" * 40, "Report expression errors too (#41)",
                         [pull(41, base="bugfix/12-report-errors", merge_commit="d" * 40)])
        self.plan("minor")
        notes = self.read("notes.md")
        self.assertIn("- Report expression errors (#13, #41 by @alice)", notes)
        self.assertNotIn("dddddddd"[:7], notes)
        self.assertNotIn("Other changes", notes)


# plan: ruleset check --------------------------------------------------------

BRANCH_RULES = f"repos/{REPO}/rules/branches/main?per_page=100"
RULESETS = f"repos/{REPO}/rulesets?includes_parents=true&per_page=100"


def ruleset_path(number):
    return f"repos/{REPO}/rulesets/{number}?includes_parents=true"


class RulesetTests(ReleaseTestCase):
    def setUp(self):
        super().setUp()
        self.fake.responses[("GET", BRANCH_RULES)] = Pages([])
        self.fake.responses[("GET", RULESETS)] = Pages([])

    def branch_rule(self, kind, number=5, bypass="never", name="Protect main"):
        rule = {"type": kind, "ruleset_source_type": "Repository", "ruleset_source": REPO, "ruleset_id": number}
        self.fake.responses[("GET", ruleset_path(number))] = {
            "id": number, "name": name, "target": "branch", "enforcement": "active",
            "current_user_can_bypass": bypass}
        return rule

    def tag_ruleset(self, number=7, include=("refs/tags/*",), exclude=(), rules=("creation",),
                    bypass="never", enforcement="active", name="Protect release tags"):
        detail = {"id": number, "name": name, "target": "tag", "enforcement": enforcement,
                  "conditions": {"ref_name": {"include": list(include), "exclude": list(exclude)}},
                  "rules": [{"type": kind} for kind in rules]}
        if bypass is not None:
            detail["current_user_can_bypass"] = bypass
        self.fake.responses[("GET", ruleset_path(number))] = detail
        return {"id": number, "name": name, "target": "tag", "enforcement": enforcement}

    def check(self, version="5.0.11"):
        return self.call(release.check_rulesets, REPO, "main", version)

    def check_fails(self, version="5.0.11"):
        return self.fails(release.check_rulesets, REPO, "main", version)

    def test_no_rulesets(self):
        self.assertEqual(self.check(), "")

    def test_branch_rules_that_block_the_version_commit(self):
        for kind in ("pull_request", "required_status_checks", "update", "required_deployments", "merge_queue"):
            with self.subTest(kind):
                self.fake.responses[("GET", BRANCH_RULES)] = Pages([self.branch_rule(kind)])
                self.assertEqual(self.check_fails(),
                                 f'This release would stop part-way: ruleset "Protect main" ({kind}) blocks '
                                 "the version commit on main. Nothing was written. Change the ruleset, or let "
                                 "the release app bypass it, and run again.")

    def test_branch_rules_that_do_not_block_the_version_commit(self):
        # Their rulesets are not even read.
        kinds = ("required_signatures", "deletion", "non_fast_forward", "required_linear_history",
                 "creation", "commit_message_pattern")
        self.fake.responses[("GET", BRANCH_RULES)] = Pages(
            [{"type": kind, "ruleset_id": 5} for kind in kinds])
        self.check()
        self.assertFalse(self.fake.called("GET", ruleset_path(5)))

    def test_current_user_can_bypass(self):
        for bypass, blocked in (("always", False), ("exempt", False), ("pull_requests_only", True),
                                ("never", True), (None, True)):
            with self.subTest(bypass=bypass):
                self.fake.responses[("GET", BRANCH_RULES)] = Pages([self.branch_rule("pull_request")])
                if bypass is None:
                    del self.fake.responses[("GET", ruleset_path(5))]["current_user_can_bypass"]
                else:
                    self.fake.responses[("GET", ruleset_path(5))]["current_user_can_bypass"] = bypass
                self.fake.responses[("GET", RULESETS)] = Pages([self.tag_ruleset(bypass=bypass)])
                if blocked:
                    error = self.check_fails()
                    self.assertIn("(pull_request) blocks the version commit", error)
                    self.assertIn("(creation) blocks creating the tag 5.0.11", error)
                else:
                    self.check()

    def test_a_tag_ruleset_with_creation_blocks_the_tag(self):
        self.fake.responses[("GET", RULESETS)] = Pages([self.tag_ruleset()])
        self.assertIn('ruleset "Protect release tags" (creation) blocks creating the tag 5.0.11',
                      self.check_fails())

    def test_a_tag_ruleset_without_creation_does_not_block(self):
        self.fake.responses[("GET", RULESETS)] = Pages(
            [self.tag_ruleset(rules=("deletion", "update", "non_fast_forward"))])
        self.check()

    def test_tag_rulesets_not_active_are_skipped(self):
        for enforcement in ("evaluate", "disabled"):
            with self.subTest(enforcement):
                self.fake.responses[("GET", RULESETS)] = Pages([self.tag_ruleset(enforcement=enforcement)])
                self.check()
        self.assertFalse(self.fake.called("GET", ruleset_path(7)))

    def test_branch_rulesets_in_the_list_are_skipped(self):
        summary = self.tag_ruleset()
        summary["target"] = "branch"
        self.fake.responses[("GET", RULESETS)] = Pages([summary])
        self.check()

    def test_tag_ruleset_include_and_exclude(self):
        cases = [
            ((["~ALL"], []), True),
            ((["refs/tags/5.0.11"], []), True),
            ((["refs/tags/v*"], []), False),
            ((["refs/tags/*"], ["refs/tags/5.*"]), False),
            ((["refs/tags/*"], ["~ALL"]), False),
            ((["refs/tags/*"], ["refs/tags/6.*"]), True),
            (([], []), False),
        ]
        for (include, exclude), blocked in cases:
            with self.subTest(include=include, exclude=exclude):
                self.fake.responses[("GET", RULESETS)] = Pages(
                    [self.tag_ruleset(include=include, exclude=exclude)])
                if blocked:
                    self.check_fails()
                else:
                    self.check()

    def test_the_tag_checked_is_the_new_version(self):
        self.fake.responses[("GET", RULESETS)] = Pages([self.tag_ruleset(include=["refs/tags/5.0.11"])])
        self.check_fails("5.0.11")
        self.check("5.1.0")

    def test_every_page_of_branch_rules_is_read(self):
        self.fake.responses[("GET", BRANCH_RULES)] = Pages(
            [{"type": "deletion", "ruleset_id": 5}] * 100, [self.branch_rule("pull_request", number=6)])
        self.assertIn("(pull_request) blocks the version commit", self.check_fails())

    def test_every_page_of_rulesets_is_read(self):
        others = [dict(self.tag_ruleset(number=100 + n, enforcement="evaluate")) for n in range(100)]
        self.fake.responses[("GET", RULESETS)] = Pages(others, [self.tag_ruleset(number=7)])
        self.assertIn("(creation) blocks creating the tag", self.check_fails())

    def test_every_problem_is_reported_and_each_ruleset_is_read_once(self):
        self.fake.responses[("GET", BRANCH_RULES)] = Pages(
            [self.branch_rule("pull_request", name="Protect\n  main"), self.branch_rule("required_status_checks")])
        self.fake.responses[("GET", ruleset_path(5))]["name"] = "Protect\n  main"
        self.fake.responses[("GET", RULESETS)] = Pages([self.tag_ruleset()])
        self.assertEqual(self.check_fails(),
                         'This release would stop part-way: ruleset "Protect main" (pull_request) blocks the '
                         'version commit on main; ruleset "Protect main" (required_status_checks) blocks the '
                         'version commit on main; ruleset "Protect release tags" (creation) blocks creating '
                         "the tag 5.0.11. Nothing was written. Change the ruleset, or let the release app "
                         "bypass it, and run again.")
        self.assertEqual(len(self.fake.called("GET", ruleset_path(5))), 1)

    def test_the_rules_are_read_with_the_release_app_token(self):
        os.environ["RULES_TOKEN"] = "app-token"
        self.fake.responses[("GET", BRANCH_RULES)] = Pages([self.branch_rule("update", bypass="always")])
        self.fake.responses[("GET", RULESETS)] = Pages([self.tag_ruleset(bypass="always")])
        self.check()
        self.assertEqual(len(self.fake.tokens), 4)
        self.assertEqual({token for _, token in self.fake.tokens}, {"app-token"})

    def test_without_the_release_app_token_the_rules_are_read_with_gh_token(self):
        self.fake.responses[("GET", BRANCH_RULES)] = Pages([self.branch_rule("update", bypass="always")])
        self.check()
        self.assertEqual({token for _, token in self.fake.tokens}, {None})

    def test_plan_stops_on_a_ruleset_before_reading_changes(self):
        self.fake.tags = self.fake.merged = ["5.0.10"]
        self.fake.merge(40, "Fix crash", [issue(12, "Fix crash", "Bug")])
        self.fake.responses[("GET", BRANCH_RULES)] = Pages([self.branch_rule("pull_request")])
        os.environ.update(BRANCH="main", BUMP="patch")
        self.assertIn("blocks the version commit on main", self.fails(release.plan))
        self.assertFalse([c for c in self.fake.calls if "/commits/" in c[1]])
        self.assertEqual(self.read(self.output), "")


# Expected results from Ruby, which GitHub uses to match ruleset ref patterns:
#   File.fnmatch?(pattern, ref, File::FNM_PATHNAME)
# for each ref in REFS. Generated once with ruby 2.6.10; the tests do not need Ruby.
REFS = ("refs/tags/1.2.3", "refs/tags/release/1.2.3", "refs/tags/release/x/1.2.3", "refs/tags/v1.0.0")
FNMATCH = (
    ("refs/tags/*",               (True, False, False, True)),
    ("refs/*",                    (False, False, False, False)),
    ("refs/**",                   (False, False, False, False)),
    ("refs/**/*",                 (True, True, True, True)),
    ("refs/tags/**",              (True, False, False, True)),
    ("refs/tags/**/*",            (True, True, True, True)),
    ("refs/tags/release/**/*",    (False, True, True, False)),
    ("**",                        (False, False, False, False)),
    ("**/*",                      (True, True, True, True)),
    ("*",                         (False, False, False, False)),
    ("refs/tags/[0-9]*",          (True, False, False, False)),
    ("refs/tags/[!v]*",           (True, False, False, False)),
    ("refs/tags/v*",              (False, False, False, True)),
    ("refs/tags/1.?.3",           (True, False, False, False)),
    ("refs/tags/1.2.3",           (True, False, False, False)),
    ("refs/tags/1.2",             (False, False, False, False)),
    ("refs/**/1.2.3",             (True, True, True, False)),
    ("refs/**/tags/*",            (True, False, False, True)),
    ("refs/tags/**/1.2.3",        (True, True, True, False)),
    ("refs/t*/*",                 (True, False, False, True)),
    ("refs/tags/[",               (False, False, False, False)),
    ("refs/tags/1.[0-9].*",       (True, False, False, False)),
    ("refs/tags/1.2.[3]",         (True, False, False, False)),
    ("refs/**/**/1.2.3",          (True, True, True, False)),
    ("refs/tags/[!0-9]*",         (False, False, False, True)),
    ("refs/tags/**3",             (True, False, False, False)),
    ("refs/tags/*/1.2.3",         (False, True, False, False)),
    ("refs/tags/?.?.?",           (True, False, False, False)),
)


class RefPatternTests(unittest.TestCase):
    def test_matches_ruby_fnmatch_with_fnm_pathname(self):
        for pattern, expected in FNMATCH:
            for ref, match in zip(REFS, expected):
                with self.subTest(pattern=pattern, ref=ref):
                    self.assertEqual(bool(release.ref_pattern(pattern).fullmatch(ref)), match)

    def test_regex_characters_in_a_pattern_are_literal(self):
        self.assertTrue(release.ref_pattern("refs/tags/1.2+3").fullmatch("refs/tags/1.2+3"))
        self.assertFalse(release.ref_pattern("refs/tags/1.2.3").fullmatch("refs/tags/1x2x3"))
        self.assertFalse(release.ref_pattern("refs/tags/(a|b)").fullmatch("refs/tags/a"))


# plan: release notes --------------------------------------------------------

class NotesTests(PlanTestCase):
    def test_notes_from_a_plan(self):
        self.fake.tags = self.fake.merged = ["5.0.10"]
        self.fake.merge(40, "Fix the crash", [issue(12, "Crash on launch", "Bug")])
        self.fake.merge(41, "Bump rexml", login="dependabot[bot]", user_type="Bot")
        self.fake.commit("c" * 40, "Fix a typo in the README")
        self.fake.commit("d" * 40, "chore: set version 5.0.10")
        self.fake.commit("e" * 40, "[ci skip] Apply automatic changes")
        self.fake.merge(42, "Tags and docs", [issue(13, "Filter by tag", "Feature"),
                                              issue(14, "Document tags", None),
                                              issue(15, "Rename Scenario", "Bug", ["breaking"], body=MIGRATION)], login="bob")
        self.fake.merge(43, "Fix the crash again", [issue(12, "Crash on launch", "Bug")], login="carol")
        # A second commit of #40.
        self.fake.commit("f" * 40, "Review fixes", [pull(40)])
        self.fake.merge(44, "Clean up", [issue(16, "Tidy tests", "Task")], login="renovate", user_type="Bot")
        self.fake.support = {"support/5.x": {"5.0.10"}}
        self.plan("major")
        self.assertEqual(self.read("notes.md"), "\n".join([
            "## Breaking changes",
            "",
            "- Rename Scenario (#15, #42 by @bob)",
            "",
            "  **Migration:**",
            "",
            "  Call `run()` instead.",
            "",
            "## Bugs",
            "",
            "- Crash on launch (#12, #40 by @alice, #43 by @carol)",
            "",
            "## Features",
            "",
            "- Filter by tag (#13, #42 by @bob)",
            "",
            "## Tasks",
            "",
            "- Tidy tests (#16, #44 by renovate)",
            "",
            "## Other changes",
            "",
            "- Document tags (#14, #42 by @bob)",
            "- Bump rexml (#41 by dependabot[bot])",
            "- Fix a typo in the README (ccccccc)",
            "",
            f"**Full list of changes:** https://github.com/{REPO}/compare/5.0.10...6.0.0",
            "",
        ]))
        graphql = [r for r in self.fake.runs if r[:3] == ("gh", "api", "graphql")]
        self.assertEqual(len(graphql), 5)
        self.assertIn("owner=cucumberswift", graphql[0])
        self.assertIn("name=CucumberSwift", graphql[0])

    def test_empty_sections_are_left_out(self):
        text = release.notes(REPO, "5.0.10", "5.0.11", {}, [(41, "Bump rexml")], [], {})
        self.assertEqual(text, "## Other changes\n\n- Bump rexml (#41)\n\n"
                               f"**Full list of changes:** https://github.com/{REPO}/compare/5.0.10...5.0.11\n")

    def test_one_other_changes_section(self):
        issues = {14: {"title": "Untyped", "type": "", "breaking": False, "pulls": [42]},
                  15: {"title": "Unknown type", "type": "Epic", "breaking": False, "pulls": [42]}}
        text = release.notes(REPO, "5.0.10", "5.0.11", issues, [(41, "Lone")], [("abcdef1", "Direct")], {})
        self.assertEqual(text.count("## "), 1)
        self.assertIn("## Other changes\n\n- Untyped (#14, #42)\n- Unknown type (#15, #42)\n"
                      "- Lone (#41)\n- Direct (abcdef1)\n", text)

    def test_titles_are_shown_as_plain_text(self):
        titles = {
            "<script>alert(1)</script> & <b>bold</b>": "&lt;script&gt;alert(1)&lt;/script&gt; &amp; &lt;b&gt;bold&lt;/b&gt;",
            "Thanks @octocat and @example/team": f"Thanks @{ZWSP}octocat and @{ZWSP}example/team",
            "Run $(rm -rf ~) and `id`": "Run $(rm -rf ~) and `id`",
            "[click](https://example.com)": "\\[click\\](https://example.com)",
            "Two\nlines\tand   spaces ": "Two lines and spaces",
        }
        for title, shown in titles.items():
            with self.subTest(title=title):
                self.assertEqual(release.clean(title), shown)
                issues = {12: {"title": title, "type": "Bug", "breaking": False, "pulls": [40]}}
                text = release.notes(REPO, "5.0.10", "5.0.11", issues, [(41, title)], [("abcdef1", title)], {})
                self.assertIn(f"- {shown} (#12, #40)\n", text)
                self.assertIn(f"- {shown} (#41)\n", text)
                self.assertIn(f"- {shown} (abcdef1)\n", text)

    def test_titles_never_reach_a_command(self):
        self.fake.tags = self.fake.merged = ["5.0.10"]
        self.fake.merge(40, "Run $(touch pwned)", [issue(12, "Run `touch pwned`", "Bug")])
        self.fake.commit("c" * 40, "Direct $(touch pwned)")
        self.plan("patch")
        self.assertFalse([r for r in self.fake.runs if any("pwned" in str(a) for a in r)])

    def test_author(self):
        cases = [
            ({"login": "alice", "type": "User"}, "@alice"),
            ({"login": "dependabot[bot]", "type": "Bot"}, "dependabot[bot]"),
            ({"login": "renovate", "type": "Bot"}, "renovate"),
            ({"login": "someapp[bot]", "type": "User"}, "someapp[bot]"),
            ({"login": "<b>x</b>", "type": "User"}, ""),
            ({"login": "a b", "type": "User"}, ""),
            ({"type": "User"}, ""),
            (None, ""),
        ]
        for user, shown in cases:
            with self.subTest(user=user):
                self.assertEqual(release.author(user), shown)

    def test_a_pull_request_without_a_known_author(self):
        self.assertEqual(release.pull_ref(40, {}), "#40")
        self.assertEqual(release.pull_ref(40, {40: ""}), "#40")
        self.assertEqual(release.pull_ref(40, {40: "@alice"}), "#40 by @alice")


class MigrationTests(PlanTestCase):
    def setUp(self):
        super().setUp()
        self.fake.support = {"support/5.x": {"5.0.10"}}

    def test_the_section_runs_to_the_next_heading_of_the_same_level(self):
        body = ("## Summary\n\nWhy.\n\n## Migration\n\nStep one.\n\n### On macOS\n\nStep two.\n\n"
                "## Root cause\n\nNot this.")
        self.assertEqual(release.migration(body), "Step one.\n\n### On macOS\n\nStep two.")

    def test_the_last_section_runs_to_the_end(self):
        self.assertEqual(release.migration("Intro.\n\n## Migration\n\nDo this.\n"), "Do this.")

    def test_a_top_level_heading_also_ends_it(self):
        self.assertEqual(release.migration("## Migration\n\nDo this.\n\n# Appendix\n\nNot this."), "Do this.")

    def test_no_section(self):
        for body in ("", None, "## Summary\n\nNothing to migrate.", "### Migration\n\nToo deep.",
                     "## Migration notes\n\nAnother heading.", "Migration\n\nNot a heading."):
            with self.subTest(body=body):
                self.assertEqual(release.migration(body), "")

    def test_the_heading_ignores_case_spacing_and_closing_hashes(self):
        for heading in ("## Migration", "##   migration  ", "## MIGRATION ##", "  ## Migration"):
            with self.subTest(heading=heading):
                self.assertEqual(release.migration(f"{heading}\n\nDo this."), "Do this.")

    def test_windows_line_endings(self):
        self.assertEqual(release.migration("## Migration\r\n\r\nDo this.\r\n## Next\r\n"), "Do this.")

    def test_headings_inside_code_blocks_do_not_count(self):
        body = ("```\n## Migration\nNot this.\n```\n\n## Migration\n\nRun:\n\n```bash\n# a comment\n"
                "## another\n```\n\n~~~~\n```\n## still code\n~~~~\n\nDone.\n\n## Next")
        self.assertEqual(release.migration(body),
                         "Run:\n\n```bash\n# a comment\n## another\n```\n\n~~~~\n```\n## still code\n~~~~\n\nDone.")

    def test_html_and_mentions_are_neutralised_outside_code(self):
        text = ("Thanks @octocat. <script>x</script> & <b>y</b>, [docs](https://example.com)\n"
                "Use `Array<Int>` and ``a ` @b``.\n\n```swift\nlet x: Array<Int> = [] // @main\n```")
        self.assertEqual(release.clean_block(text),
                         f"Thanks @{ZWSP}octocat. &lt;script&gt;x&lt;/script&gt; &amp; &lt;b&gt;y&lt;/b&gt;, "
                         "[docs](https://example.com)\n"
                         "Use `Array<Int>` and ``a ` @b``.\n\n```swift\nlet x: Array<Int> = [] // @main\n```")

    def test_a_code_span_needs_a_closing_run_of_the_same_length(self):
        cases = {
            # One tick opens, two do not close: not code.
            "`@team``": f"`@{ZWSP}team``",
            "```@a``": f"```@{ZWSP}a``",
            # Two ticks open and close, with a tick inside: code.
            "`` `@team`` `": "`` `@team`` `",
            "``@a`` and `<b>`": "``@a`` and `<b>`",
            # The single tick closes at the next single tick, past the double one.
            "`@a`` and `@b`": f"`@a`` and `@{ZWSP}b`",
        }
        for text, shown in cases.items():
            with self.subTest(text=text):
                self.assertEqual(release.clean_block(text), shown)

    def test_an_escaped_backtick_does_not_open_a_code_span(self):
        # Each case checked against GitHub's Markdown renderer.
        cases = {
            # Escaped opener: not code.
            "\\`@team\\`": f"\\`@{ZWSP}team\\`",
            "\\``@c``": f"\\``@{ZWSP}c``",
            # An escaped backslash leaves the backtick active: code.
            "\\\\`@a`": "\\\\`@a`",
            # Backslashes inside a span are literal, so the span closes after one.
            "`a\\`@b <i>": f"`a\\`@{ZWSP}b &lt;i&gt;",
            "`` \\`@d`` x": "`` \\`@d`` x",
        }
        for text, shown in cases.items():
            with self.subTest(text=text):
                self.assertEqual(release.clean_block(text), shown)

    def test_a_code_span_that_wraps_a_line_is_escaped_like_text(self):
        # Safe side: a wrapped span shows escaped characters, and a backtick
        # that opens in one list item never hides the next item's text.
        self.assertEqual(release.clean_block("Use `Array<\nInt>` @x"), f"Use `Array&lt;\nInt&gt;` @{ZWSP}x")
        self.assertEqual(release.clean_block("- a `b\n- c` @y"), f"- a `b\n- c` @{ZWSP}y")

    def test_a_closing_fence_has_only_spaces_after_it(self):
        text = "```\n@a <b>\n``` not a close\n```  \n@c <d>"
        self.assertEqual(release.clean_block(text), f"```\n@a <b>\n``` not a close\n```  \n@{ZWSP}c &lt;d&gt;")
        body = "## Migration\n\n```\n## inside\n```text\n## still inside\n```\n\nDone.\n\n## Next"
        self.assertEqual(release.migration(body), "```\n## inside\n```text\n## still inside\n```\n\nDone.")

    def test_a_closing_fence_is_the_same_character_and_at_least_as_long(self):
        text = "````\n@a\n```\n~~~~\n@b\n````\n@c"
        self.assertEqual(release.clean_block(text), f"````\n@a\n```\n~~~~\n@b\n````\n@{ZWSP}c")

    def test_backticks_in_the_info_string_do_not_open_a_fence(self):
        self.assertEqual(release.clean_block("```a`b @c\n@d"), f"```a`b @{ZWSP}c\n@{ZWSP}d")
        self.assertEqual(release.migration("## Migration\n\n```a`b\n## Next\n\nNot this."), "```a`b")

    def test_an_unclosed_code_span_is_not_code(self):
        self.assertEqual(release.clean_block("A `tick and <b>"), "A `tick and &lt;b&gt;")

    def test_the_section_is_listed_under_its_issue(self):
        self.fake.tags = self.fake.merged = ["5.0.10"]
        body = "## Migration\n\nUse `run()`:\n\n```swift\nrun()\n```\n\n- one\n- two"
        self.fake.merge(40, "Rename", [issue(12, "Rename start", "Task", ["breaking"], body=body)])
        self.fake.merge(41, "Drop pods", [issue(13, "Drop CocoaPods", "Task", body="## Migration\n\nUse SwiftPM.")])
        self.fake.merge(42, "Fix", [issue(14, "Crash", "Bug", body="## Summary\n\nNo migration.")])
        self.plan("major")
        self.assertEqual(self.read("notes.md"), "\n".join([
            "## Breaking changes",
            "",
            "- Rename start (#12, #40 by @alice)",
            "",
            "  **Migration:**",
            "",
            "  Use `run()`:",
            "",
            "  ```swift",
            "  run()",
            "  ```",
            "",
            "  - one",
            "  - two",
            "",
            "## Bugs",
            "",
            "- Crash (#14, #42 by @alice)",
            "",
            "## Tasks",
            "",
            "- Drop CocoaPods (#13, #41 by @alice)",
            "",
            "  **Migration:**",
            "",
            "  Use SwiftPM.",
            "",
            f"**Full list of changes:** https://github.com/{REPO}/compare/5.0.10...6.0.0",
            "",
        ]))
        self.assertIn("  Use `run()`:", self.read(self.summary))

    def test_a_breaking_issue_without_a_section_is_refused(self):
        self.fake.merge(40, "Remove API", [issue(12, "Remove API", "Task", ["breaking"])])
        self.assertEqual(self.plan_fails("major"),
                         '#12 is labelled breaking but has no "## Migration" section. Add one to the issue body, '
                         "saying what consumers must change, and run again. Nothing was created.")
        self.assertFalse(os.path.exists("notes.md"))
        self.assertEqual(self.read(self.output), "")

    def test_an_empty_section_is_refused(self):
        body = "## Migration\n\n   \n\n## Details\n\nMore."
        self.fake.merge(40, "Remove API", [issue(12, "Remove API", "Task", ["breaking"], body=body)])
        self.assertIn("#12 is labelled breaking but has no", self.plan_fails("major"))

    def test_every_breaking_issue_without_a_section_is_listed(self):
        self.fake.merge(40, "Remove APIs", [issue(12, "Remove A", "Task", ["breaking"]),
                                            issue(13, "Remove B", "Task", ["breaking"], body=MIGRATION),
                                            issue(14, "Remove C", "Bug", ["breaking"])])
        self.assertTrue(self.plan_fails("major").startswith(
            '#12, #14 are labelled breaking but have no "## Migration" section.'))

    def test_the_bump_is_checked_before_the_section(self):
        self.fake.merge(40, "Remove API", [issue(12, "Remove API", "Task", ["breaking"])])
        self.assertIn("patch is too low", self.plan_fails("patch"))

    def test_the_section_never_reaches_a_command(self):
        self.fake.tags = self.fake.merged = ["5.0.10"]
        body = "## Migration\n\nRun $(touch pwned) and `touch pwned`."
        self.fake.merge(40, "Rename", [issue(12, "Rename", "Task", ["breaking"], body=body)])
        self.plan("major")
        self.assertIn("Run $(touch pwned) and `touch pwned`.", self.read("notes.md"))
        self.assertFalse([r for r in self.fake.runs if any("pwned" in str(a) for a in r)])


# publish --------------------------------------------------------------------

PLIST = "Sources/CucumberSwift/Info.plist"
PLIST_TEXT = """<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>CFBundleInfoDictionaryVersion</key>
\t<string>6.0</string>
\t<key>CFBundleShortVersionString</key>
\t<string>1.0</string>
\t<key>CFBundleVersion</key>
\t<string>5.0.10</string>
</dict>
</plist>
"""
COMMIT = "c" * 40
TAG_OBJECT = "7" * 40


def encoded(text):
    return {"content": base64.b64encode(text.encode("utf-8")).decode()}


class PublishTests(ReleaseTestCase):
    def setUp(self):
        super().setUp()
        os.environ.update(BRANCH="main", VERSION="5.0.11", LATEST="true", PLIST=PLIST)
        r = self.fake.responses
        r[("GET", f"repos/{REPO}/git/ref/heads/main")] = {"object": {"sha": SHA}}
        r[("GET", f"repos/{REPO}/contents/{PLIST}?ref={SHA}")] = encoded(PLIST_TEXT)
        r[("GET", f"repos/{REPO}/git/commits/{SHA}")] = {"sha": SHA, "tree": {"sha": "t" * 40}}
        self.blobs = iter(("1" * 40,))
        r[("POST", f"repos/{REPO}/git/blobs")] = lambda body: {"sha": next(self.blobs)}
        r[("POST", f"repos/{REPO}/git/trees")] = {"sha": "e" * 40}
        r[("POST", f"repos/{REPO}/git/commits")] = {"sha": COMMIT}
        r[("PATCH", f"repos/{REPO}/git/refs/heads/main")] = {"object": {"sha": COMMIT}}
        r[("GET", f"repos/{REPO}/git/ref/tags/5.0.11")] = Status(404)
        r[("POST", f"repos/{REPO}/git/tags")] = {"sha": TAG_OBJECT}
        r[("POST", f"repos/{REPO}/git/refs")] = {"ref": "refs/tags/5.0.11"}
        r[("GET", f"repos/{REPO}/releases/tags/5.0.11")] = Status(404)

    def body(self, method, path):
        calls = self.fake.called(method, f"repos/{REPO}/{path}")
        self.assertEqual(len(calls), 1, calls)
        return calls[0][2]

    def writes(self):
        return [(method, path) for method, path, _, _ in self.fake.calls if method != "GET"]

    def earlier_attempt(self, message="chore: set version 5.0.11", author="github-actions[bot]", parents=(SHA,)):
        self.fake.responses[("GET", f"repos/{REPO}/git/ref/heads/main")] = {"object": {"sha": COMMIT}}
        self.fake.responses[("GET", f"repos/{REPO}/git/commits/{COMMIT}")] = {
            "sha": COMMIT, "message": message, "author": {"name": author},
            "parents": [{"sha": p} for p in parents], "tree": {"sha": "e" * 40}}

    def test_a_first_run(self):
        out = self.call(release.publish)
        self.assertEqual(self.writes(), [
            ("POST", f"repos/{REPO}/git/blobs"),
            ("POST", f"repos/{REPO}/git/trees"),
            ("POST", f"repos/{REPO}/git/commits"),
            ("PATCH", f"repos/{REPO}/git/refs/heads/main"),
            ("POST", f"repos/{REPO}/git/tags"),
            ("POST", f"repos/{REPO}/git/refs"),
        ])
        self.assertEqual(self.body("POST", "git/trees"), {"base_tree": "t" * 40, "tree": [
            {"path": PLIST, "mode": "100644", "type": "blob", "sha": "1" * 40}]})
        self.assertEqual(self.body("POST", "git/commits"),
                         {"message": "chore: set version 5.0.11", "tree": "e" * 40, "parents": [SHA]})
        self.assertEqual(self.body("PATCH", "git/refs/heads/main"), {"sha": COMMIT, "force": False})
        self.assertEqual(self.body("POST", "git/tags"),
                         {"tag": "5.0.11", "message": "5.0.11", "object": COMMIT, "type": "commit"})
        self.assertEqual(self.body("POST", "git/refs"), {"ref": "refs/tags/5.0.11", "sha": TAG_OBJECT})
        self.assertEqual(self.fake.processes, [[
            "gh", "release", "create", "5.0.11", "--verify-tag", "--title", "Release 5.0.11",
            "--notes-file", "notes.md", "--latest=true", "docs-major.zip", "docs-root.zip"]])
        self.assertEqual(self.read(self.summary), f"Released 5.0.11 at {COMMIT}.\n")
        self.assertEqual(out, "")

    def test_latest_false_is_passed_on(self):
        os.environ["LATEST"] = "false"
        self.call(release.publish)
        self.assertIn("--latest=false", self.fake.processes[0])

    def test_the_version_commit_changes_only_the_version_lines(self):
        self.call(release.publish)
        blobs = [call[2] for call in self.fake.called("POST", f"repos/{REPO}/git/blobs")]
        for blob, before, lines in ((blobs[0], PLIST_TEXT, ["\t<string>5.0.11</string>"] * 2),):
            self.assertEqual(blob["encoding"], "base64")
            after = base64.b64decode(blob["content"]).decode("utf-8")
            changed = [l for l in difflib.ndiff(before.splitlines(True), after.splitlines(True)) if l[:1] in "+-"]
            self.assertEqual(len(changed), 2 * len(lines), changed)
            self.assertEqual([l for l in changed if l[:1] == "+"], [f"+ {line}\n" for line in lines])
            self.assertEqual(after.count("5.0.10"), 0)
            self.assertEqual(after.count("1.0<"), 0)

    def test_a_plist_key_already_current_is_left_as_it_is(self):
        self.fake.responses[("GET", f"repos/{REPO}/contents/{PLIST}?ref={SHA}")] = encoded(
            PLIST_TEXT.replace("<string>1.0</string>", "<string>5.0.11</string>"))
        self.call(release.publish)
        after = base64.b64decode(self.fake.called("POST", f"repos/{REPO}/git/blobs")[0][2]["content"]).decode()
        self.assertEqual(after, PLIST_TEXT.replace("1.0<", "5.0.11<").replace("5.0.10", "5.0.11"))

    def test_a_change_beyond_the_version_lines_stops_the_run(self):
        # set_version changes only version lines, so this guards against a future bug in it.
        set_version = release.set_version
        patch = mock.patch.object(release, "set_version",
                                  lambda path, content, version: set_version(path, content, version) + "\n")
        patch.start()
        self.addCleanup(patch.stop)
        self.assertEqual(self.fails(release.publish),
                         f"The version change in {PLIST} would touch more than the version lines.")
        self.assertEqual(self.writes(), [])

    def test_missing_or_current_version_files_are_skipped(self):
        self.fake.responses[("GET", f"repos/{REPO}/contents/{PLIST}?ref={SHA}")] = Status(404)
        self.call(release.publish)
        # Nothing to commit: the release is tagged at the released commit.
        self.assertEqual(self.writes(), [("POST", f"repos/{REPO}/git/tags"), ("POST", f"repos/{REPO}/git/refs")])
        self.assertEqual(self.body("POST", "git/tags")["object"], SHA)

    def test_unset_version_files_are_not_read(self):
        del os.environ["PLIST"]
        self.call(release.publish)
        self.assertFalse([c for c in self.fake.calls if "/contents/" in c[1]])

    def test_a_branch_that_moved_stops_the_run(self):
        self.fake.responses[("PATCH", f"repos/{REPO}/git/refs/heads/main")] = Status(422)
        self.assertEqual(self.fails(release.publish),
                         "main moved during the run. Nothing was tagged or released. Start a new run.")
        self.assertFalse(self.fake.called("POST", f"repos/{REPO}/git/tags"))
        self.assertFalse(self.fake.called("POST", f"repos/{REPO}/git/refs"))
        self.assertEqual(self.fake.processes, [])

    def test_another_failure_updating_the_branch_stops_the_run(self):
        self.fake.responses[("PATCH", f"repos/{REPO}/git/refs/heads/main")] = Status(403)
        self.assertIn("(HTTP 403)", self.fails(release.publish))
        self.assertEqual(self.fake.processes, [])

    def test_a_rerun_reuses_the_commit_the_tag_and_the_release(self):
        self.earlier_attempt()
        self.fake.responses[("GET", f"repos/{REPO}/git/ref/tags/5.0.11")] = {
            "object": {"type": "tag", "sha": TAG_OBJECT}}
        self.fake.responses[("GET", f"repos/{REPO}/git/tags/{TAG_OBJECT}")] = {
            "object": {"type": "commit", "sha": COMMIT}}
        self.fake.responses[("GET", f"repos/{REPO}/releases/tags/5.0.11")] = {"tag_name": "5.0.11"}
        out = self.call(release.publish)
        self.assertEqual(self.writes(), [])
        self.assertEqual(self.fake.processes, [])
        self.assertEqual(out, f"Reusing the version commit {COMMIT} from an earlier attempt.\n"
                              "Reusing the tag 5.0.11 from an earlier attempt.\n"
                              "The release 5.0.11 already exists. Nothing to do.\n")
        self.assertEqual(self.read(self.summary), f"Released 5.0.11 at {COMMIT}.\n")

    def test_a_rerun_after_the_commit_creates_the_tag_and_the_release(self):
        self.earlier_attempt()
        self.call(release.publish)
        self.assertEqual(self.writes(), [("POST", f"repos/{REPO}/git/tags"), ("POST", f"repos/{REPO}/git/refs")])
        self.assertEqual(self.body("POST", "git/tags")["object"], COMMIT)
        self.assertEqual(len(self.fake.processes), 1)

    def test_a_lightweight_tag_on_the_commit_is_reused(self):
        self.fake.responses[("GET", f"repos/{REPO}/git/ref/tags/5.0.11")] = {
            "object": {"type": "commit", "sha": COMMIT}}
        self.call(release.publish)
        self.assertFalse(self.fake.called("POST", f"repos/{REPO}/git/tags"))
        self.assertEqual(len(self.fake.processes), 1)

    def test_someone_elses_commit_on_the_branch_is_not_reused(self):
        for kwargs in ({"message": "chore: set version 5.0.12"}, {"author": "alice"},
                       {"parents": ("b" * 40,)}, {"parents": (SHA, "b" * 40)}):
            with self.subTest(**kwargs):
                self.fake.calls.clear()
                self.blobs = iter(("1" * 40,))
                self.earlier_attempt(**kwargs)
                self.fake.responses[("PATCH", f"repos/{REPO}/git/refs/heads/main")] = Status(422)
                self.assertIn("main moved during the run", self.fails(release.publish))
                self.assertTrue(self.fake.called("POST", f"repos/{REPO}/git/commits"))

    def test_a_rerun_reuses_the_version_commit_made_by_the_release_app(self):
        os.environ["RELEASE_BOT"] = "cucumberswift-release[bot]"
        self.earlier_attempt(author="cucumberswift-release[bot]")
        out = self.call(release.publish)
        self.assertIn(f"Reusing the version commit {COMMIT} from an earlier attempt.", out)
        self.assertFalse(self.fake.called("POST", f"repos/{REPO}/git/commits"))

    def test_with_the_release_app_a_github_actions_commit_is_not_reused(self):
        os.environ["RELEASE_BOT"] = "cucumberswift-release[bot]"
        self.earlier_attempt(author="github-actions[bot]")
        self.fake.responses[("PATCH", f"repos/{REPO}/git/refs/heads/main")] = Status(422)
        self.assertIn("main moved during the run", self.fails(release.publish))
        self.assertTrue(self.fake.called("POST", f"repos/{REPO}/git/commits"))

    def test_a_tag_on_another_commit_stops_the_run(self):
        for ref in ({"type": "commit", "sha": "b" * 40}, {"type": "tag", "sha": TAG_OBJECT}):
            with self.subTest(ref=ref):
                self.fake.responses[("GET", f"repos/{REPO}/git/ref/tags/5.0.11")] = {"object": ref}
                self.fake.responses[("GET", f"repos/{REPO}/git/tags/{TAG_OBJECT}")] = {
                    "object": {"type": "commit", "sha": "b" * 40}}
                self.blobs = iter(("1" * 40,))
                self.assertEqual(self.fails(release.publish),
                                 "The tag 5.0.11 already exists and points to another commit.")
                self.assertEqual(self.fake.processes, [])

    def test_an_existing_release_is_never_replaced(self):
        self.fake.responses[("GET", f"repos/{REPO}/releases/tags/5.0.11")] = {"tag_name": "5.0.11"}
        out = self.call(release.publish)
        self.assertIn("The release 5.0.11 already exists. Nothing to do.", out)
        self.assertEqual(self.fake.processes, [])
        self.assertFalse([c for c in self.fake.calls if "/releases" in c[1] and c[0] != "GET"])

    def test_a_failure_reading_the_release_stops_the_run(self):
        self.fake.responses[("GET", f"repos/{REPO}/releases/tags/5.0.11")] = Status(500)
        self.assertIn("(HTTP 500)", self.fails(release.publish))
        self.assertEqual(self.fake.processes, [])

    def test_unexpected_inputs_are_refused(self):
        for env in ({"VERSION": "5.0.11; true"}, {"VERSION": "v5.0.11"}, {"VERSION": "05.0.11"},
                    {"LATEST": "yes"}, {"BRANCH": "feature/x"}):
            with self.subTest(**env):
                os.environ.update(VERSION="5.0.11", LATEST="true", BRANCH="main")
                os.environ.update(env)
                self.assertIn("Unexpected", self.fails(release.publish))
                self.assertEqual(self.fake.calls, [])


class SetVersionTests(ReleaseTestCase):
    def test_plist(self):
        self.assertEqual(release.set_version(PLIST, PLIST_TEXT, "5.0.11"),
                         PLIST_TEXT.replace("<string>5.0.10</string>", "<string>5.0.11</string>")
                                   .replace("<string>1.0</string>", "<string>5.0.11</string>"))
        self.assertEqual(self.fails(release.set_version, "X.txt", "version = 1", "5.0.11"),
                         "X.txt is not a version file the release can change.")

    def test_exactly_one_version_is_required(self):
        cases = [(PLIST, PLIST_TEXT.replace("<key>CFBundleVersion<", "<key>CFBundleOther<"), "CFBundleVersion"),
                 (PLIST, PLIST_TEXT.replace("CFBundleShortVersionString", "CFBundleOther"),
                  "CFBundleShortVersionString"),
                 (PLIST, PLIST_TEXT + PLIST_TEXT, "CFBundleShortVersionString"),
                 (PLIST, PLIST_TEXT.replace("</dict>", "\t<key>CFBundleVersion</key>\n\t<string>1</string>\n</dict>"),
                  "CFBundleVersion"),
                 (PLIST, PLIST_TEXT.replace("</dict>", "\t<key>CFBundleVersion</key>\n\t<integer>1</integer>\n</dict>"),
                  "CFBundleVersion"),
                 (PLIST, PLIST_TEXT.replace("<string>1.0</string>", "<integer>1</integer>"),
                  "CFBundleShortVersionString")]
        for path, text, name in cases:
            with self.subTest(path=path, text=text):
                self.assertEqual(self.fails(release.set_version, path, text, "5.0.11"),
                                 f"Could not find exactly one {name} in {path}.")

    def test_a_version_value_split_over_lines_is_refused(self):
        # Replacing it would change more than its own line.
        cases = [(PLIST, PLIST_TEXT.replace("<string>5.0.10</string>", "<string>5.0\n10</string>"), "CFBundleVersion"),
                 (PLIST, PLIST_TEXT.replace("<string>1.0</string>", "<string>1.\n0</string>"),
                  "CFBundleShortVersionString")]
        for path, text, name in cases:
            with self.subTest(path=path, text=text):
                self.assertEqual(self.fails(release.set_version, path, text, "5.0.11"),
                                 f"Could not find exactly one {name} in {path}.")


# api ------------------------------------------------------------------------

class ApiTests(unittest.TestCase):
    def gh(self, returncode=0, stdout="", stderr=""):
        self.processes = []

        def fake_run(args, **kwargs):
            self.processes.append((list(args), kwargs))
            return subprocess.CompletedProcess(args, returncode, stdout, stderr)

        patch = mock.patch.object(release.subprocess, "run", fake_run)
        patch.start()
        self.addCleanup(patch.stop)

    def fails(self, *args, **kwargs):
        out = io.StringIO()
        with redirect_stdout(out), self.assertRaises(SystemExit) as raised:
            release.api(*args, **kwargs)
        self.assertEqual(raised.exception.code, 1)
        return out.getvalue()

    def test_a_get(self):
        self.gh(stdout='{"sha": "abc"}')
        self.assertEqual(release.api("repos/o/r/git/ref/heads/main"), {"sha": "abc"})
        args, kwargs = self.processes[0]
        self.assertEqual(args, ["gh", "api", "-X", "GET", "repos/o/r/git/ref/heads/main"])
        self.assertIsNone(kwargs["input"])
        self.assertTrue(kwargs["capture_output"])
        self.assertNotIn("shell", kwargs)

    def test_a_token_replaces_gh_token_for_that_call_only(self):
        self.gh(stdout="{}")
        with mock.patch.dict(os.environ, {"GH_TOKEN": "workflow-token"}):
            release.api("repos/o/r/rulesets", token="app-token")
            release.api("repos/o/r/rulesets")
            self.assertEqual(os.environ["GH_TOKEN"], "workflow-token")
        self.assertEqual(self.processes[0][1]["env"]["GH_TOKEN"], "app-token")
        self.assertIsNone(self.processes[1][1]["env"])

    def test_a_body_is_sent_as_json_on_stdin(self):
        self.gh(stdout='{"sha": "abc"}')
        release.api("repos/o/r/git/refs", "POST", {"ref": "refs/tags/1.0.0", "sha": "abc"})
        args, kwargs = self.processes[0]
        self.assertEqual(args, ["gh", "api", "-X", "POST", "repos/o/r/git/refs", "--input", "-"])
        self.assertEqual(json.loads(kwargs["input"]), {"ref": "refs/tags/1.0.0", "sha": "abc"})

    def test_an_empty_response(self):
        self.gh(stdout="\n")
        self.assertEqual(release.api("repos/o/r/git/refs/heads/main", "PATCH", {"sha": "abc"}), {})

    def test_only_an_allowed_status_returns_none(self):
        self.gh(1, stderr="gh: Not Found (HTTP 404)\n")
        self.assertIsNone(release.api("repos/o/r/releases/tags/1.0.0", allow=(404,)))

    def test_any_other_status_stops_the_run(self):
        for status, allow in ((404, ()), (500, (404,)), (403, (404, 422)), (422, (404,))):
            with self.subTest(status=status, allow=allow):
                self.gh(1, stderr=f"gh: Something went wrong (HTTP {status})\n")
                out = self.fails("repos/o/r/releases/tags/1.0.0?per_page=100", allow=allow)
                self.assertEqual(out, f"::error::GitHub API GET repos/o/r/releases/tags/1.0.0 failed (HTTP {status}).\n")

    def test_a_failure_without_a_status_stops_the_run(self):
        self.gh(1, stderr="error connecting to api.github.com\n")
        out = self.fails("repos/o/r/rulesets", allow=(404,))
        self.assertEqual(out, "::error::GitHub API GET repos/o/r/rulesets failed (HTTP error).\n")

    def test_the_error_output_of_gh_is_not_printed(self):
        self.gh(1, stderr="gh: Bad credentials (HTTP 401)\ndetail from gh\n")
        self.assertNotIn("detail from gh", self.fails("repos/o/r"))

    def test_every_page_of_a_list_is_read(self):
        self.gh(stdout='[[{"id": 1}, {"id": 2}], [{"id": 3}], []]')
        self.assertEqual(release.api("repos/o/r/rulesets?per_page=100", paginate=True),
                         [{"id": 1}, {"id": 2}, {"id": 3}])
        args, _ = self.processes[0]
        self.assertEqual(args, ["gh", "api", "-X", "GET", "repos/o/r/rulesets?per_page=100",
                                "--paginate", "--slurp"])

    def test_an_empty_list(self):
        self.gh(stdout="[[]]")
        self.assertEqual(release.api("repos/o/r/rulesets", paginate=True), [])

    def test_a_single_page_is_not_flattened_without_paginate(self):
        self.gh(stdout='[{"id": 1}]')
        self.assertEqual(release.api("repos/o/r/rulesets"), [{"id": 1}])
        self.assertNotIn("--paginate", self.processes[0][0])



if __name__ == "__main__":
    unittest.main()
