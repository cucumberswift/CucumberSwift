#!/bin/bash
# Runs one of the parallel testing fixtures in Tests/ParallelFixtures with Xcode's parallel testing on,
# and fails unless every scenario ran exactly once, in as many workers as the fixtures' plain XCTest
# classes, up to two. Used by the Parallel tests jobs in CI.yml; run `mise run generate-fixtures` first.
#
#   PLATFORM=<iOS Simulator|tvOS Simulator|macOS|Mac Catalyst> KIND=<Hostless|Hosted|UI> \
#   [WORKERS=3] [EXPECTED_SCENARIOS=10] .github/scripts/parallel-fixture.sh
#
# Each run of a scenario writes a record, named after the scenario, its worker's process and a UUID, so
# that two runs never share one. xcodebuild's log can't show this, because it interleaves its own output
# with the workers' and cuts test lines short.
set -u
WORKERS=${WORKERS:-3}
# The scenarios in Tests/ParallelFixtures/Features.
EXPECTED_SCENARIOS=${EXPECTED_SCENARIOS:-10}
temp=${RUNNER_TEMP:-$(mktemp -d)}

case "$PLATFORM" in
  "Mac Catalyst") suffix=""; destination="platform=macOS,variant=Mac Catalyst" ;;
  "macOS") suffix="Mac"; destination="platform=macOS" ;;
  *)
    # The first iPhone or Apple TV of the runtime the selected Xcode comes with, so the job doesn't
    # depend on a device name: the newest runtime not newer than the Xcode's SDK, or else the oldest
    # newer one of the same major version, or else the newest. A runner can have newer runtimes than
    # an older Xcode, such as iOS 18.6 and 26.2 beside Xcode 16.4, and the tests run on the runtimes
    # each Xcode comes with.
    if [[ "$PLATFORM" = "tvOS Simulator" ]]; then suffix="TV"; runtime="tvOS"; device="Apple TV"; sdk="appletvsimulator"; else suffix=""; runtime="iOS"; device="iPhone"; sdk="iphonesimulator"; fi
    sdk_version=$(xcrun --sdk "$sdk" --show-sdk-version)
    udid=$(xcrun simctl list devices available --json | RUNTIME="$runtime" DEVICE="$device" SDK_VERSION="$sdk_version" python3 -c '
import json, os, sys
devices = json.load(sys.stdin)["devices"]
prefix = ".SimRuntime." + os.environ["RUNTIME"] + "-"
sdk = [int(n) for n in os.environ["SDK_VERSION"].split(".")]
version = lambda r: [int(n) for n in r.rsplit(prefix, 1)[1].split("-")]
runtimes = sorted((r for r in devices if prefix in r), key=version, reverse=True)
runtimes = ([r for r in runtimes if version(r) <= sdk]
            + sorted((r for r in runtimes if version(r) > sdk and version(r)[0] == sdk[0]), key=version)
            + [r for r in runtimes if version(r)[0] > sdk[0]])
print(next((d["udid"] for r in runtimes for d in devices[r] if d["name"].startswith(os.environ["DEVICE"])), ""))
')
    if [[ -z "$udid" ]]; then
      echo "::error::No $device simulator is available on this runner." >&2
      exit 1
    fi
    destination="platform=$PLATFORM,id=$udid" ;;
esac
scheme="Parallel${KIND}Tests${suffix}"
records="$temp/parallel-test-records"
mkdir -p "$records"
echo "Running $scheme on $destination with $WORKERS workers"

xcodebuild test -project Tests/ParallelFixtures/ParallelFixtures.xcodeproj -scheme "$scheme" -destination "$destination" \
  -parallel-testing-worker-count "$WORKERS" -resultBundlePath "$temp/parallel-test.xcresult" \
  PARALLEL_TEST_RECORDS="$records" > parallel-test.log 2>&1
status=$?
# The sandboxed UI test runner on macOS and Mac Catalyst records in its own temporary folder.
cp "$HOME"/Library/Containers/*/Data/tmp/parallel-test-records/* "$records"/ 2>/dev/null || true

echo "Tests: $(grep -cE "^Test [Cc]ase .* passed" parallel-test.log) passed, $(grep -cE "^Test [Cc]ase .* failed" parallel-test.log) failed"
grep -E 'error: ' parallel-test.log | sed -E 's|^.*/Features/||; s|^.*/Tests/||' | sort | uniq -c | sort -rn | head -40
grep -oE 'Could not record [^"]*' parallel-test.log | sort -u | head -5
# Each failing test and why, from the result bundle: the log names a failing test, not always why.
xcrun xcresulttool get test-results summary --path "$temp/parallel-test.xcresult" 2>/dev/null | python3 -c '
import json, sys
for failure in json.load(sys.stdin).get("testFailures", [])[:30]:
    print("Failed:", failure.get("testName"), "--", " ".join(failure.get("failureText", "").split())[:2000])
' || true
# A fixture app that crashed leaves a report: show what it died of.
for report in $(ls -t "$HOME"/Library/Logs/DiagnosticReports/ParallelFixtureApp* 2>/dev/null | head -3); do
  echo "Crash report $(basename "$report"):"
  grep -E '"(exception|termination|asi)"' "$report" | head -5
done
grep -E -A4 'xcodebuild: error|encountered an error|\*\* (BUILD|TEST) FAILED' parallel-test.log | head -30

total=$(ls "$records" | wc -l | tr -d ' ')
# Each record is <scenario>.<worker's process>.<UUID>.
scenarios=$(ls "$records" | sed -E 's/\.[0-9]+\.[0-9A-F-]+$//' | sort -u | wc -l | tr -d ' ')
workers=$(ls "$records" | sed -E 's/^.*\.([0-9]+)\.[0-9A-F-]+$/\1/' | sort -u | wc -l | tr -d ' ')
echo "Scenario records: $total for $scenarios scenarios, from $workers workers ($EXPECTED_SCENARIOS scenarios expected)"
# The workers Xcode gave the plain XCTest classes, named in each result line.
control=$(grep -oE "PlainXCTestControl[0-9]+.* (passed|failed) on '[^']*'" parallel-test.log | sed -E "s/^.* on '//; s/'$//" | sort -u | wc -l | tr -d ' ')
[[ "$control" -gt 0 ]] || control=1
echo "Plain XCTest classes ran in $control workers"
min_workers=$(( control < 2 ? control : 2 ))
ls "$records" | sed -E 's/\.[0-9]+\.[0-9A-F-]+$//' | sort | uniq -d | sed 's/^/::error::Ran more than once: /' >&2
if [[ "$scenarios" -ne "$EXPECTED_SCENARIOS" ]]; then
  echo "::error::$scenarios of $EXPECTED_SCENARIOS scenarios ran. If you changed the fixtures' features, update EXPECTED_SCENARIOS in .github/scripts/parallel-fixture.sh." >&2
  status=1
fi
if [[ "$total" -ne "$scenarios" ]]; then
  echo "::error::Some scenarios ran more than once." >&2
  status=1
fi
if [[ "$workers" -lt "$min_workers" ]]; then
  echo "::error::The scenarios ran in $workers workers, and plain XCTest classes in $control, so they did not run in parallel." >&2
  status=1
fi
exit $status
