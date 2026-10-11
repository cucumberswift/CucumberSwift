#!/usr/bin/env python3
"""Build the parallel tests' matrix for a CI run.

CI.yml runs this in its `changes` job. The parallel tests run each combination of
an Xcode version (16 or 26), a platform (iOS, tvOS, macOS or Catalyst) and a kind
(hostless, hosted or UI). Which combinations run depends on the event:

  pull_request       the hosted tests on each platform, with Xcode 26;
  push               every combination with Xcode 26, and iOS and Catalyst with
                     Xcode 16 too;
  schedule and       every combination with both Xcode versions.
  workflow_dispatch

Xcode 26's macOS hostless combination is never in the matrix: the parallel_smoke
job runs it first, and the others wait for it. So the script also says whether
that job runs: always when the matrix runs at all, except on a manual run whose
inputs leave it out.

A manual run (workflow_dispatch) can narrow its combinations with three inputs:

  parallel_platforms  `all`, or a comma-separated list of platforms;
  parallel_kinds      `all`, or a comma-separated list of kinds;
  parallel_xcode      `all`, `16` or `26`.

Names match in any case, and an empty input means `all`. A combination the event
leaves out stays out. Any other event ignores the inputs. An unknown name fails
with an error naming it and the names that are allowed.

Run from the repository root, in a GitHub Actions job:

  python3 .github/scripts/parallel_matrix.py

It reads GITHUB_EVENT_NAME and the inputs from PARALLEL_PLATFORMS, PARALLEL_KINDS
and PARALLEL_XCODE, prints the combinations, and writes to GITHUB_OUTPUT
`parallel_matrix`, a JSON list of {"xcode", "platform", "kind"} objects for the
parallel_tests job's matrix (`[]` when none), and `parallel_smoke`, `true` or
`false`. It exits non-zero on an unknown name or when it cannot write them.

Only the standard library is used.
"""
import json
import os
import sys

# In the order the check names list them. These values are what the check names
# show; CI.yml's steps turn them into what parallel-fixture.sh takes.
XCODES = ("16", "26")
PLATFORMS = ("iOS", "tvOS", "macOS", "Catalyst")
KINDS = ("hostless", "hosted", "UI")
# The combination parallel_smoke runs.
SMOKE = {"xcode": "26", "platform": "macOS", "kind": "hostless"}
FULL_EVENTS = {"schedule", "workflow_dispatch"}


class InputError(Exception):
    """An input names something that does not exist."""


def selected(value, allowed, name):
    """The names a comma-separated input selects, as a set."""
    value = (value or "").strip()
    if not value or value.lower() == "all":
        return set(allowed)
    by_lower = {item.lower(): item for item in allowed}
    chosen = set()
    for part in value.split(","):
        part = part.strip()
        if part.lower() not in by_lower:
            raise InputError(
                f"{name} has '{part}', which is not one of: all, {', '.join(allowed)}."
            )
        chosen.add(by_lower[part.lower()])
    return chosen


def runs_for_event(event, combination):
    """Whether the event runs the combination, before any input narrows it."""
    if event == "pull_request":
        return combination["xcode"] == "26" and combination["kind"] == "hosted"
    if event in FULL_EVENTS:
        return True
    # Pushes to main and support/N.x leave out Xcode 16's tvOS and macOS.
    return combination["xcode"] == "26" or combination["platform"] in ("iOS", "Catalyst")


def build(event, platforms="", kinds="", xcode=""):
    """The parallel_tests matrix and whether parallel_smoke runs."""
    if event == "workflow_dispatch":
        chosen_platforms = selected(platforms, PLATFORMS, "parallel_platforms")
        chosen_kinds = selected(kinds, KINDS, "parallel_kinds")
        chosen_xcodes = selected(xcode, XCODES, "parallel_xcode")
    else:
        chosen_platforms, chosen_kinds, chosen_xcodes = set(PLATFORMS), set(KINDS), set(XCODES)
    combinations = [
        {"xcode": x, "platform": p, "kind": k}
        for x in XCODES if x in chosen_xcodes
        for p in PLATFORMS if p in chosen_platforms
        for k in KINDS if k in chosen_kinds
    ]
    smoke = SMOKE in combinations or event != "workflow_dispatch"
    matrix = [c for c in combinations if c != SMOKE and runs_for_event(event, c)]
    return matrix, smoke


def main():
    event = os.environ.get("GITHUB_EVENT_NAME", "")
    try:
        matrix, smoke = build(
            event,
            os.environ.get("PARALLEL_PLATFORMS", ""),
            os.environ.get("PARALLEL_KINDS", ""),
            os.environ.get("PARALLEL_XCODE", ""),
        )
    except InputError as error:
        print(f"::error::{error}")
        return 1
    print(f"Parallel tests (macOS, hostless) runs first: {'yes' if smoke else 'no'}")
    print(f"Then {len(matrix)} combinations:")
    for c in matrix:
        print(f"  {c['platform']}, {c['kind']}, Xcode {c['xcode']}")
    output = os.environ.get("GITHUB_OUTPUT")
    if not output:
        print("::error::GITHUB_OUTPUT is not set.")
        return 1
    with open(output, "a", encoding="utf-8") as handle:
        handle.write(f"parallel_matrix={json.dumps(matrix, separators=(',', ':'))}\n")
        handle.write(f"parallel_smoke={'true' if smoke else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
