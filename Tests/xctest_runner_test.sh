#!/bin/bash
# Tests bazel/xctest_runner.template.sh with a stand-in for `xcrun xctest` and
# `xcrun simctl`, so no real tests run and no simulator is made. Each case fills in the template as rules_apple does and checks
# what the runner passes to xctest and how it exits.

set -euo pipefail

template="$1"
work="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/runner_test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# A stand-in for xcrun. For xctest, and for a process simctl spawns: records its arguments,
# PROBE and DEVELOPER_DIR (SIMCTL_CHILD_PROBE for a spawned one, which also records whether the
# variables the runner must not pass on reached it: PATH and SIMCTL_CHILD_*), prints the
# summary line xctest would print for FAKE_COUNT tests, and exits with FAKE_STATUS. Every simctl
# command goes to FAKE_SIMCTL; `simctl list` prints FAKE_RUNTIMES, and `simctl create` a device.
mkdir -p "$work/bin"
cat > "$work/bin/xcrun" <<'EOF'
#!/bin/bash
if [[ "$1" == "--sdk" ]]; then echo "$FAKE_SDK_VERSION"; exit 0; fi
if [[ "$1" == "simctl" ]]; then
  echo "${*:2}" >> "$FAKE_SIMCTL"
  if [[ "$2" == "--sdk" ]]; then echo "$FAKE_SDK_VERSION"; exit 0; fi
  case "$2" in
    list) printf '%s\n' "$FAKE_RUNTIMES"; exit 0 ;;
    create) echo "FAKE-DEVICE"; exit 0 ;;
    spawn)
      shift 3
      PROBE="${SIMCTL_CHILD_PROBE-unset}"
      printf 'PATH=%s\nNESTED=%s\n' "${SIMCTL_CHILD_PATH-unset}" "${SIMCTL_CHILD_SIMCTL_CHILD_FAKE-unset}" \
        > "$FAKE_CHILD_EXCLUDED" ;;
    *) exit 0 ;;
  esac
fi
printf '%s\n' "$@" > "$FAKE_ARGS"
printf '%s' "${PROBE-unset}" > "$FAKE_PROBE"
printf '%s' "${DEVELOPER_DIR-unset}" > "$FAKE_DEVELOPER_DIR"
printf "\t Executed %s tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds\n" "$FAKE_COUNT"
exit "$FAKE_STATUS"
EOF
chmod +x "$work/bin/xcrun"

# A bundle zipped as rules_apple zips it: Fake.xctest at the root.
mkdir -p "$work/bundle/Fake.xctest/Contents"
(cd "$work/bundle" && zip -qr "$work/Fake.zip" Fake.xctest)

# An environment value with commas and an equals sign, which must reach xctest as it is.
probe="a,b=c,d"

# The runner's bundle: the zip, unless a case sets it. The platform: macOS, unless a case sets it.
bundle="$work/Fake.zip"
platform="macos"

# What `simctl list --json runtimes` prints: three watchOS runtimes, an unavailable newer one,
# and an iOS one. The selected Xcode's watchOS SDK is FAKE_SDK_VERSION, 26.4 unless a case sets it.
runtimes='{"runtimes": [
  {"platform": "watchOS", "isAvailable": true, "version": "11.5", "identifier": "watchOS-11-5",
   "supportedDeviceTypes": [{"identifier": "Watch-Old"}]},
  {"platform": "watchOS", "isAvailable": true, "version": "26.4", "identifier": "watchOS-26-4",
   "supportedDeviceTypes": [{"identifier": "Watch-A"}, {"identifier": "Watch-B"}]},
  {"platform": "watchOS", "isAvailable": true, "version": "26.5", "identifier": "watchOS-26-5",
   "supportedDeviceTypes": [{"identifier": "Watch-C"}]},
  {"platform": "watchOS", "isAvailable": false, "version": "27.0", "identifier": "watchOS-27-0",
   "supportedDeviceTypes": [{"identifier": "Watch-New"}]},
  {"platform": "iOS", "isAvailable": true, "version": "26.4", "identifier": "iOS-26-4",
   "supportedDeviceTypes": [{"identifier": "iPhone"}]}]}'

failures=0
fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

# Writes the runner with the given test_filter attribute and runs it with the
# given environment, recording its exit status, stdout and stderr.
run() {
  local filter="$1"
  shift
  sed -e "s|%(test_type)s|XCTEST|" \
    -e "s|%(test_host_path)s||" \
    -e "s|%(test_bundle_path)s|$bundle|" \
    -e "s|%(test_filter)s|$filter|" \
    -e "s|__PLATFORM__|$platform|" \
    "$template" > "$work/runner.sh"
  rm -f "$work/simctl" "$work/child_excluded"
  status=0
  env -u TEST_PREMATURE_EXIT_FILE -u TESTBRIDGE_TEST_ONLY \
    PATH="$work/bin:$PATH" FAKE_ARGS="$work/args" FAKE_PROBE="$work/probe" FAKE_DEVELOPER_DIR="$work/developer_dir" \
    FAKE_SIMCTL="$work/simctl" FAKE_CHILD_EXCLUDED="$work/child_excluded" FAKE_RUNTIMES="$runtimes" \
    FAKE_SDK_VERSION=26.4 FAKE_COUNT=3 FAKE_STATUS=0 "$@" \
    bash "$work/runner.sh" > "$work/out" 2> "$work/err" || status=$?
}

# A passing run exits 0 and runs xctest on the unzipped bundle.
run ""
[[ "$status" -eq 0 ]] || fail "a passing run exited $status"
[[ "$(cat "$work/args")" == "xctest"$'\n'*/Fake.xctest ]] || fail "unexpected arguments: $(cat "$work/args")"

# An .xctest folder bundle (apple.experimental.tree_artifact_outputs) is copied,
# and xctest runs the copy, not Bazel's read-only output.
bundle="$work/bundle/Fake.xctest"
run ""
bundle="$work/Fake.zip"
[[ "$status" -eq 0 ]] || fail "a folder bundle run exited $status"
copied="$(sed -n 2p "$work/args")"
[[ "$copied" == */Fake.xctest ]] || fail "unexpected folder bundle arguments: $(cat "$work/args")"
[[ "$copied" != "$work/bundle/Fake.xctest" ]] || fail "xctest ran the folder bundle in place"

# An environment value keeps its commas.
run "" PROBE="$probe"
[[ "$(cat "$work/probe")" == "$probe" ]] || fail "PROBE reached xctest as '$(cat "$work/probe")'"

# The log names the Xcode Bazel selected, and xctest gets it in DEVELOPER_DIR.
run "" DEVELOPER_DIR="/Selected/Xcode.app/Contents/Developer"
grep -qx "Running xctest from /Selected/Xcode.app/Contents/Developer" "$work/out" || fail "the log doesn't name the selected Xcode: $(cat "$work/out")"
[[ "$(cat "$work/developer_dir")" == "/Selected/Xcode.app/Contents/Developer" ]] || fail "DEVELOPER_DIR reached xctest as '$(cat "$work/developer_dir")'"

# xctest's failure is the runner's failure.
run "" FAKE_STATUS=1
[[ "$status" -eq 1 ]] || fail "a failing xctest run exited $status"

# A run with no tests fails and shows xctest's last summary line.
run "" FAKE_COUNT=0
[[ "$status" -ne 0 ]] || fail "a run with no tests passed"
grep -q "no tests ran" "$work/err" || fail "no 'no tests ran' error"
grep -q "Last xctest summary:.*Executed 0 tests" "$work/err" || fail "the summary line is missing: $(cat "$work/err")"

# --test_filter and the test_filter attribute go to xctest together.
run "Mod.B" TESTBRIDGE_TEST_ONLY="Mod.A/testOne"
[[ "$(sed -n 2,3p "$work/args")" == "-XCTest"$'\n'"Mod.A/testOne,Mod.B" ]] || fail "unexpected filter: $(cat "$work/args")"

# A skip filter is rejected rather than ignored.
rm -f "$work/args"
run "" TESTBRIDGE_TEST_ONLY="Mod.A,-Mod.B"
[[ "$status" -ne 0 && ! -e "$work/args" ]] || fail "a skip filter ran xctest or passed"

# macOS makes no simulator.
run ""
[[ ! -e "$work/simctl" ]] || fail "a macOS run used simctl: $(cat "$work/simctl")"

platform="watchos"

# A watchOS run makes a simulator of the newest available watchOS that is not newer than the
# selected Xcode's watchOS SDK, boots it, runs the
# watchOS simulator's xctest of the selected Xcode on the unzipped bundle, and deletes it.
run "" DEVELOPER_DIR="/Selected/Xcode.app/Contents/Developer"
[[ "$status" -eq 0 ]] || fail "a passing watchOS run exited $status: $(cat "$work/err")"
grep -qx "create bazel-xctest-.* Watch-B watchOS-26-4" "$work/simctl" || fail "unexpected simctl create: $(cat "$work/simctl")"
grep -qx "boot FAKE-DEVICE" "$work/simctl" || fail "the simulator was not booted: $(cat "$work/simctl")"
[[ "$(tail -2 "$work/simctl")" == "shutdown FAKE-DEVICE"$'\n'"delete FAKE-DEVICE" ]] || fail "the simulator was not deleted: $(cat "$work/simctl")"
[[ "$(cat "$work/args")" == "/Selected/Xcode.app/Contents/Developer/Platforms/WatchSimulator.platform/Developer/Library/Xcode/Agents/xctest"$'\n'*/Fake.xctest ]] || fail "unexpected watchOS arguments: $(cat "$work/args")"

# An older Xcode's watchOS SDK picks the newest runtime that it isn't older than.
run "" FAKE_SDK_VERSION=11.5
grep -qx "create bazel-xctest-.* Watch-Old watchOS-11-5" "$work/simctl" || fail "Xcode 16.4's SDK picked: $(grep create "$work/simctl")"

# When every runtime is newer than the SDK, the newest available one runs.
run "" FAKE_SDK_VERSION=10.0
grep -qx "create bazel-xctest-.* Watch-C watchOS-26-5" "$work/simctl" || fail "an SDK older than every runtime picked: $(grep create "$work/simctl")"

# The test environment reaches the spawned xctest, but this Mac's PATH doesn't.
run "" PROBE="$probe"
[[ "$(cat "$work/probe")" == "$probe" ]] || fail "PROBE reached the watchOS xctest as '$(cat "$work/probe")'"
grep -qx "PATH=unset" "$work/child_excluded" || fail "PATH reached the watchOS xctest: $(cat "$work/child_excluded")"

# A value with a newline and Unicode, an empty value and a whitespace-only value reach it as they are.
for value in $'line one\nline two' "café ✓ 日本" "" "   "; do
  run "" PROBE="$value"
  [[ "$(cat "$work/probe")" == "$value" ]] || fail "PROBE='$value' reached the watchOS xctest as '$(cat "$work/probe")'"
done

# SIMCTL_CHILD_* variables are already simctl's own, so they aren't passed on again. (The runner
# skips DYLD_* too, but macOS strips those before bash starts, so no case can set one.)
run "" SIMCTL_CHILD_FAKE=1
grep -qx "NESTED=unset" "$work/child_excluded" || fail "SIMCTL_CHILD_FAKE was passed on again: $(cat "$work/child_excluded")"

# A filter goes to the watchOS xctest too.
run "Mod.B"
[[ "$(sed -n 2,3p "$work/args")" == "-XCTest"$'\n'"Mod.B" ]] || fail "unexpected watchOS filter: $(cat "$work/args")"

# The simulator is deleted when the tests fail too.
run "" FAKE_STATUS=1
[[ "$status" -eq 1 ]] || fail "a failing watchOS run exited $status"
grep -qx "delete FAKE-DEVICE" "$work/simctl" || fail "a failing run left the simulator: $(cat "$work/simctl")"

# With no watchOS runtime, the run fails and says how to install one.
saved_runtimes="$runtimes"
runtimes='{"runtimes": []}'
run ""
runtimes="$saved_runtimes"
[[ "$status" -ne 0 ]] || fail "a run with no watchOS runtime passed"
grep -q "xcodebuild -downloadPlatform watchOS" "$work/err" || fail "no install hint: $(cat "$work/err")"
! grep -q "^create" "$work/simctl" || fail "a run with no watchOS runtime made a simulator"

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
echo "All runner cases passed."
