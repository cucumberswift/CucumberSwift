import json
import os
import tempfile
import unittest
import zipfile

import check_bazel_coverage


def outputs_zip(directory, manifest, files):
    path = os.path.join(directory, "outputs.zip")
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr("_cucumberCoverage/run-1/manifest.json", json.dumps(manifest))
        for name, content in files.items():
            archive.writestr(f"_cucumberCoverage/run-1/{name}", content)
    return path


def good_manifest():
    return {
        "binaries": [{"path": "/x/Tests.xctest/Contents/MacOS/Tests"}],
        "features": [{"feature": "Grading"}],
        "scenarios": [
            {"name": "A", "profiles": ["a-Tests.profraw"]},
            {"name": "B", "profiles": ["b-Tests.profraw"]},
        ],
    }


GOOD_FILES = {"a-Tests.profraw": "x", "b-Tests.profraw": "x"}


class CheckBazelCoverageTests(unittest.TestCase):
    def check(self, manifest, files, count=2):
        with tempfile.TemporaryDirectory() as directory:
            return check_bazel_coverage.check(outputs_zip(directory, manifest, files), count)

    def test_a_complete_run_passes(self):
        self.assertEqual(self.check(good_manifest(), GOOD_FILES), [])

    def test_a_missing_profile_fails(self):
        problems = self.check(good_manifest(), {"a-Tests.profraw": "x"})
        self.assertEqual(len(problems), 1)
        self.assertIn("b-Tests.profraw is missing or empty", problems[0])

    def test_an_empty_profile_fails(self):
        self.assertEqual(len(self.check(good_manifest(), {**GOOD_FILES, "a-Tests.profraw": ""})), 1)

    def test_too_few_scenarios_fail(self):
        manifest = good_manifest()
        manifest["scenarios"].pop()
        self.assertIn("expected 2 scenarios, the manifest has 1", self.check(manifest, GOOD_FILES)[0])

    def test_a_problem_fails(self):
        manifest = good_manifest() | {"scoresProblem": "no coverage map"}
        self.assertIn("scoresProblem: no coverage map", self.check(manifest, GOOD_FILES)[0])

    def test_no_scores_fail(self):
        manifest = good_manifest() | {"features": []}
        self.assertIn("no feature scores", self.check(manifest, GOOD_FILES)[0])

    def test_no_manifest_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "outputs.zip")
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("other.txt", "x")
            self.assertIn("expected one coverage manifest", check_bazel_coverage.check(path, 2)[0])


if __name__ == "__main__":
    unittest.main()
