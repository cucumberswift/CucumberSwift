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

The Release workflow's version commit counts as checked too (#400). release.py
pushes it straight to main, so no queue run tests it, but it changes only the
version in Info.plist, on top of a commit the queue did test. It counts when all
of these hold:

  - its message is the one release.py writes (VERSION_MESSAGE, which matches
    VERSION_COMMIT) for a version X.Y.Z;
  - its author is the release app's bot (RELEASE_BOT), on GitHub and in git;
  - it has one parent, and changes only VERSION_FILE, and only the version keys
    release.py sets (release.version_patterns), to X.Y.Z;
  - its parent passed or is running a merge_group run as above, or is itself
    such a version commit on a checked parent.

The parallel tests, which run on a push that changes Sources, skip a version
commit too (`version_commit`): the parent's push run decided them.

Anything else, such as a push straight to main with no queue run, a failed or
cancelled queue run, another event or branch, or any error looking it up, counts
as not checked, and CI runs everything as before.

Run from the repository root, in a GitHub Actions job whose token can read
Actions (`actions: read`):

  python3 .github/scripts/queue_checked.py

It reads GITHUB_EVENT_NAME, GITHUB_REF, GITHUB_SHA, GITHUB_REPOSITORY and
GITHUB_WORKFLOW_REF, calls the GitHub API with the `gh` CLI (GH_TOKEN), prints
the decision, and writes `queue_checked` and `version_commit`, each `true` or
`false`, to GITHUB_OUTPUT.
It exits non-zero only when it cannot write it.

Only the standard library is used.
"""
import base64
import json
import os
import re
import subprocess
import sys

import release

MAIN = "refs/heads/main"
# A run's status until it completes; a completed run has a conclusion instead.
UNFINISHED = {"queued", "in_progress", "waiting", "pending", "requested"}
COMMIT_SHA = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")
REPOSITORY = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
# owner/repo/.github/workflows/<file>@<ref>
WORKFLOW_REF = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/\.github/workflows/([A-Za-z0-9_.-]+\.ya?ml)@.+")
# The release app's bot, which release.yml passes to release.py as RELEASE_BOT
# (the app's slug and [bot]); test_queue_checked.py checks the two agree.
RELEASE_BOT = "cucumberswift-release[bot]"
# The file the version commit changes: release.yml's PLIST, checked by the tests too.
VERSION_FILE = "Sources/CucumberSwift/Info.plist"
# How many version commits in a row may sit on top of the queue-checked commit.
MAX_VERSION_COMMITS = 3

# What decide returns: not checked, checked by a queue run, or a version commit
# on a checked commit.
NOT_CHECKED = ""
QUEUE = "queue"
VERSION = "version"


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


def file_at(repository, path, sha, api):
    """The text of `path` at commit `sha`."""
    response = api(f"repos/{repository}/contents/{path}?ref={sha}")
    if not isinstance(response, dict) or response.get("encoding") != "base64":
        raise QueueLookupError(f"no base64 content for {path} at {sha}")
    try:
        return base64.b64decode(response.get("content") or "").decode("utf-8")
    except ValueError as error:
        raise QueueLookupError(f"{path} at {sha} is not UTF-8 text ({error})") from error


def only_the_version_changes(before, after, version):
    """Whether `after` is `before` with each version key set to `version`, as
    release.set_version would set them (which stops the run instead of answering)."""
    for _, occurrence, pattern in release.version_patterns(VERSION_FILE):
        if len(occurrence.findall(before)) != 1:
            return False
        before, count = pattern.subn(lambda m: f"{m.group(1)}{version}{m.group(2)}", before)
        if count != 1:
            return False
    return before == after


def version_parent(repository, sha, api=gh_api):
    """The parent of `sha` if `sha` is a version commit of the Release workflow,
    else None. Prints why a commit whose message looks like one is not."""
    response = api(f"repos/{repository}/commits/{sha}")
    commit = response.get("commit") if isinstance(response, dict) else None
    message = commit.get("message") if isinstance(commit, dict) else None
    if not isinstance(message, str) or not release.VERSION_COMMIT.match(message):
        return None
    version = message.strip().removeprefix(release.VERSION_MESSAGE.format(""))

    def not_one(why):
        print(f"{sha} looks like a version commit, but {why}.")
        return None

    if not release.SEMVER.match(version) or message.strip() != release.VERSION_MESSAGE.format(version):
        return not_one("its message is not the one release.py writes")
    author = response.get("author") if isinstance(response.get("author"), dict) else {}
    git_author = commit.get("author") if isinstance(commit.get("author"), dict) else {}
    if author.get("login") != RELEASE_BOT or git_author.get("name") != RELEASE_BOT:
        return not_one(f"its author is not {RELEASE_BOT}")
    parents = response.get("parents")
    if not isinstance(parents, list) or len(parents) != 1 or not isinstance(parents[0], dict) \
            or not COMMIT_SHA.fullmatch(str(parents[0].get("sha"))):
        return not_one("it does not have exactly one parent")
    parent = parents[0]["sha"]
    files = response.get("files")
    if not isinstance(files, list) or len(files) != 1 or not isinstance(files[0], dict) \
            or files[0].get("filename") != VERSION_FILE or files[0].get("status") != "modified":
        return not_one(f"it changes more than {VERSION_FILE}")
    before = file_at(repository, VERSION_FILE, parent, api)
    after = file_at(repository, VERSION_FILE, sha, api)
    if not only_the_version_changes(before, after, version):
        return not_one(f"it changes more than the version keys in {VERSION_FILE}")
    return parent


def checked(repository, workflow, sha, api=gh_api, depth=0):
    """QUEUE or VERSION if `sha` counts as checked, NOT_CHECKED if not, printing why."""
    runs = passing_queue_runs(repository, workflow, sha, api)
    if runs:
        print(f"Merge queue run {runs[0]} of {workflow} passed or is running on {sha}.")
        return QUEUE
    if depth >= MAX_VERSION_COMMITS:
        return NOT_CHECKED
    parent = version_parent(repository, sha, api)
    if parent is None:
        return NOT_CHECKED
    print(f"{sha} is the Release workflow's version commit on {parent}.")
    return VERSION if checked(repository, workflow, parent, api, depth + 1) else NOT_CHECKED


def decide(environ, api=gh_api):
    """Whether the run's commit already passed the merge queue (QUEUE), or is a
    version commit on one that did (VERSION), printing why. NOT_CHECKED, which is
    falsy, if neither."""
    event = environ.get("GITHUB_EVENT_NAME", "")
    ref = environ.get("GITHUB_REF", "")
    if event != "push" or ref != MAIN:
        print(f"A {event or 'unknown'} run on {ref or 'an unknown ref'} is not a push to main: nothing is skipped.")
        return NOT_CHECKED
    sha = environ.get("GITHUB_SHA", "")
    repository = environ.get("GITHUB_REPOSITORY", "")
    try:
        if not COMMIT_SHA.fullmatch(sha):
            raise QueueLookupError("GITHUB_SHA is not a full commit SHA")
        if not REPOSITORY.fullmatch(repository):
            raise QueueLookupError("GITHUB_REPOSITORY is not owner/repo")
        workflow = workflow_file(environ.get("GITHUB_WORKFLOW_REF", ""))
        result = checked(repository, workflow, sha, api)
    except QueueLookupError as error:
        print(f"::warning::Running the full CI: could not look up the merge queue runs ({error}).")
        return NOT_CHECKED
    if result == QUEUE:
        print("Only what the merge queue skips runs.")
    elif result == VERSION:
        print("Nothing runs: the merge queue checked the code, and the version commit changes only the version.")
    else:
        print(f"No passing or running merge queue run of {workflow} tested {sha}: the full CI runs.")
    return result


def main():
    result = decide(os.environ)
    output = os.environ.get("GITHUB_OUTPUT")
    if not output:
        print("::error::GITHUB_OUTPUT is not set.")
        return 1
    with open(output, "a", encoding="utf-8") as handle:
        handle.write(f"queue_checked={'true' if result else 'false'}\n"
                     f"version_commit={'true' if result == VERSION else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
