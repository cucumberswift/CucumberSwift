#!/bin/bash
# Runs a macos_unit_test's bundle with `xcrun xctest`. rules_apple fills in the
# %(name)s values when it builds the test; see xctest_runner.bzl.

set -euo pipefail

test_type="%(test_type)s"
test_host_path="%(test_host_path)s"
bundle_path="%(test_bundle_path)s"
test_filter="%(test_filter)s"

if [[ -n "${TEST_PREMATURE_EXIT_FILE:-}" ]]; then
  touch "$TEST_PREMATURE_EXIT_FILE"
fi

if [[ "$test_type" != "XCTEST" ]]; then
  echo "error: this runner only runs unit tests, not $test_type." >&2
  exit 1
fi
if [[ -n "$test_host_path" ]]; then
  echo "error: this runner does not support a test host." >&2
  exit 1
fi
if [[ "${COVERAGE:-}" == 1 ]]; then
  echo "error: this runner does not collect coverage." >&2
  exit 1
fi

# The bundle is a zip, or an .xctest folder with --define=apple.experimental.tree_artifact_outputs=1.
# Copy it either way, because Bazel's outputs are read-only.
test_dir="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/xctest.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
bundle_name="$(basename "${bundle_path%.*}")"
if [[ "$bundle_path" == *.xctest ]]; then
  cp -R "$bundle_path" "$test_dir"
else
  unzip -qq -d "$test_dir" "$bundle_path"
fi

# xctest inherits Bazel's test environment as it is: --test_env, the env
# attribute and the TEST_* variables. the test_env substitution holds the same
# values joined with commas, which can't be split back safely, so it isn't used.

# --test_filter (TESTBRIDGE_TEST_ONLY) and the test_filter attribute: a comma
# separated list of tests as xctest names them, Module.Class or
# Module.Class/method (CucumberSwift.CucumberTest runs every scenario).
filter="${TESTBRIDGE_TEST_ONLY:-}"
if [[ -n "$test_filter" ]]; then
  filter="${filter:+$filter,}$test_filter"
fi
args=()
if [[ -n "$filter" ]]; then
  if [[ ",$filter" == *,-* ]]; then
    echo "error: this runner cannot skip tests; xctest only selects them. Filter: $filter" >&2
    exit 1
  fi
  args+=(-XCTest "$filter")
fi

log="$test_dir/test.log"
status=0
xcrun xctest "${args[@]+"${args[@]}"}" "$test_dir/$bundle_name.xctest" 2>&1 | tee "$log" || status=$?

if [[ "$status" -ne 0 ]]; then
  echo "error: xctest exited with $status" >&2
  exit "$status"
fi

# xctest passes when the bundle has no tests; treat that as a failure.
summary="$(grep -E 'Executed [0-9]+ tests?,' "$log" | tail -1 || true)"
if [[ -z "$summary" || "$summary" == *"Executed 0 tests"* ]]; then
  echo "error: no tests ran. Is the test bundle empty, or does the filter match nothing?" >&2
  echo "Last xctest summary: ${summary:-none}" >&2
  exit 1
fi

if [[ -n "${TEST_PREMATURE_EXIT_FILE:-}" ]]; then
  rm -f "$TEST_PREMATURE_EXIT_FILE"
fi
