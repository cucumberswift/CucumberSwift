#!/usr/bin/env python3
"""Checks the per-scenario coverage that `bazel coverage` leaves in a test's outputs.

Usage: check_bazel_coverage.py <outputs.zip> <scenario count>

The zip is bazel-testlogs/<target>/test.outputs/outputs.zip. CucumberSwift writes its coverage into the
test's undeclared outputs under Bazel: a run folder with manifest.json, and one raw profile for each
scenario and binary. The check fails unless every scenario has a non-empty profile, and the run has
scores and no problem.
"""

import json
import sys
import zipfile


def check(path, scenario_count):
    """Returns the problems with the coverage in the zip at `path`, none when it is right."""
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        manifests = [name for name in names if name.endswith("/manifest.json") and "_cucumberCoverage/run-" in name]
        if len(manifests) != 1:
            return [f"expected one coverage manifest, found {len(manifests)} in {sorted(names)}"]
        manifest = json.loads(archive.read(manifests[0]))
        folder = manifests[0].rsplit("/", 1)[0]
        problems = []
        for key in ("problem", "scoresProblem"):
            if manifest.get(key):
                problems.append(f"the manifest's {key}: {manifest[key]}")
        scenarios = manifest.get("scenarios", [])
        if len(scenarios) != scenario_count:
            problems.append(f"expected {scenario_count} scenarios, the manifest has {len(scenarios)}")
        if not manifest.get("binaries"):
            problems.append("the manifest lists no binary built with coverage")
        if not manifest.get("features"):
            problems.append("the manifest has no feature scores")
        for scenario in scenarios:
            profiles = scenario.get("profiles", [])
            if not profiles:
                problems.append(f"{scenario['name']} has no profile")
            for profile in profiles:
                name = f"{folder}/{profile}"
                if name not in names or archive.getinfo(name).file_size == 0:
                    problems.append(f"{scenario['name']}'s profile {profile} is missing or empty")
        return problems


def main(arguments):
    if len(arguments) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    problems = check(arguments[0], int(arguments[1]))
    for problem in problems:
        print(f"::error::{problem}")
    if not problems:
        print(f"Every one of {arguments[1]} scenarios has a coverage profile, and the run has scores.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
