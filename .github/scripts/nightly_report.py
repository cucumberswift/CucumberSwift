#!/usr/bin/env python3
"""Report the nightly CI run in a GitHub issue.

CI.yml runs this in its `nightly_report` job, on the scheduled run only, after
every other job has finished. It lists the jobs of this run attempt and:

  - when a job failed, timed out or was cancelled, opens an issue titled TITLE
    that names each such job and links the run, or comments the same on the
    open issue with that title if there is one;
  - when every job passed or was skipped, comments on the open issue with that
    title, if there is one, that the run passed, so a maintainer can close it.

It never closes an issue. It looks only at open issues with exactly that title
that GitHub Actions opened, so an issue anyone else opens with the same title
is left alone.

Job names and the run's URL go to `gh` as arguments and on standard input, never
through a shell, and nothing reads the jobs' logs.

Run from the repository root, in a GitHub Actions job whose token can read
Actions and write issues (`actions: read`, `issues: write`):

  python3 .github/scripts/nightly_report.py

It reads GITHUB_REPOSITORY, GITHUB_RUN_ID, GITHUB_RUN_ATTEMPT and
GITHUB_SERVER_URL, and NIGHTLY_ISSUE_TITLE when set (to try it out under another
title), and calls the GitHub API with the `gh` CLI (GH_TOKEN). It exits non-zero
when it cannot list the jobs, find the issue, or open or comment on it.

Only the standard library is used.
"""
import json
import os
import subprocess
import sys

TITLE = "Nightly CI run failed"
# The issues GitHub Actions opens with GITHUB_TOKEN have this author.
AUTHOR = "github-actions[bot]"
FAILED = {"failure", "timed_out", "cancelled", "startup_failure"}


def gh(args, stdin=None):
    """Runs `gh` with these arguments and returns its standard output."""
    result = subprocess.run(["gh", *args], input=stdin, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"gh {args[0]} {args[1] if len(args) > 1 else ''} failed: {result.stderr.strip()}")
    return result.stdout


def json_lines(text):
    return [json.loads(line) for line in text.splitlines() if line.strip()]


def failing_jobs(repository, run_id, attempt, run=gh):
    """The names of this attempt's finished jobs that failed, in the API's order.

    The job running this script has not finished, so it is never listed."""
    jobs = json_lines(run([
        "api", "--paginate",
        f"repos/{repository}/actions/runs/{run_id}/attempts/{attempt}/jobs?per_page=100",
        "--jq", ".jobs[] | {name, status, conclusion}",
    ]))
    return [job["name"] for job in jobs if job["status"] == "completed" and job["conclusion"] in FAILED]


def open_issue(repository, title, run=gh):
    """The number of the oldest open issue GitHub Actions opened with this title, or None."""
    issues = json_lines(run([
        "api", "--paginate",
        f"repos/{repository}/issues?state=open&creator=github-actions%5Bbot%5D&per_page=100",
        "--jq", ".[] | {number, title, pull_request, author: .user.login}",
    ]))
    numbers = [issue["number"] for issue in issues
               if issue["title"] == title and issue["author"] == AUTHOR and issue["pull_request"] is None]
    return min(numbers) if numbers else None


def failure_text(run_url, jobs):
    lines = "\n".join(f"- {name}" for name in jobs)
    return f"The nightly CI run failed: {run_url}\n\nThese jobs failed:\n\n{lines}\n"


def pass_text(run_url):
    return f"A later nightly CI run passed: {run_url}\n\nA maintainer can close this issue.\n"


def report(environ, run=gh):
    """Opens or comments on the issue, and returns what it did, for the log."""
    repository = environ["GITHUB_REPOSITORY"]
    run_id = environ["GITHUB_RUN_ID"]
    attempt = environ.get("GITHUB_RUN_ATTEMPT") or "1"
    server = environ.get("GITHUB_SERVER_URL") or "https://github.com"
    title = environ.get("NIGHTLY_ISSUE_TITLE") or TITLE
    run_url = f"{server}/{repository}/actions/runs/{run_id}"
    if attempt != "1":
        run_url += f"/attempts/{attempt}"

    jobs = failing_jobs(repository, run_id, attempt, run)
    number = open_issue(repository, title, run)
    if jobs:
        body = failure_text(run_url, jobs)
        if number is None:
            url = run(["issue", "create", "--repo", repository, "--title", title, "--body-file", "-"], body).strip()
            return f"{len(jobs)} job(s) failed; opened {url}"
        run(["issue", "comment", str(number), "--repo", repository, "--body-file", "-"], body)
        return f"{len(jobs)} job(s) failed; commented on #{number}"
    if number is None:
        return "Every job passed, and no issue is open."
    run(["issue", "comment", str(number), "--repo", repository, "--body-file", "-"], pass_text(run_url))
    return f"Every job passed; commented on #{number}"


def main():
    try:
        print(report(os.environ))
    except (KeyError, RuntimeError, ValueError) as error:
        print(f"::error::Could not report the nightly run: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
