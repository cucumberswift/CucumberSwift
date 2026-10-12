"""Unit tests for parallel_records.py.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

Only the standard library is used.
"""
import io
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parallel_records  # noqa: E402

UUID = "0D6E3A0C-1B5B-4C38-9D2B-6E2B7C1F7A11"


def name(process, sequence, kind, feature, scenario="-"):
    return f"{process}.{sequence:06d}.{kind}.{feature}.{scenario}.{UUID}"


def worker(process, feature, scenarios, start=1):
    """A worker's records for a feature: BeforeFeature, its scenarios, AfterFeature."""
    kinds = [("before", "-")] + [("scenario", s) for s in scenarios] + [("after", "-")]
    return [name(process, start + i, kind, feature, scenario) for i, (kind, scenario) in enumerate(kinds)]


A1, A2, B1 = "line-3-Sign-in", "line-9-Sign-out", "line-4-Pay"


class CheckTests(unittest.TestCase):
    def errors(self, names, unit="scenario", expected=3, min_workers=1):
        return parallel_records.check(names, unit, expected, min_workers)[1]

    def test_a_scenario_run_spread_over_workers_passes(self):
        names = worker(1, "Accounts", [A1]) + worker(2, "Accounts", [A2]) + worker(2, "Checkout", [B1], start=10)
        self.assertEqual(self.errors(names, min_workers=2), [])

    def test_a_scenario_that_ran_twice_fails(self):
        names = worker(1, "Accounts", [A1, A2]) + worker(2, "Accounts", [A1]) + worker(2, "Checkout", [B1], start=10)
        self.assertTrue(any("Ran 2 times" in e for e in self.errors(names)))

    def test_a_missing_scenario_fails(self):
        names = worker(1, "Accounts", [A1, A2])
        self.assertTrue(any("2 of 3 scenarios ran" in e for e in self.errors(names)))

    def test_too_few_workers_fails_with_scenarios(self):
        names = worker(1, "Accounts", [A1, A2]) + worker(1, "Checkout", [B1], start=10)
        self.assertTrue(any("did not run in parallel" in e for e in self.errors(names, min_workers=2)))

    def test_one_worker_is_enough_with_whole_features(self):
        names = worker(1, "Accounts", [A1, A2]) + worker(1, "Checkout", [B1], start=10)
        self.assertEqual(self.errors(names, unit="feature", min_workers=2), [])

    def test_after_feature_before_one_of_the_workers_scenarios_fails(self):
        names = [name(1, 1, "before", "Accounts"), name(1, 2, "scenario", "Accounts", A1),
                 name(1, 3, "after", "Accounts"), name(1, 4, "scenario", "Accounts", A2)]
        names += worker(2, "Checkout", [B1])
        self.assertTrue(any("AfterFeature last" in e for e in self.errors(names)))

    def test_a_scenario_before_before_feature_fails(self):
        names = [name(1, 1, "scenario", "Accounts", A1), name(1, 2, "before", "Accounts"),
                 name(1, 3, "scenario", "Accounts", A2), name(1, 4, "after", "Accounts")]
        names += worker(2, "Checkout", [B1])
        self.assertTrue(any("BeforeFeature should come first" in e for e in self.errors(names)))

    def test_a_missing_after_feature_fails(self):
        names = worker(1, "Accounts", [A1, A2])[:-1] + worker(2, "Checkout", [B1])
        self.assertTrue(any("AfterFeature 0 times" in e for e in self.errors(names)))

    def test_a_hook_in_a_worker_that_ran_none_of_the_features_scenarios_fails(self):
        names = worker(1, "Accounts", [A1, A2]) + worker(2, "Checkout", [B1]) + [name(2, 9, "after", "Accounts")]
        self.assertTrue(any("ran no scenario of 'Accounts'" in e for e in self.errors(names)))

    def test_whole_features_split_over_workers_fails(self):
        names = worker(1, "Accounts", [A1]) + worker(2, "Accounts", [A2]) + worker(2, "Checkout", [B1], start=10)
        self.assertTrue(any("in 2 workers, not one" in e for e in self.errors(names, unit="feature")))

    def test_whole_features_out_of_the_feature_files_order_fails(self):
        names = worker(1, "Accounts", [A2, A1]) + worker(1, "Checkout", [B1], start=10)
        self.assertTrue(any("not in the feature file's order" in e for e in self.errors(names, unit="feature")))

    def test_the_order_of_scenarios_does_not_matter_with_scenarios(self):
        names = worker(1, "Accounts", [A2, A1]) + worker(1, "Checkout", [B1], start=10)
        self.assertEqual(self.errors(names), [])

    def test_a_file_that_is_not_a_record_fails(self):
        names = worker(1, "Accounts", [A1, A2]) + worker(1, "Checkout", [B1], start=10) + [".DS_Store"]
        self.assertTrue(any("Not a record" in e for e in self.errors(names)))

    def test_the_sequence_orders_records_not_the_file_names(self):
        # Sorted by name, 10 would come before 9.
        names = [name(1, 9, "before", "Accounts"), name(1, 10, "scenario", "Accounts", A1),
                 name(1, 11, "scenario", "Accounts", A2), name(1, 12, "after", "Accounts")]
        names += worker(1, "Checkout", [B1], start=13)
        self.assertEqual(self.errors(names), [])


class MainTests(unittest.TestCase):
    def run_main(self, names, *args):
        with tempfile.TemporaryDirectory() as folder:
            for record in names:
                open(os.path.join(folder, record), "w").close()
            out, err = io.StringIO(), io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                status = parallel_records.main([folder, *args])
        return status, out.getvalue(), err.getvalue()

    def test_passes_and_summarises(self):
        names = worker(1, "Accounts", [A1, A2]) + worker(2, "Checkout", [B1])
        status, out, err = self.run_main(names, "--unit", "scenario", "--expected-scenarios", "3", "--min-workers", "2")
        self.assertEqual((status, err), (0, ""))
        self.assertIn("Scenario records: 3 for 3 scenarios, from 2 workers", out)
        self.assertIn("Accounts: worker 1 1/2/1", out)

    def test_fails_with_github_errors(self):
        status, _, err = self.run_main([], "--unit", "feature", "--expected-scenarios", "3")
        self.assertEqual(status, 1)
        self.assertIn("::error::0 of 3 scenarios ran", err)


if __name__ == "__main__":
    unittest.main()
