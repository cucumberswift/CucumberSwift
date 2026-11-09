#!/usr/bin/env python3
"""Tests for parity.py, which normalizes and compares the parity suite's results (#561)."""
import copy
import json
import os
import tempfile
import unittest

import parity


REPORT = [{
    "name": "Hooks", "uri": "file:///Users/x/Build/Features/Hooks.feature", "tags": [{"name": "@shop"}],
    "elements": [{
        "name": "Hooks run", "line": 3, "keyword": "Scenario", "tags": [],
        "steps": [
            {"line": 4, "keyword": "Given ", "name": "a step runs",
             "result": {"status": "passed", "duration": 123.4}},
            {"line": 5, "keyword": "Then ", "name": "it fails",
             "result": {"status": "failed", "duration": 5.0,
                        "error_message": "XCTAssertEqual failed at /Users/x/Tests/Steps.swift:9\nsecond line"}},
        ],
    }],
}]

XCTEST_OUTPUT = """\
Test Suite 'Hooks › Hooks run' failed at 2026-11-09 10:00:00.000.
Test Suite 'All tests' failed at 2026-11-09 10:00:01.000.
\t Executed 7 tests, with 1 failure (0 unexpected) in 0.5 (0.5) seconds
CucumberSwift coverage: Hooks: 50% of the code its scenarios ran, redundancy 0%, about 0.01 s of 0.20 s in redundant scenarios
CucumberSwift coverage: 3 scenarios in /Users/x/Documents/_cucumberCoverage/run-A5306254-2459-4850-8FA0-04DE45EE82E9
/Users/x/Features/Hooks.feature:1: warning: Feature coverage 50%
  CucumberSwift: /Users/x/Checkouts/CucumberSwift
"""


def trace_folder(files):
    folder = tempfile.mkdtemp()
    for name, text in files.items():
        with open(os.path.join(folder, name), "w", encoding="utf-8") as f:
            f.write(text)
    return folder


class CombinationTests(unittest.TestCase):
    def test_a_combination_has_four_parts(self):
        self.assertEqual(parity.parse_combination("xcode/xctest/serial/macOS"), ["xcode", "xctest", "serial", "macOS"])
        for bad in ("xcode/xctest/serial", "xcode/junit/serial/macOS", "xcode/xctest/fast/macOS", "a//b/c"):
            with self.assertRaises(parity.ParityError, msg=bad):
                parity.parse_combination(bad)


class NormalizeTests(unittest.TestCase):
    def test_the_report_loses_paths_durations_and_extra_error_lines(self):
        features = parity.normalize_report(REPORT)
        self.assertEqual(features["Hooks"]["file"], "Hooks.feature")
        self.assertEqual(features["Hooks"]["tags"], ["@shop"])
        steps = features["Hooks"]["scenarios"]["Hooks run (line 3)"][0]["steps"]
        self.assertEqual(steps, ["4 Given a step runs: passed",
                                 "5 Then it fails: failed (XCTAssertEqual failed at Steps.swift:9)"])

    def test_messages_lose_paths_times_run_folders_and_package_listings(self):
        messages = parity.read_messages(XCTEST_OUTPUT)
        self.assertEqual(messages, [
            "CucumberSwift coverage: 3 scenarios in run-<id>",
            "CucumberSwift coverage: Hooks: 50% of the code its scenarios ran, redundancy 0%, about <n> s of <n> s in redundant scenarios",
            "Hooks.feature:1: warning: Feature coverage 50%",
        ])

    def test_failed_scenarios_come_from_either_runners_output(self):
        self.assertEqual(parity.read_failed(XCTEST_OUTPUT), ["Hooks run"])
        self.assertEqual(parity.read_failed('✘ Test "Hooks run" with 2 test cases failed after 0.004 seconds with 1 issue.\n'
                                            '✘ Test "Other" recorded an issue with 1 argument testCase → 1 at X:1:1: Issue\n'),
                         ["Hooks run"])

    def test_the_trace_keeps_each_scenarios_order_and_counts_feature_hooks(self):
        folder = trace_folder({
            "1-a.trace": "scenario: Hooks › Hooks run (line 3)\nBeforeScenario\nstep: one\nAfterScenario\n",
            "1-b.trace": "feature: Hooks\nBeforeFeature\n",
            "2-c.trace": "feature: Hooks\nBeforeFeature\n",
        })
        hooks, trace = parity.read_trace(folder)
        self.assertEqual(hooks, {"Hooks": {"BeforeFeature": 2}})
        self.assertEqual(trace, {"Hooks › Hooks run (line 3)": [["BeforeScenario", "step: one", "AfterScenario"]]})

    def test_the_failures_in_a_result_bundle_name_the_scenario(self):
        summary = {"testFailures": [
            {"testIdentifierString": "F02 S04 › Failures › A requirement stops a step/1 › When it fails", "testName": "1 › When it fails"},
            {"testIdentifierString": "Failures › A requirement stops a step/2 › Then it never runs", "testName": "2 › Then it never runs"},
            {"testIdentifierString": "Features/Failures/ARequirement", "testName": "An expectation fails a step"},
        ]}
        self.assertEqual(parity.failed_from_summary(summary), ["A requirement stops a step", "An expectation fails a step"])

    def test_xcodes_workers_count_a_feature_hook_once_and_leave_out_messages(self):
        folder = trace_folder({"1-b.trace": "feature: Hooks\nBeforeFeature\n", "2-c.trace": "feature: Hooks\nBeforeFeature\n"})
        summary = {"totalTestCount": 9, "testFailures": []}
        result = parity.normalize("xcode/xctest/parallel/macOS", "", [], folder, 0, summary)
        self.assertEqual(result["hooks"], {"Hooks": {"BeforeFeature": 1}})
        self.assertEqual(result["tests"], {"XCTest": 9})
        self.assertNotIn("messages", result)
        serial = parity.normalize("xcode/xctest/serial/macOS", "", [], folder, 0, summary)
        self.assertEqual(serial["hooks"], {"Hooks": {"BeforeFeature": 2}})
        self.assertIn("messages", serial)


GOLDEN = {"exit": "failed", "tests": {"XCTest": 83, "Swift Testing": 30}, "messages": ["a", "b"],
          "features": {"F": {"tags": []}}}
KNOWN = {"combination": "*/swift-testing/parallel/*", "changes": [{"path": ["messages"], "value": ["c"]}],
         "behaviour": "Coverage is off", "issues": [1], "approved": "Ian, 2026-11-09"}


def result(**changes):
    value = copy.deepcopy(GOLDEN)
    value["tests"] = {"XCTest": 83}
    value.update(changes)
    return value


class CompareTests(unittest.TestCase):
    def test_an_identical_result_matches(self):
        self.assertEqual(parity.compare(result(), GOLDEN, [], "swiftpm/xctest/serial/macOS"), [])

    def test_the_other_runners_count_is_not_needed(self):
        swift_testing = result(tests={"Swift Testing": 30})
        self.assertEqual(parity.compare(swift_testing, GOLDEN, [], "swiftpm/swift-testing/serial/macOS"), [])
        wrong = result(tests={"Swift Testing": 29})
        self.assertTrue(parity.compare(wrong, GOLDEN, [], "swiftpm/swift-testing/serial/macOS"))

    def test_a_different_result_fails_with_a_diff(self):
        errors = parity.compare(result(exit="passed"), GOLDEN, [], "swiftpm/xctest/serial/macOS")
        self.assertEqual(len(errors), 1)
        self.assertIn('-  "exit": "failed"', errors[0])
        self.assertIn('+  "exit": "passed"', errors[0])

    def test_a_known_difference_allows_only_its_combination_and_value(self):
        combination = "swiftpm/swift-testing/parallel/macOS"
        ok = result(tests={"Swift Testing": 30}, messages=["c"])
        self.assertEqual(parity.compare(ok, GOLDEN, [KNOWN], combination), [])
        other_value = result(tests={"Swift Testing": 30}, messages=["d"])
        self.assertTrue(parity.compare(other_value, GOLDEN, [KNOWN], combination))
        serial = result(tests={"Swift Testing": 30}, messages=["c"])
        self.assertTrue(parity.compare(serial, GOLDEN, [KNOWN], "swiftpm/swift-testing/serial/macOS"))

    def test_a_known_difference_that_no_longer_differs_fails(self):
        combination = "swiftpm/swift-testing/parallel/macOS"
        same_as_golden = result(tests={"Swift Testing": 30})
        errors = parity.compare(same_as_golden, GOLDEN, [KNOWN], combination)
        self.assertTrue(any("no longer differs" in error for error in errors), errors)

    def test_a_known_difference_needs_every_field(self):
        for field in ("combination", "changes", "behaviour", "issues", "approved"):
            entry = {key: value for key, value in KNOWN.items() if key != field}
            with self.assertRaises(parity.ParityError, msg=field):
                parity.compare(result(), GOLDEN, [entry], "swiftpm/xctest/serial/macOS")

    def test_a_change_without_a_value_removes_the_golden_key(self):
        known = dict(KNOWN, changes=[{"path": ["messages"]}])
        without = result(tests={"Swift Testing": 30})
        del without["messages"]
        self.assertEqual(parity.compare(without, GOLDEN, [known], "swiftpm/swift-testing/parallel/macOS"), [])

    def test_known_prints_the_changes_that_make_the_golden_result_equal_a_result(self):
        actual = result(messages=["c"], features={"F": {"tags": ["@x"]}}, extra=1)
        del actual["exit"]
        changes = parity.diff_changes(GOLDEN, actual)
        self.assertEqual(changes, [
            {"path": ["exit"]},
            {"path": ["extra"], "value": 1},
            {"path": ["features", "F", "tags"], "value": ["@x"]},
            {"path": ["messages"], "value": ["c"]},
            {"path": ["tests", "Swift Testing"]},
        ])
        # compare() gives a result only its runner's test count, which is not a known difference.
        entry = dict(KNOWN, combination="*", changes=[change for change in changes if change["path"][0] != "tests"])
        self.assertEqual(parity.compare(actual, GOLDEN, [entry], "swiftpm/xctest/serial/macOS"), [])

    def test_assertion_text_is_dropped_only_for_scenarios_tagged_assertion_text(self):
        report = [{"name": "F", "uri": "x/F.feature", "elements": [
            {"name": "A", "line": 1, "keyword": "Scenario", "tags": [{"name": "assertion-text"}], "steps": [
                {"line": 2, "keyword": "When ", "name": "s", "result": {"status": "failed", "error_message": "XCTAssertEqual failed"}}]},
            {"name": "B", "line": 4, "keyword": "Scenario", "tags": [], "steps": [
                {"line": 5, "keyword": "When ", "name": "s", "result": {"status": "failed", "error_message": "boom"}}]}]}]
        scenarios = parity.normalize_report(report)["F"]["scenarios"]
        self.assertEqual(scenarios["A (line 1)"][0]["steps"], ["2 When s: failed"])
        self.assertEqual(scenarios["B (line 4)"][0]["steps"], ["5 When s: failed (boom)"])

    def test_a_parallel_run_is_compared_with_the_golden_parallel_values(self):
        golden = dict(GOLDEN, parallel={"messages": ["off"], "tests": {"XCTest": 65, "Swift Testing": 30}})
        parallel = result(tests={"XCTest": 65}, messages=["off"])
        self.assertEqual(parity.compare(parallel, golden, [], "swiftpm/xctest/parallel/macOS"), [])
        self.assertTrue(parity.compare(result(tests={"XCTest": 83}, messages=["off"]), golden, [], "swiftpm/xctest/parallel/macOS"))
        self.assertEqual(parity.compare(result(), golden, [], "swiftpm/xctest/serial/macOS"), [])

    def test_messages_are_skipped_when_the_result_has_none(self):
        without = result()
        del without["messages"]
        self.assertEqual(parity.compare(without, GOLDEN, [], "xcode/xctest/parallel/macOS"), [])

    def test_a_result_is_written_as_sorted_json(self):
        self.assertEqual(json.loads(parity.dump({"b": 1, "a": [2]})), {"a": [2], "b": 1})
        self.assertTrue(parity.dump({"b": 1, "a": 2}).startswith('{\n  "a"'))


if __name__ == "__main__":
    unittest.main()
