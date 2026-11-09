#!/usr/bin/env python3
"""Check Fixtures/Parity/known-differences.json against the issues it cites (#561).

Every entry has a `kind`:

  pending   behaviour that differs until an open issue fixes it. `issues` lists the issues.
  accepted  a limit a maintainer approved. `approved` names the maintainer and the date.

Two checks read the issues' states from GitHub, with `gh` and the workflow's GH_TOKEN:

  python3 .github/scripts/parity_known.py stale
      Fails if a pending entry cites a closed issue. The Parity tests job runs it. A fix removes its own
      entry, and an entry cannot stay after its issue closes.
  python3 .github/scripts/parity_known.py release <version>
      Fails if a pending entry cites an issue that is open in the milestone named <version>. The Release
      workflow's plan job runs it through release.py, in a dry run too, so cutting a release waits for the
      fix of each pending difference or for a maintainer to approve the entry as accepted. There is no flag
      that skips it.

Both fail, and say why, when an issue's state can't be read. The file is missing on a branch without the
parity suite, and then there is nothing to check.

Only the standard library is used.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KNOWN = os.path.join(ROOT, "Fixtures", "Parity", "known-differences.json")
KINDS = ("pending", "accepted")
# A maintainer's approval with its date, as an accepted entry must say it.
APPROVAL = re.compile(r"\b\d{4}-\d{2}-\d{2}\b")


class KnownError(Exception):
    """A known-differences file or an issue state that can't be used."""


def load(path=KNOWN):
    """The entries of the known-differences file, or an empty list if the branch has none."""
    if not os.path.exists(path):
        return []
    try:
        with open(path, encoding="utf-8") as f:
            entries = json.load(f)
    except json.JSONDecodeError as error:
        raise KnownError(f"{path} isn't valid JSON: {error}") from error
    if not isinstance(entries, list):
        raise KnownError(f"{path} must hold a list of entries")
    return entries


def check_kinds(entries):
    """The errors in the entries' kinds: each is pending or accepted, and says what that kind needs."""
    errors = []
    for number, entry in enumerate(entries, start=1):
        kind = entry.get("kind")
        if kind not in KINDS:
            errors.append(f"known difference {number} has kind {kind!r}, not one of {', '.join(KINDS)}")
        elif kind == "pending" and not (entry.get("issues") and all(isinstance(n, int) for n in entry["issues"])):
            errors.append(f"known difference {number} is pending, so it must cite the open issues that fix it")
        elif kind == "accepted" and not APPROVAL.search(entry.get("approved") or ""):
            errors.append(f"known difference {number} is accepted, so `approved` must name the maintainer and the date")
    return errors


def fetch_issue(repo, number):
    """{state, milestone} of an issue, read with gh and GH_TOKEN. Raises KnownError if it can't be read."""
    result = subprocess.run(["gh", "api", f"repos/{repo}/issues/{number}", "--jq",
                             "{state: .state, milestone: (.milestone.title // null)}"],
                            capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise KnownError(f"Can't read the state of issue #{number}: {result.stderr.strip() or 'gh failed'}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise KnownError(f"Can't read the state of issue #{number}: gh printed {result.stdout!r}") from error


def pending_issues(entries):
    """Each (entry number, issue number) that a pending entry cites."""
    return [(number, issue) for number, entry in enumerate(entries, start=1) if entry.get("kind") == "pending"
            for issue in entry.get("issues", [])]


def stale(entries, fetch):
    """The errors for the pending entries that cite a closed issue. `fetch(number)` gives {state, milestone}."""
    errors = []
    for number, issue in pending_issues(entries):
        if str(fetch(issue).get("state")).lower() == "closed":
            errors.append(f"known difference {number} is pending #{issue}, which is closed. A fix removes its own "
                          f"entry: remove the entry, or make it accepted if a maintainer approves the limit.")
    return errors


def release_blockers(entries, fetch, version):
    """The errors for the pending entries that cite an issue open in the milestone named `version`."""
    errors = []
    for number, issue in pending_issues(entries):
        info = fetch(issue)
        if str(info.get("state")).lower() == "open" and info.get("milestone") == version:
            errors.append(f"known difference {number} is pending #{issue}, which is open in the {version} milestone. "
                          f"Release {version} after the issue's fix removes the entry, or after a maintainer approves "
                          f"the entry as accepted.")
    return errors


def main(argv):
    repo = os.environ.get("GITHUB_REPOSITORY", "cucumberswift/CucumberSwift")
    try:
        if len(argv) == 2 and argv[1] == "stale":
            entries = load()
            errors = check_kinds(entries) + stale(entries, lambda n: fetch_issue(repo, n))
        elif len(argv) == 3 and argv[1] == "release":
            entries = load()
            errors = check_kinds(entries) + release_blockers(entries, lambda n: fetch_issue(repo, n), argv[2])
        else:
            print("usage: parity_known.py stale | release <version>", file=sys.stderr)
            return 2
    except KnownError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(f"error: {error}", file=sys.stderr)
    if not errors:
        print(f"The {len(entries)} known differences are in order.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
