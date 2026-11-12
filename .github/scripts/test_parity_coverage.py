#!/usr/bin/env python3
"""Tests for parity_coverage.py, which fails a public API or setting with no parity scenario (#561)."""
import unittest

import parity_coverage

FOUND = {"CucumberSwift/A.swift::public func a()": 3, "setting::Cucumber.reportPath": 9}
AVAILABLE = {"Hooks.feature": {"Hooks run"}}


def api(covered=None, baseline=None):
    return {"covered": covered or {}, "baseline": baseline or []}


class CheckTests(unittest.TestCase):
    def test_everything_listed_passes(self):
        covered = {"CucumberSwift/A.swift::public func a()": {"feature": "Hooks.feature", "scenario": "Hooks run"}}
        self.assertEqual(parity_coverage.check(FOUND, api(covered, ["setting::Cucumber.reportPath"]), AVAILABLE), [])

    def test_a_new_declaration_fails_and_names_the_fix(self):
        errors = parity_coverage.check(FOUND, api(baseline=["setting::Cucumber.reportPath"]), AVAILABLE)
        self.assertEqual(len(errors), 1)
        self.assertIn("CucumberSwift/A.swift::public func a()", errors[0])
        self.assertIn("api.json", errors[0])

    def test_a_scenario_that_does_not_exist_fails(self):
        covered = {"CucumberSwift/A.swift::public func a()": {"feature": "Hooks.feature", "scenario": "Gone"}}
        errors = parity_coverage.check(FOUND, api(covered, ["setting::Cucumber.reportPath"]), AVAILABLE)
        self.assertTrue(any("doesn't exist" in error for error in errors), errors)

    def test_an_entry_for_a_deleted_declaration_fails(self):
        errors = parity_coverage.check({}, api(baseline=["CucumberSwift/Old.swift::public func old()"]), AVAILABLE)
        self.assertTrue(any("isn't in the sources any more" in error for error in errors), errors)

    def test_a_declaration_cannot_be_covered_and_in_the_baseline(self):
        key = "CucumberSwift/A.swift::public func a()"
        covered = {key: {"feature": "Hooks.feature", "scenario": "Hooks run"}}
        errors = parity_coverage.check({key: 3}, api(covered, [key]), AVAILABLE)
        self.assertTrue(any("in `covered` and in `baseline`" in error for error in errors), errors)

    def test_the_real_sources_match_the_real_api_file(self):
        found = {**parity_coverage.declarations(), **parity_coverage.settings()}
        self.assertEqual(parity_coverage.check(found, parity_coverage.read_api(), parity_coverage.scenarios()), [])


if __name__ == "__main__":
    unittest.main()
