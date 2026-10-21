#!/usr/bin/env bash
# Runs the root package's Swift Testing tests with Swift 6.3 or later, where the Swift Testing runner
# reports a skipped scenario case with `Test.cancel` (#480). Fails if the toolchain is older, if the
# run doesn't reach its summary or runs fewer tests than expected, or if any test was cancelled: a
# test that calls the runner itself must not end cancelled, because that hides whether it passed.
#
#   .github/scripts/swift-testing-unit-tests.sh <fewest tests> <output file>
#
# Used by CI's Fixture tests job, whose runner image has Swift 6.3; SwiftPM tests runs the same tests
# with the oldest Swift supported.
set -euo pipefail

min=${1:?usage: swift-testing-unit-tests.sh <fewest tests> <output file>}
log=${2:?usage: swift-testing-unit-tests.sh <fewest tests> <output file>}

version=$(swift --version 2>&1 | grep -oE 'Swift version [0-9]+\.[0-9]+' | head -1 | grep -oE '[0-9]+\.[0-9]+' || true)
major=${version%%.*}
minor=${version#*.}
if [[ -z "$version" ]] || (( major < 6 || (major == 6 && minor < 3) )); then
  echo "::error::These tests need Swift 6.3 or later; the toolchain is Swift ${version:-unknown}."
  exit 1
fi

swift test --enable-all-traits --disable-xctest 2>&1 | tee "$log"

total=$(grep -oE 'Test run with [0-9]+ tests' "$log" | tail -1 | grep -oE '[0-9]+' || true)
echo "Swift Testing tests run with Swift $version: ${total:-0} (at least $min expected)"
if [[ "${total:-0}" -lt "$min" ]]; then
  echo "::error::Only ${total:-0} Swift Testing tests ran with Swift $version; at least $min were expected."
  exit 1
fi

cancelled=$(grep -E 'Test .* was cancelled' "$log" || true)
if [[ -n "$cancelled" ]]; then
  echo "::error::Tests ended cancelled with Swift $version, so whether they passed isn't known:"
  echo "$cancelled"
  exit 1
fi
