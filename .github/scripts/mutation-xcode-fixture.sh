#!/usr/bin/env bash
# Runs mutation testing on Fixtures/MutationTestingTuist, an Xcode project, as a project would: from the Run Script
# build phase of the fixture's Mutation target, where the command runs `xcodebuild` with a scheme and a destination
# and prints each surviving mutant as a warning. The run must find the mutants, and kill and keep the ones, that the
# fixture's expected-mutants lists, and the build log must warn at each survivor (.github/scripts/mutation_fixture.py).
# Used by CI's Fixture tests, after `mise run test-fixtures`.
#
#   .github/scripts/mutation-xcode-fixture.sh <directory>
#
# The fixture's own path to this checkout doesn't reach it from another folder, so the run uses a copy of the
# fixture's files in <directory>, which depends on CucumberSwift by URL, as a project does: a git repository of the
# checked-out commit, tagged 999.0.0, in <directory>, which the fixture's Project.swift reads from TUIST_CUCUMBERSWIFT.
# The copy has no project or build products from `mise run test-fixtures`, which the run would copy and hash twice.
# The reports go to <directory>/mutation-MutationTestingTuist and the build log to
# <directory>/mutation-MutationTestingTuist-build.log. The fixture in this checkout stays as it is.
set -euo pipefail

dir=${1:?usage: mutation-xcode-fixture.sh <directory>}
name=MutationTestingTuist
fixture=Fixtures/$name
repo="$(cd "$dir" && pwd -P)/CucumberSwift.git"
project="$(cd "$dir" && pwd -P)/$name"
reports="$(cd "$dir" && pwd -P)/mutation-$name"
version=999.0.0

# A local clone copies every object, so the commit is there even when the checkout is shallow and detached.
rm -rf "$repo" "$reports" "$project"
git clone --quiet --bare . "$repo"
git -C "$repo" tag "$version" "$(git rev-parse HEAD)"
export TUIST_CUCUMBERSWIFT="file://$repo"

mkdir -p "$project"
rsync -a --exclude Derived --exclude .build --exclude '*.xcodeproj' --exclude '*.xcworkspace' "$fixture/" "$project/"
mise exec -- tuist generate --no-open --path "$project"

# Mutation testing runs from the Run Script build phase of the fixture's Mutation target, as a project runs it to see
# the surviving mutants as warnings in Xcode. The phase runs the command from this checkout, so it needs the Macros
# trait, which the tool needs to read Swift code with swift-syntax. Resolving rewrites this checkout's Package.resolved,
# so the step puts it back. The build log has the command's output, with each survivor as a warning.
export CUCUMBERSWIFT_CHECKOUT="$PWD"
export MUTATION_REPORTS="$reports"
log="$(cd "$dir" && pwd -P)/mutation-$name-build.log"
status=0
.github/scripts/keep-package-resolved.sh xcodebuild build \
  -project "$project/$name.xcodeproj" \
  -scheme Mutation \
  -destination "platform=macOS" \
  -derivedDataPath "$(cd "$dir" && pwd -P)/mutation-$name-build" \
  -skipMacroValidation -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$log" || status=${PIPESTATUS[0]}
if [[ "$status" -ne 0 ]]; then
  echo "error: $name: the build with the mutation testing phase exited with status $status" >&2
  exit "$status"
fi
python3 .github/scripts/mutation_fixture.py "$fixture" "$reports" "$log"

# Both runners' scenarios must be in each run's Cucumber report: the XCTest target's (Voting) and the Swift Testing
# target's (Retiring). Each killed mutant then names the scenarios that failed on it.
python3 -I - "$reports" <<'PYTHON'
import json, os, sys

reports = sys.argv[1]
with open(os.path.join(reports, "cucumber-baseline.json"), encoding="utf-8") as f:
    features = {feature["name"] for feature in json.load(f)}
if not {"Retiring", "Voting"} <= features:
    sys.exit(f"::error::MutationTestingTuist: the baseline report has the features {sorted(features)}, not Retiring and Voting")
with open(os.path.join(reports, "mutation-report.json"), encoding="utf-8") as f:
    report = json.load(f)
for name, entry in report["files"].items():
    for mutant in entry["mutants"]:
        if mutant["status"] == "Killed" and not mutant.get("killedBy"):
            line = mutant["location"]["start"]["line"]
            sys.exit(f"::error::MutationTestingTuist: no scenario is named as killing the mutant at {name}:{line}")
print("MutationTestingTuist: each run's report has both runners' scenarios.")
PYTHON
