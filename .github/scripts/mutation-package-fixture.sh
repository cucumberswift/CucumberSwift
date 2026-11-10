#!/bin/bash
# Runs mutation testing on Fixtures/MutationTestingPackage with the command-line tool, as a Swift package's
# script or build server would, and checks the result against the fixture's expected-mutants (#519):
#
#     .github/scripts/mutation-package-fixture.sh [<folder for the reports and the log>]
#
# `swift run cucumberswift-mutation-test --format xcode` tests the package's XCTest and Swift Testing targets
# against each mutant. .github/scripts/mutation_fixture.py then fails unless every mutant has the status that
# expected-mutants lists, and the output has a warning for each survivor. The tool copies the package to a
# temporary folder, so CUCUMBER_SWIFT_PATH gives the fixture's Package.swift the checkout's absolute path.
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
fixture="$repo/Fixtures/MutationTestingPackage"
folder="${1:-${RUNNER_TEMP:-$(mktemp -d)}}"
reports="$folder/mutation-MutationTestingPackage"
log="$folder/mutation-MutationTestingPackage.log"
rm -rf "$reports"

export CUCUMBER_SWIFT_PATH="$repo"
status=0
(cd "$fixture" && swift run cucumberswift-mutation-test --format xcode --baseline-runs 1 --output "$reports") 2>&1 | tee "$log" || status=$?
if [[ "$status" -ne 0 ]]; then
  echo "::error::MutationTestingPackage: cucumberswift-mutation-test exited with $status"
  exit 1
fi
cd "$repo"
python3 .github/scripts/mutation_fixture.py "$fixture" "$reports" "$log"

# Both runners' scenarios must be in each run's Cucumber report: the XCTest target's (Voting) and the
# Swift Testing target's (Retiring). Each killed mutant then names the scenarios that failed on it.
python3 -I - "$reports" <<'PYTHON'
import json, os, sys

reports = sys.argv[1]
with open(os.path.join(reports, "cucumber-baseline.json"), encoding="utf-8") as f:
    features = sorted(feature["name"] for feature in json.load(f))
if features != ["Retiring", "Voting"]:
    sys.exit(f"::error::MutationTestingPackage: the baseline report has the features {features}, not Retiring and Voting")
with open(os.path.join(reports, "mutation-report.json"), encoding="utf-8") as f:
    report = json.load(f)
for name, entry in report["files"].items():
    for mutant in entry["mutants"]:
        if mutant["status"] == "Killed" and not mutant.get("killedBy"):
            line = mutant["location"]["start"]["line"]
            sys.exit(f"::error::MutationTestingPackage: no scenario is named as killing the mutant at {name}:{line}")
print("MutationTestingPackage: each run's report has both runners' scenarios.")
PYTHON
