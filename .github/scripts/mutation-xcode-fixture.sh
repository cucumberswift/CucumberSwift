#!/usr/bin/env bash
# Runs mutation testing on Fixtures/MutationTestingTuist, an Xcode project, as a project would: with `xcodebuild`,
# a scheme and a destination. The run must find the mutants, and kill and keep the ones, that the fixture's
# expected-mutants lists (.github/scripts/mutation_fixture.py).
# Used by CI's Fixture tests, after `mise run test-fixtures`.
#
#   .github/scripts/mutation-xcode-fixture.sh <directory>
#
# The fixture's own path to this checkout doesn't reach it from another folder, so the run uses a copy of the
# fixture's files in <directory>, which depends on CucumberSwift by URL, as a project does: a git repository of the
# checked-out commit, tagged 999.0.0, in <directory>, which the fixture's Project.swift reads from TUIST_CUCUMBERSWIFT.
# The copy has no project or build products from `mise run test-fixtures`, which the run would copy and hash twice.
# The reports go to <directory>/mutation-MutationTestingTuist. The fixture in this checkout stays as it is.
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

# The Macros trait, because the tool finds the mutants with swift-syntax. Resolving rewrites this checkout's
# Package.resolved, so the step puts it back.
status=0
.github/scripts/keep-package-resolved.sh swift run --traits Macros CucumberSwiftMutationTestingTool \
  --root "$project" \
  --project "$name.xcodeproj" \
  --scheme "$name" \
  --destination "platform=macOS" \
  --output "$reports" \
  --baseline-runs 1 \
  --minimum-timeout 120 || status=$?
if [ "$status" -ne 0 ]; then
  echo "error: $name: mutation testing exited with status $status"
  exit "$status"
fi
python3 .github/scripts/mutation_fixture.py "$fixture" "$reports"
