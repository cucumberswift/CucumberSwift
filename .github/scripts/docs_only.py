#!/usr/bin/env python3
"""Decide whether a CI run only changes documentation.

CI.yml and codeql.yml run this in their `changes` job. On a docs-only run they
skip the jobs that build and test code, and the Docs job checks the change.

A change is docs-only when every file it adds, changes, deletes or renames
(both the old and the new path) is one of:

  - a Markdown file, `*.md`, anywhere;
  - anything inside a DocC catalog, a `*.docc` folder, images included;
  - LICENSE, at the repository root;
  - an issue template, under .github/ISSUE_TEMPLATE/.

Which files a run changes depends on its event:

  pull_request  the pull request's head against its merge base with the base
                branch, as GitHub shows the pull request's files;
  merge_group   the merge queue's head commit against the queue's base commit.

Every other event (push, schedule, workflow_dispatch, ...) is never docs-only,
so main and the support/N.x branches always run everything. So does any error:
a missing or unreadable event, a commit that is not a full SHA or is missing
from the checkout, a git failure, or a change with no files. When in doubt, CI runs in full.

The checkout needs the history of both commits (actions/checkout with
`fetch-depth: 0`; `filter: blob:none` is enough, since only paths are read).

Run from the repository root, in a GitHub Actions job:

  python3 .github/scripts/docs_only.py

It reads GITHUB_EVENT_NAME and GITHUB_EVENT_PATH, prints the changed files and
the decision, and writes `docs_only=true` or `docs_only=false` to
GITHUB_OUTPUT. It exits non-zero only when it cannot write that output.

Only the standard library is used.
"""
import json
import os
import re
import subprocess
import sys

DOCS_EXTENSIONS = (".md",)
DOCC_CATALOG = ".docc"
ROOT_DOCS = {"LICENSE"}
DOCS_FOLDERS = (".github/ISSUE_TEMPLATE/",)
# A full commit SHA, SHA-1 or SHA-256. Anything else in the event never reaches git.
COMMIT_SHA = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")


class ChangesError(Exception):
    """The changed files could not be worked out."""


def is_docs(path):
    """Whether a changed file, as a repository-relative path, is documentation."""
    if path in ROOT_DOCS:
        return True
    if path.startswith(DOCS_FOLDERS):
        return True
    if path.lower().endswith(DOCS_EXTENSIONS):
        return True
    # A file inside a catalog: some folder above it ends in .docc.
    folders = path.split("/")[:-1]
    return any(folder.endswith(DOCC_CATALOG) for folder in folders)


def docs_only(paths):
    """Whether every changed file is documentation. No files is not docs-only."""
    return bool(paths) and all(is_docs(path) for path in paths)


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise ChangesError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def diff(base, head):
    # -z: paths exactly as stored, without quoting. --no-renames: a rename lists
    # both paths, so moving code into a .md file is still a code change.
    output = git("diff", "--name-only", "--no-renames", "-z", base, head, "--")
    return [path for path in output.split("\0") if path]


def sha(event, *keys):
    value = event
    for key in keys:
        value = value.get(key) if isinstance(value, dict) else None
    if not isinstance(value, str) or not COMMIT_SHA.fullmatch(value):
        raise ChangesError(f"the event has no commit SHA at {'.'.join(keys)}")
    return value


def changed_files(event_name, event):
    """The files a run changes, or None when the event always runs everything."""
    if event_name == "pull_request":
        base = sha(event, "pull_request", "base", "sha")
        head = sha(event, "pull_request", "head", "sha")
        merge_base = git("merge-base", base, head).strip()
        return diff(merge_base, head)
    if event_name == "merge_group":
        base = sha(event, "merge_group", "base_sha")
        head = sha(event, "merge_group", "head_sha")
        return diff(base, head)
    return None


def decide(event_name, event_path):
    """Whether the run is docs-only, printing why."""
    try:
        with open(event_path, encoding="utf-8") as handle:
            event = json.load(handle)
        paths = changed_files(event_name, event)
    except (OSError, ValueError, ChangesError) as error:
        print(f"::warning::Running the full CI: could not work out the changed files ({error}).")
        return False
    if paths is None:
        print(f"A {event_name} run always runs the full CI.")
        return False
    print(f"{len(paths)} changed files:")
    for path in paths:
        print(f"  {'docs' if is_docs(path) else 'code'}  {path}")
    result = docs_only(paths)
    print("Docs-only: the code jobs are skipped." if result else "Not docs-only: the full CI runs.")
    return result


def main():
    result = decide(os.environ.get("GITHUB_EVENT_NAME", ""), os.environ.get("GITHUB_EVENT_PATH", ""))
    output = os.environ.get("GITHUB_OUTPUT")
    if not output:
        print("::error::GITHUB_OUTPUT is not set.")
        return 1
    with open(output, "a", encoding="utf-8") as handle:
        handle.write(f"docs_only={'true' if result else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
