#!/bin/bash
# Runs the launcher that cucumberswift_fix_feature_files makes, as `bazel run` does: it fixes the feature
# files in the source tree (BUILD_WORKSPACE_DIRECTORY), not the copies in the sandbox. $1 is the launcher.

set -euo pipefail

launcher="$1"
work="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/launcher_test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

mkdir "$work/Features"
printf 'Feature: Greeting\n  Scenario: Say hello\n    Giben a greeting\n' > "$work/Features/Greeting.feature"

export RUNFILES_DIR="${TEST_SRCDIR:?}"
BUILD_WORKSPACE_DIRECTORY="$work" "$launcher" > "$work/out"
grep -q "^    Given a greeting$" "$work/Features/Greeting.feature" || { echo "FAIL: Giben was not fixed: $(cat "$work/out")" >&2; exit 1; }

status=0
env -u BUILD_WORKSPACE_DIRECTORY "$launcher" > /dev/null 2>&1 || status=$?
[[ "$status" != 0 ]] || { echo "FAIL: the launcher ran outside bazel run" >&2; exit 1; }
echo "PASS"
