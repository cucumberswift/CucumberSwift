#!/usr/bin/env python3
"""Checks the per-scenario coverage that `bazel coverage` leaves in a test's outputs.

Usage: check_bazel_coverage.py <test.outputs folder or outputs.zip> <scenario count> <redundant scenario count>

Bazel leaves a test's undeclared outputs in bazel-testlogs/<target>/test.outputs/, zipped as outputs.zip
or, as on macOS, as plain files. CucumberSwift writes its coverage into them under Bazel: a run folder with manifest.json, and one raw profile for each
scenario and binary. The check fails unless every scenario has a non-empty profile, the run has
scores and no problem, and the feature's redundancy score is above 0 with exactly the expected number of
scenarios that add no coverage of their own.
"""

import json
import os
import sys
import zipfile


class Outputs:
    """The files of a test's outputs: a folder, or a zip of one. Names are relative to it."""

    def __init__(self, path):
        self.path = path
        self.archive = zipfile.ZipFile(path) if os.path.isfile(path) else None

    def names(self):
        if self.archive:
            return self.archive.namelist()
        return [os.path.relpath(os.path.join(root, name), self.path)
                for root, _, files in os.walk(self.path) for name in files]

    def read(self, name):
        if self.archive:
            return self.archive.read(name)
        with open(os.path.join(self.path, name), "rb") as file:
            return file.read()

    def size(self, name):
        if self.archive:
            return self.archive.getinfo(name).file_size
        return os.path.getsize(os.path.join(self.path, name))


def check(path, scenario_count, redundant_count):
    """Returns the problems with the coverage in the outputs at `path`, none when it is right."""
    outputs = Outputs(path)
    names = outputs.names()
    manifests = [name for name in names if name.endswith("/manifest.json") and "_cucumberCoverage/run-" in name]
    if len(manifests) != 1:
        return [f"expected one coverage manifest, found {len(manifests)} in {sorted(names)}"]
    manifest = json.loads(outputs.read(manifests[0]))
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
    for feature in manifest.get("features", []):
        scores = feature.get("scores", {})
        if not (scores.get("redundancy") or 0) > 0:
            problems.append(f"{feature.get('featureName')} has redundancy {scores.get('redundancy')}, expected above 0")
        adding_nothing = [one["name"] for one in scores.get("scenarios", []) if one.get("addsNothing")]
        if len(adding_nothing) != redundant_count:
            problems.append(f"expected {redundant_count} scenarios that add nothing, found {adding_nothing}")
    for scenario in scenarios:
        profiles = scenario.get("profiles", [])
        if not profiles:
            problems.append(f"{scenario['name']} has no profile")
        for profile in profiles:
            name = f"{folder}/{profile}"
            if name not in names or outputs.size(name) == 0:
                problems.append(f"{scenario['name']}'s profile {profile} is missing or empty")
    return problems


def main(arguments):
    if len(arguments) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    problems = check(arguments[0], int(arguments[1]), int(arguments[2]))
    for problem in problems:
        print(f"::error::{problem}")
    if not problems:
        print(f"Every one of {arguments[1]} scenarios has a coverage profile, and the run has coverage and redundancy scores.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
