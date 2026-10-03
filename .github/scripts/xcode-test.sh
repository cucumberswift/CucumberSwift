#!/usr/bin/env bash
# Runs the CucumberSwift scheme's tests with xcodebuild, as CONTRIBUTING.md gives
# the command, and checks that they all ran. CI's test jobs and the Release
# workflow's test job run it.
#
#   .github/scripts/xcode-test.sh <xcodebuild arguments>
#
# The arguments follow `xcodebuild test -scheme CucumberSwift`, for example
# -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGNING_ALLOWED=NO.
# The full xcodebuild output goes to xcode-test.log in the working directory.
#
# A test that silently stops running still reports success (#231), so this also
# fails when:
#   - fewer tests ran than MIN_TESTS, counted from the log, not the .xcresult,
#     which merges suites that share a name;
#   - a test bundle ran in parallel, which skips every Cucumber scenario.
#
# Environment:
#   MIN_TESTS  the fewest tests the scheme's test bundles may run together
set -u

if [ -z "${MIN_TESTS:-}" ]; then
  echo "::error::Set MIN_TESTS to the number of tests the CucumberSwift scheme runs."
  exit 1
fi

log=xcode-test.log
xcodebuild test -scheme CucumberSwift "$@" > "$log" 2>&1
status=$?

grep -E "Test Suite '.*\.(xctest|framework)' (passed|failed)" -A1 "$log" | grep -E 'Executed' | sort -u
grep -E ': error: -\[' "$log" | sed -E 's|^.*/Resources/||' | sort -u | head -20
# A failure before any test runs (a bad destination, a build error)
# prints no counts, so show xcodebuild's own errors too.
grep -E -A4 'xcodebuild: error|\*\* (BUILD|TEST) FAILED' "$log" | head -30

# Each bundle runs in a process of its own, which ends with one
# "All tests" or "Selected tests" total.
totals=$(grep -E "^Test Suite '(All|Selected) tests' (passed|failed)" -A1 "$log" | grep -oE 'Executed [0-9]+' | grep -oE '[0-9]+')
total=$(( $(echo "$totals" | paste -sd+ -) + 0 ))
echo "Tests run by each bundle: $(echo "$totals" | paste -sd' ' -), $total in all (at least $MIN_TESTS expected)"

# XCTest never hands CucumberSwift's generated scenario tests to a parallel
# worker, so a parallel bundle drops them (#231). Only a parallel run prints
# "Test suite '…' started on '<device>'".
if grep -qE "^Test suite '.*' started on '" "$log"; then
  echo "::error::A test bundle ran in parallel, which skips every Cucumber scenario. Do not mark a target parallelizable in CucumberSwift.xctestplan."
  status=1
fi
if [ "$status" -eq 0 ] && [ "$total" -lt "$MIN_TESTS" ]; then
  echo "::error::Only $total tests ran; at least $MIN_TESTS were expected. If you removed tests on purpose, lower MIN_TESTS in CI.yml."
  status=1
fi
exit $status
