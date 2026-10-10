#!/usr/bin/env python3
"""Decide whether a push to main repeats what the merge queue already checked.

CI.yml runs this in its `changes` job. A pull request that merges through the
merge queue is tested by a merge_group run, and when that run passes, main moves
to the very commit it tested. The push run that follows would test the same
commit again, so CI skips every job the merge queue runs when the pushed commit
was tested by a merge_group run of this workflow that passed or is still running.

The queue merges as soon as the required checks pass, so its run is usually still
running its other jobs (the Xcode 16 variants) when the push run starts. A run
still going counts: its jobs report on the same commit when they finish. A run
that failed or was cancelled does not.

The commit counts as checked only when both hold:

  - the run is a push to refs/heads/main (support/N.x has no merge queue);
  - GitHub lists a run of this workflow for the pushed commit (head_sha) with
    event merge_group that succeeded or has not completed.

Anything else, such as a push straight to main with no queue run, a failed or
cancelled queue run, another event or branch, or any error looking it up, counts
as not checked, and CI runs everything as before.

Run from the repository root, in a GitHub Actions job whose token can read
Actions (`actions: read`):

  python3 .github/scripts/queue_checked.py

It reads GITHUB_EVENT_NAME, GITHUB_REF, GITHUB_SHA, GITHUB_REPOSITORY and
GITHUB_WORKFLOW_REF, calls the GitHub API with the `gh` CLI (GH_TOKEN), prints
the decision, and writes `queue_checked`, `true` or `false`, to GITHUB_OUTPUT.
It exits non-zero only when it cannot write it.

Only the standard library is used.
"""
import json
import os
import re
import subprocess
import sys

MAIN = "refs/heads/main"
# A run's status until it completes; a completed run has a conclusion instead.
UNFINISHED = {"queued", "in_progress", "waiting", "pending", "requested"}
COMMIT_SHA = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")
REPOSITORY = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
# owner/repo/.github/workflows/<file>@<ref>
WORKFLOW_REF = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/\.github/workflows/([A-Za-z0-9_.-]+\.ya?ml)@.+")


class QueueLookupError(Exception):
    """The queue runs could not be looked up."""


def workflow_file(workflow_ref):
    """The workflow's file name, such as CI.yml, from GITHUB_WORKFLOW_REF."""
    match = WORKFLOW_REF.fullmatch(workflow_ref or "")
    if not match:
        raise QueueLookupError("GITHUB_WORKFLOW_REF does not name a workflow file")
    return match.group(1)


def gh_api(path):
    result = subprocess.run(["gh", "api", path], capture_output=True, text=True)
    if result.returncode != 0:
        raise QueueLookupError(f"gh api failed: {result.stderr.strip()}")
    try:
        return json.loads(result.stdout)
    except ValueError as error:
        raise QueueLookupError(f"gh api returned no JSON ({error})") from error


def passing_queue_runs(repository, workflow, sha, api=gh_api):
    """The ids of this workflow's merge_group runs on the commit that passed or are still going."""
    response = api(
        f"repos/{repository}/actions/workflows/{workflow}/runs"
        f"?head_sha={sha}&event=merge_group&per_page=100"
    )
    runs = response.get("workflow_runs") if isinstance(response, dict) else None
    if not isinstance(runs, list):
        raise QueueLookupError("the response has no workflow_runs")
    # The query filters already; check again, so a filter GitHub ignored cannot
    # make a commit look checked.
    return [
        run.get("id")
        for run in runs
        if isinstance(run, dict)
        and run.get("head_sha") == sha
        and run.get("event") == "merge_group"
        and (run.get("conclusion") == "success" or run.get("status") in UNFINISHED)
    ]


def decide(environ, api=gh_api):
    """Whether the run's commit already passed the merge queue, printing why."""
    event = environ.get("GITHUB_EVENT_NAME", "")
    ref = environ.get("GITHUB_REF", "")
    if event != "push" or ref != MAIN:
        print(f"A {event or 'unknown'} run on {ref or 'an unknown ref'} is not a push to main: nothing is skipped.")
        return False
    sha = environ.get("GITHUB_SHA", "")
    repository = environ.get("GITHUB_REPOSITORY", "")
    try:
        if not COMMIT_SHA.fullmatch(sha):
            raise QueueLookupError("GITHUB_SHA is not a full commit SHA")
        if not REPOSITORY.fullmatch(repository):
            raise QueueLookupError("GITHUB_REPOSITORY is not owner/repo")
        workflow = workflow_file(environ.get("GITHUB_WORKFLOW_REF", ""))
        runs = passing_queue_runs(repository, workflow, sha, api)
    except QueueLookupError as error:
        print(f"::warning::Running the full CI: could not look up the merge queue runs ({error}).")
        return False
    if not runs:
        print(f"No passing or running merge queue run of {workflow} tested {sha}: the full CI runs.")
        return False
    print(f"Merge queue run {runs[0]} of {workflow} passed or is running on {sha}: "
          "only what the merge queue skips runs.")
    return True


def main():
    checked = decide(os.environ)
    output = os.environ.get("GITHUB_OUTPUT")
    if not output:
        print("::error::GITHUB_OUTPUT is not set.")
        return 1
    with open(output, "a", encoding="utf-8") as handle:
        handle.write(f"queue_checked={'true' if checked else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
