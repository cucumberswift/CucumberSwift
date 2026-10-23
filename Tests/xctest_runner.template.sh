#!/bin/bash
# Runs a macos_unit_test's bundle with `xcrun xctest`, or a watchos_unit_test's
# with the watchOS simulator's xctest, on a simulator made for the run.
# rules_apple fills in the %(name)s values when it builds the test, and the
# runner rule fills in the platform; see xctest_runner.bzl.

set -euo pipefail

test_type="%(test_type)s"
test_host_path="%(test_host_path)s"
bundle_path="%(test_bundle_path)s"
test_filter="%(test_filter)s"
platform="__PLATFORM__"

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
simulator=""
cleanup() {
  if [[ -n "$simulator" ]]; then
    xcrun simctl shutdown "$simulator" > /dev/null 2>&1 || true
    xcrun simctl delete "$simulator" > /dev/null 2>&1 || true
  fi
  rm -rf "$test_dir"
}
trap cleanup EXIT
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

# Bazel sets DEVELOPER_DIR to the Xcode it selected (see xctest_runner.bzl), and
# xcrun runs that Xcode's xctest. Say which, for anyone reading the test log.
developer_dir="${DEVELOPER_DIR:-$(xcode-select -p)}"
echo "Running xctest from $developer_dir"

# rules_apple's watchOS runner runs no tests, so a watchOS bundle runs here: on a
# new simulator with that platform's xctest. The simulator runs the newest
# watchOS that is not newer than the selected Xcode's watchOS SDK, or the newest
# installed if every one is newer. simctl passes a variable to the process it spawns only with a
# SIMCTL_CHILD_ prefix, so the test environment is passed on that way, but for
# the variables that describe this Mac rather than the simulator.
if [[ "$platform" == "watchos" ]]; then
  # JavaScript for Automation reads the JSON: it comes with macOS, and doesn't depend on Xcode
  # as /usr/bin/python3 does.
  runtime_and_type="$(osascript -l JavaScript -e '
    function run(argv) {
      const version = (r) => r.version.split(".").map(Number);
      const newer = (a, b) => {
        for (let i = 0; i < Math.max(a.length, b.length); i++) {
          if ((a[i] || 0) !== (b[i] || 0)) return (a[i] || 0) > (b[i] || 0);
        }
        return false;
      };
      const sdk = argv[1].split(".").map(Number);
      let newest = null;
      let newestForSDK = null;
      for (const r of JSON.parse(argv[0]).runtimes) {
        if (r.platform !== "watchOS" || !r.isAvailable || !(r.supportedDeviceTypes || []).length) continue;
        if (!newest || newer(version(r), version(newest))) newest = r;
        if (!newer(version(r), sdk) && (!newestForSDK || newer(version(r), version(newestForSDK)))) newestForSDK = r;
      }
      const chosen = newestForSDK || newest;
      return chosen ? chosen.identifier + " " + chosen.supportedDeviceTypes.slice(-1)[0].identifier : "";
    }' "$(xcrun simctl list --json runtimes)" "$(xcrun --sdk watchsimulator --show-sdk-version)")"
  if [[ -z "$runtime_and_type" ]]; then
    echo "error: no watchOS simulator runtime is installed. Install one with: xcodebuild -downloadPlatform watchOS" >&2
    exit 1
  fi
  runtime="${runtime_and_type%% *}"
  simulator="$(xcrun simctl create "bazel-xctest-$$" "${runtime_and_type#* }" "$runtime")"
  echo "Running on a new watchOS simulator, $simulator ($runtime)"
  xcrun simctl boot "$simulator"
  xcrun simctl bootstatus "$simulator" > /dev/null
  while IFS= read -r -d '' entry; do
    name="${entry%%=*}"
    case "$name" in
      PATH | HOME | TMPDIR | PWD | OLDPWD | SHLVL | _ | DYLD_* | SIMCTL_CHILD_*) continue ;;
    esac
    if [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      export "SIMCTL_CHILD_$name=${entry#*=}"
    fi
  done < <(env -0)
fi

run_xctest() {
  if [[ -n "$simulator" ]]; then
    xcrun simctl spawn "$simulator" \
      "$developer_dir/Platforms/WatchSimulator.platform/Developer/Library/Xcode/Agents/xctest" "$@"
  else
    xcrun xctest "$@"
  fi
}

log="$test_dir/test.log"
status=0
run_xctest "${args[@]+"${args[@]}"}" "$test_dir/$bundle_name.xctest" 2>&1 | tee "$log" || status=$?

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
