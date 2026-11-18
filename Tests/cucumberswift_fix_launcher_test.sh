#!/bin/bash
# Runs the launcher that cucumberswift_fix_feature_files makes, as `bazel run` does: it fixes the feature
# files in the source tree (BUILD_WORKSPACE_DIRECTORY), not the copies in the sandbox. $1 is the launcher, which changes to
# the Tests package folder first, so the fixture lives in $work/Tests.

set -euo pipefail

launcher="$1"
work="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/launcher_test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/Tests/Features"
printf 'Feature: Greeting\n  Scenario: Say hello\n    Giben a greeting\n    Whn it is said\n' > "$work/Tests/Features/Greeting.feature"

export RUNFILES_DIR="${TEST_SRCDIR:?}"
BUILD_WORKSPACE_DIRECTORY="$work" "$launcher" > "$work/out"
for fixed in "    Given a greeting" "    When it is said"; do
  grep -qxF "$fixed" "$work/Tests/Features/Greeting.feature" || { echo "FAIL: '$fixed' was not fixed: $(cat "$work/out")" >&2; exit 1; }
done

status=0
env -u BUILD_WORKSPACE_DIRECTORY "$launcher" > /dev/null 2>&1 || status=$?
[[ "$status" != 0 ]] || { echo "FAIL: the launcher ran outside bazel run" >&2; exit 1; }
echo "PASS"
