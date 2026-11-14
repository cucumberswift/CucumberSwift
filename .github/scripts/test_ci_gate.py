"""Unit tests for CI.yml's ci_gate job.

Run from the repository root:

  python3 -m unittest discover -s .github/scripts -v

The gate is the one check main's ruleset can require for the whole run (#606), so it must
need every job, run whatever they did, and fail only when one of them failed or was
cancelled. The step's script runs with bash and jq, as on the runner; those tests skip
where either is missing. Only the standard library is used.
"""
import json
import os
import re
import shutil
import subprocess
import unittest

WORKFLOW = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "workflows", "CI.yml")
# Jobs the gate doesn't need: itself, and the nightly report, which runs only on the
# schedule and needs the gate.
NOT_GATED = {"ci_gate", "nightly_report"}


def job_block(jobs, job_id):
    start = jobs.index(f"\n  {job_id}:\n")
    following = re.search(r"^  [A-Za-z0-9_-]+:\s*$", jobs[start + 2:], flags=re.MULTILINE)
    return jobs[start:start + 2 + following.start()] if following else jobs[start:]


class GateWorkflowTests(unittest.TestCase):
    def setUp(self):
        with open(WORKFLOW, encoding="utf-8") as file:
            text = file.read()
        jobs = text[text.index("\njobs:\n"):]
        self.job_ids = re.findall(r"^  ([A-Za-z0-9_-]+):\s*$", jobs, flags=re.MULTILINE)
        self.job = job_block(jobs, "ci_gate")

    def test_it_needs_every_job_but_itself_and_the_nightly_report(self):
        needs = re.search(r"^    needs: \[([^\]]*)\]", self.job, flags=re.MULTILINE)
        self.assertIsNotNone(needs, "ci_gate needs a one-line `needs: [...]` list")
        listed = [name.strip() for name in needs.group(1).split(",")]
        self.assertEqual(len(listed), len(set(listed)), "a job is listed twice")
        self.assertEqual(set(listed), set(self.job_ids) - NOT_GATED)

    def test_it_runs_whatever_the_jobs_it_needs_did(self):
        self.assertRegex(self.job, r"(?m)^    if: \$\{\{ !cancelled\(\) \}\}$")

    def test_it_reports_under_one_name_with_no_permissions(self):
        self.assertRegex(self.job, r"(?m)^    name: CI gate$")
        self.assertNotIn("strategy:", self.job)
        self.assertRegex(self.job, r"(?m)^    permissions: \{\}$")


@unittest.skipUnless(shutil.which("bash") and shutil.which("jq"), "needs bash and jq")
class GateStepTests(unittest.TestCase):
    """Runs the gate's step with a `needs` context like the one GitHub passes it."""

    def setUp(self):
        with open(WORKFLOW, encoding="utf-8") as file:
            text = file.read()
        job = job_block(text[text.index("\njobs:\n"):], "ci_gate")
        script = job[job.index("        run: |\n") + len("        run: |\n"):]
        lines = []
        for line in script.splitlines():
            if line.strip() and not line.startswith(" " * 10):
                break  # the block scalar ends at the first line indented less
            lines.append(line[10:])
        self.script = "\n".join(lines)

    def gate(self, **results):
        needs = {name: {"result": result, "outputs": {}} for name, result in results.items()}
        return subprocess.run(["bash", "-e", "-c", self.script], capture_output=True, text=True,
                              env={**os.environ, "NEEDS": json.dumps(needs)})

    def test_success_and_skipped_pass(self):
        result = self.gate(changes="success", ios_tests="skipped", fixture_tests="success")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("ios_tests: skipped", result.stdout)

    def test_a_failure_fails_and_names_the_job(self):
        result = self.gate(changes="success", script_tests="failure", docs="skipped")
        self.assertEqual(result.returncode, 1)
        self.assertIn("::error::These jobs didn't pass: script_tests", result.stdout)

    def test_a_cancelled_job_fails(self):
        result = self.gate(changes="success", bazel_tests="cancelled", docs="failure")
        self.assertEqual(result.returncode, 1)
        self.assertIn("bazel_tests, docs", result.stdout)


if __name__ == "__main__":
    unittest.main()


class ThrowawayFailure(unittest.TestCase):
    """Throwaway (#606): fails Script tests so CI shows the gate failing. Reverted next."""

    def test_fails(self):
        self.fail("throwaway failure to prove the CI gate fails")
