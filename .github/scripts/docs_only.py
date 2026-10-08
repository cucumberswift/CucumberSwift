#!/usr/bin/env python3
"""Decide whether a CI run changes code that the macOS jobs check.

CI.yml and codeql.yml run this in their `changes` job. Each changed file is one of:

  docs    documentation, which the Docs job checks;
  script  a script that only Linux jobs run, which Script tests checks;
  code    everything else, which the macOS jobs build and test.

A file is documentation when it is:

  - a Markdown file, `*.md`, anywhere;
  - anything inside a DocC catalog, a `*.docc` folder, images included;
  - LICENSE, at the repository root;
  - an issue template, under .github/ISSUE_TEMPLATE/.

A file is a Linux-run script when it is in LINUX_SCRIPTS below: a script in
.github/scripts that no macOS job runs, or its tests. The list names each file,
so a new script is code until it is added, and a script that a macOS job runs,
such as xcode-test.sh, select-xcode.sh, parallel-fixture.sh or check_lockfiles.py
(Project checks), never belongs on it.

On a run with no code, CI and CodeQL skip the macOS jobs that build and test
code. On a docs-only run, CI also skips Script tests; on a scripts-only run, it
also skips the Docs job. A run with no code that changes a DocC catalog still
compiles the catalog's Swift examples, in the SwiftPM tests job. A run that
changes documentation Script tests checks, listed in SCRIPT_TESTED_DOCS, is not
docs-only, so Script tests runs.

Which files a run changes depends on its event:

  pull_request  the pull request's head against its merge base with the base
                branch, as GitHub shows the pull request's files;
  merge_group   the merge queue's head commit against the queue's base commit.

Every other event (push, schedule, workflow_dispatch, ...) counts as changing
code, so main and the support/N.x branches always run everything. So does any error:
a missing or unreadable event, a commit that is not a full SHA or is missing
from the checkout, a git failure, or a change with no files. When in doubt, CI runs in full.

The checkout needs the history of both commits (actions/checkout with
`fetch-depth: 0`; `filter: blob:none` is enough, since only paths are read).

Run from the repository root, in a GitHub Actions job:

  python3 .github/scripts/docs_only.py

It reads GITHUB_EVENT_NAME and GITHUB_EVENT_PATH, prints the changed files and
the decision, and writes `docs_only`, `scripts_only`, `no_code` and `catalog`,
each `true` or `false`, to GITHUB_OUTPUT. `catalog` is whether a file inside a
DocC catalog changes, and is `true` on a full run. It exits non-zero only when it cannot write them.

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
# The scripts that only Linux jobs run, and their tests: Script tests runs the
# tests, the changes jobs run docs_only.py, the Release workflow's plan and release
# jobs run release.py, and docs.yml runs publish-docs.sh.
LINUX_SCRIPTS = {
    ".github/scripts/docs_only.py",
    ".github/scripts/test_docs_only.py",
    ".github/scripts/release.py",
    ".github/scripts/test_release.py",
    ".github/scripts/test_check_lockfiles.py",
    ".github/scripts/test_gherkin_highlighting.py",
    ".github/scripts/publish-docs.sh",
}
# The documentation that Script tests checks: test_gherkin_highlighting.py reads
# this article. A run changing it is not docs-only, so Script tests runs.
SCRIPT_TESTED_DOCS = {
    "Sources/CucumberSwift/CucumberSwift.docc/Running-Tests-In-Xcode.md",
}
# A full commit SHA, SHA-1 or SHA-256. Anything else in the event never reaches git.
COMMIT_SHA = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")


class ChangesError(Exception):
    """The changed files could not be worked out."""


def in_catalog(path):
    """Whether a changed file is inside a DocC catalog: some folder above it ends in .docc."""
    folders = path.split("/")[:-1]
    return any(folder.endswith(DOCC_CATALOG) for folder in folders)


def is_docs(path):
    """Whether a changed file, as a repository-relative path, is documentation."""
    if path in ROOT_DOCS:
        return True
    if path.startswith(DOCS_FOLDERS):
        return True
    if path.lower().endswith(DOCS_EXTENSIONS):
        return True
    return in_catalog(path)


def kind(path):
    """What a changed file is, as a repository-relative path: docs, script or code."""
    if is_docs(path):
        return "docs"
    if path in LINUX_SCRIPTS:
        return "script"
    return "code"


def summary(paths):
    """The outputs for these changed files. No files counts as code."""
    kinds = {kind(path) for path in paths}
    return {
        "docs_only": kinds == {"docs"} and not SCRIPT_TESTED_DOCS.intersection(paths),
        "scripts_only": kinds == {"script"},
        "no_code": bool(kinds) and "code" not in kinds,
        "catalog": not paths or any(in_catalog(path) for path in paths),
    }


FULL_RUN = summary([])



def printable(path):
    """A path for the log, on one line: a newline in it could start a workflow command."""
    return "".join(char if char.isprintable() else repr(char)[1:-1] for char in path)


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
    """The outputs for the run, printing why."""
    try:
        with open(event_path, encoding="utf-8") as handle:
            event = json.load(handle)
        paths = changed_files(event_name, event)
    except (OSError, ValueError, ChangesError) as error:
        print(f"::warning::Running the full CI: could not work out the changed files ({error}).")
        return FULL_RUN
    if paths is None:
        print(f"A {event_name} run always runs the full CI.")
        return FULL_RUN
    print(f"{len(paths)} changed files:")
    for path in paths:
        print(f"  {kind(path)}  {printable(path)}")
    result = summary(paths)
    if result["no_code"] and result["catalog"]:
        print("A DocC catalog changes: SwiftPM tests compiles its Swift examples.")
    if result["docs_only"]:
        print("Docs-only: the code jobs and Script tests are skipped.")
    elif result["scripts_only"]:
        print("Linux-run scripts only: the macOS jobs, Docs included, are skipped.")
    elif result["no_code"]:
        print("Docs and Linux-run scripts only: the macOS code jobs are skipped.")
    else:
        print("Code changes: the full CI runs.")
    return result


def main():
    result = decide(os.environ.get("GITHUB_EVENT_NAME", ""), os.environ.get("GITHUB_EVENT_PATH", ""))
    output = os.environ.get("GITHUB_OUTPUT")
    if not output:
        print("::error::GITHUB_OUTPUT is not set.")
        return 1
    with open(output, "a", encoding="utf-8") as handle:
        for name, value in result.items():
            handle.write(f"{name}={'true' if value else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
