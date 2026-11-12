#!/usr/bin/env python3
"""Tests for parity_known.py, and for the release gate in release.py that uses it (#561).

The issues' states come from a fake, so the tests need no network. Only the standard library is used.
"""
import io
import os
import pathlib
import sys
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parity_known  # noqa: E402
import release  # noqa: E402


def pending(*issues, approved="Ian, 2026-11-09, pending"):
    return {"kind": "pending", "issues": list(issues), "approved": approved}


ACCEPTED = {"kind": "accepted", "issues": [515], "approved": "Ian, 2026-11-08, a stated limit"}
STATES = {
    1: {"state": "open", "milestone": "6.9.0"},
    2: {"state": "open", "milestone": "6.10.0"},
    3: {"state": "open", "milestone": None},
    4: {"state": "closed", "milestone": "6.9.0"},
}


def fetch(number):
    return STATES[number]


class KindTests(unittest.TestCase):
    def test_a_pending_entry_cites_issues_and_an_accepted_one_names_the_date(self):
        self.assertEqual(parity_known.check_kinds([pending(1), ACCEPTED]), [])

    def test_an_entry_without_a_kind_fails(self):
        errors = parity_known.check_kinds([{"issues": [1], "approved": "Ian, 2026-11-09"}])
        self.assertEqual(len(errors), 1)
        self.assertIn("kind", errors[0])

    def test_a_pending_entry_without_an_issue_fails(self):
        self.assertTrue(parity_known.check_kinds([pending()]))

    def test_an_accepted_entry_without_a_date_fails(self):
        self.assertTrue(parity_known.check_kinds([dict(ACCEPTED, approved="Ian")]))

    def test_the_real_file_has_valid_kinds(self):
        self.assertEqual(parity_known.check_kinds(parity_known.load()), [])


class StaleTests(unittest.TestCase):
    def test_a_pending_entry_that_cites_an_open_issue_passes(self):
        self.assertEqual(parity_known.stale([pending(1, 2)], fetch), [])

    def test_a_pending_entry_that_cites_a_closed_issue_fails(self):
        errors = parity_known.stale([pending(1), pending(1, 4)], fetch)
        self.assertEqual(len(errors), 1)
        self.assertIn("known difference 2 is pending #4, which is closed", errors[0])

    def test_an_accepted_entry_is_not_checked_against_its_issue(self):
        self.assertEqual(parity_known.stale([dict(ACCEPTED, issues=[4])], fetch), [])

    def test_an_issue_that_cannot_be_read_fails_loudly(self):
        def unreadable(number):
            raise parity_known.KnownError(f"Can't read the state of issue #{number}: HTTP 401")

        with self.assertRaises(parity_known.KnownError):
            parity_known.stale([pending(1)], unreadable)


class ReleaseBlockerTests(unittest.TestCase):
    def test_a_pending_entry_open_in_the_released_milestone_blocks(self):
        errors = parity_known.release_blockers([pending(1)], fetch, "6.9.0")
        self.assertEqual(len(errors), 1)
        self.assertIn("open in the 6.9.0 milestone", errors[0])

    def test_a_pending_entry_open_in_another_milestone_or_none_does_not_block(self):
        self.assertEqual(parity_known.release_blockers([pending(2, 3)], fetch, "6.9.0"), [])

    def test_a_closed_issue_does_not_block_a_release_but_the_stale_check_fails_it(self):
        self.assertEqual(parity_known.release_blockers([pending(4)], fetch, "6.9.0"), [])
        self.assertTrue(parity_known.stale([pending(4)], fetch))

    def test_an_accepted_entry_never_blocks(self):
        self.assertEqual(parity_known.release_blockers([dict(ACCEPTED, issues=[1])], fetch, "6.9.0"), [])


class ReleaseGateTests(unittest.TestCase):
    """release.check_parity_differences, which plan runs for a dry run and a real one."""

    def gate(self, entries, version="6.9.0"):
        out = io.StringIO()
        with mock.patch.object(parity_known, "load", return_value=entries), \
                mock.patch.object(parity_known, "fetch_issue", side_effect=lambda repo, number: fetch(number)), \
                redirect_stdout(out):
            try:
                release.check_parity_differences("cucumberswift/CucumberSwift", version)
            except SystemExit as stopped:
                return stopped.code, out.getvalue()
        return 0, out.getvalue()

    def test_the_release_stops_while_a_pending_entry_is_open_in_its_milestone(self):
        code, out = self.gate([pending(1)])
        self.assertEqual(code, 1)
        self.assertIn("::error::The parity suite's known differences block this release.", out)
        self.assertIn("#1", out)

    def test_the_release_goes_ahead_once_the_entry_is_gone_or_accepted(self):
        self.assertEqual(self.gate([])[0], 0)
        self.assertEqual(self.gate([dict(ACCEPTED, issues=[1])])[0], 0)

    def test_another_versions_release_goes_ahead(self):
        self.assertEqual(self.gate([pending(1)], version="6.10.0")[0], 0)

    def test_the_release_stops_when_an_issue_cannot_be_read(self):
        out = io.StringIO()
        with mock.patch.object(parity_known, "load", return_value=[pending(1)]), \
                mock.patch.object(parity_known, "fetch_issue",
                                  side_effect=parity_known.KnownError("Can't read the state of issue #1")), \
                redirect_stdout(out), self.assertRaises(SystemExit):
            release.check_parity_differences("cucumberswift/CucumberSwift", "6.9.0")
        self.assertIn("Can't read the state of issue #1", out.getvalue())

    def test_a_branch_without_the_parity_suite_has_nothing_to_check(self):
        with mock.patch.object(parity_known, "KNOWN", "/nonexistent/known-differences.json"):
            self.assertEqual(parity_known.load("/nonexistent/known-differences.json"), [])

    def test_plan_runs_the_gate_before_it_checks_the_rulesets(self):
        source = pathlib.Path(__file__).with_name("release.py").read_text(encoding="utf-8")
        plan = source[source.index("def plan():"):source.index("def version_patterns")]
        self.assertLess(plan.index("check_parity_differences(repo, version)"), plan.index("check_rulesets(repo, branch, version)"))


if __name__ == "__main__":
    unittest.main()
