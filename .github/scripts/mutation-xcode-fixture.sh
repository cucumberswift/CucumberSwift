#!/usr/bin/env bash
# Runs mutation testing on Fixtures/MutationTestingTuist, an Xcode project, as a project would: from the Run Script
# build phase of the fixture's Mutation target, where the command runs `xcodebuild` with a scheme and a destination
# and prints each surviving mutant as a warning. The run must find the mutants, and kill and keep the ones, that the
# fixture's expected-mutants lists, and the build log must warn at each survivor (.github/scripts/mutation_fixture.py).
# It then runs XcodebuildRunnerFixtureTests, which selects one scenario of each test runner with xcodebuild.
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

# The same project, one scenario at a time: the runner selects an XCTest scenario and a Swift Testing scenario with
# the test names that ScenarioTestNames makes, and each run ran exactly that scenario. The tests skip without the
# folder, and a skipped test or a filter that matches nothing exits with success, so the output must show tests that ran.
selection_log="$(cd "$dir" && pwd -P)/mutation-$name-selection.log"
MUTATION_XCODE_FIXTURE="$project" .github/scripts/keep-package-resolved.sh \
  swift test --enable-all-traits --filter XcodebuildRunnerFixtureTests 2>&1 | tee "$selection_log"
if ! grep -Eq 'Executed [1-9][0-9]* tests?, with 0 failures' "$selection_log" || grep -Eq '[1-9][0-9]* tests? skipped' "$selection_log"; then
  echo "error: $name: XcodebuildRunnerFixtureTests did not run, or skipped a test" >&2
  exit 1
fi
