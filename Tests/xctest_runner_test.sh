#!/bin/bash
# Tests xctest_runner.template.sh with a stand-in for `xcrun xctest`, so no
# real tests run. Each case fills in the template as rules_apple does and checks
# what the runner passes to xctest and how it exits.

set -euo pipefail

template="$1"
work="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/runner_test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# A stand-in for xcrun: records its arguments and PROBE, prints the summary
# line xctest would print for FAKE_COUNT tests, and exits with FAKE_STATUS.
mkdir -p "$work/bin"
cat > "$work/bin/xcrun" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$FAKE_ARGS"
printf '%s' "${PROBE-unset}" > "$FAKE_PROBE"
printf "\t Executed %s tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds\n" "$FAKE_COUNT"
exit "$FAKE_STATUS"
EOF
chmod +x "$work/bin/xcrun"

# A bundle zipped as rules_apple zips it: Fake.xctest at the root.
mkdir -p "$work/bundle/Fake.xctest/Contents"
(cd "$work/bundle" && zip -qr "$work/Fake.zip" Fake.xctest)

# The runner's bundle: the zip, unless a case sets it.
bundle="$work/Fake.zip"

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
    "$template" > "$work/runner.sh"
  status=0
  env -u TEST_PREMATURE_EXIT_FILE -u TESTBRIDGE_TEST_ONLY \
    PATH="$work/bin:$PATH" FAKE_ARGS="$work/args" FAKE_PROBE="$work/probe" \
    FAKE_COUNT=3 FAKE_STATUS=0 "$@" \
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
run "" PROBE="a,b=c,d"
[[ "$(cat "$work/probe")" == "a,b=c,d" ]] || fail "PROBE reached xctest as '$(cat "$work/probe")'"

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

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
echo "All runner cases passed."
