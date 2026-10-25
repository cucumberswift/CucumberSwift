#!/bin/bash
# Runs one of the parallel testing fixtures in Tests/ParallelFixtures with Xcode's parallel testing on,
# and fails unless every scenario ran exactly once, in as many workers as the fixtures' plain XCTest
# classes, up to two, and each feature's hooks ran as often, where and when they should (#387). Where
# Xcode runs the tests in parallel (runs_in_parallel), the scenarios must also have run in every worker,
# or with UNIT=feature in as many as there are features (#491).
# Used by the Parallel tests jobs in CI.yml; run `mise run generate-fixtures` first.
#
#   PLATFORM=<iOS Simulator|tvOS Simulator|macOS|Mac Catalyst> KIND=<Hostless|Hosted|UI> \
#   [UNIT=scenario|feature|both] [LAYOUT=step|scenario|alternate] [SERIAL=yes] [WORKERS=3] \
#   [EXPECTED_SCENARIOS=10] [WITHOUT_SETTING=YES] .github/scripts/parallel-fixture.sh
#
# With WITHOUT_SETTING=YES the fixture leaves out `Cucumber.parallelTesting`, and the run must fail with
# CucumberSwift's message naming it (#389) instead of running the scenarios wrongly. It is one run, whatever
# UNIT is, with a test per step, whatever LAYOUT is.
#
# UNIT is what Xcode hands to a worker, passed to the tests as CUCUMBER_PARALLEL_TESTING_UNIT: each
# scenario (the default), each whole feature, or both, one after the other, with a records folder and
# a report each.
#
# Each worker also merges its results into one Cucumber JSON report, which must hold every scenario once.
#
# LAYOUT is a test per step (the default) or one test per scenario (#388), passed to the tests as
# CUCUMBER_ONE_TEST_PER_SCENARIO. With UNIT=both, `alternate` runs the scenario unit with a test per step
# and the feature unit with one test per scenario, so one job runs both layouts and both units in a way
# that makes each way of making a class run. With SERIAL=yes, each unit also runs once with Xcode's parallel
# testing off, and the scenarios must run in the order of the feature files.
#
# Each run of a scenario and each feature hook writes a record, named after its worker's process, its
# position among that process's records, what it records, and a UUID, so that two runs never share one.
# .github/scripts/parallel_records.py checks them. xcodebuild's log can't show this, because it
# interleaves its own output with the workers' and cuts test lines short.
set -u
WORKERS=${WORKERS:-3}
UNIT=${UNIT:-scenario}
case "$UNIT" in
  scenario|feature) units=("$UNIT") ;;
  both) units=(scenario feature) ;;
  *) echo "::error::UNIT must be scenario, feature or both, not '$UNIT'." >&2; exit 1 ;;
esac
case "${LAYOUT:-step}" in
  step|scenario|alternate) ;;
  *) echo "::error::LAYOUT must be step, scenario or alternate, not '$LAYOUT'." >&2; exit 1 ;;
esac
# Without the setting there is no unit to hand out, so it is one run.
[[ "${WITHOUT_SETTING:-}" = "YES" ]] && units=(scenario)
# The scenarios in Tests/ParallelFixtures/Features.
EXPECTED_SCENARIOS=${EXPECTED_SCENARIOS:-10}
EXPECTED_FEATURES=${EXPECTED_FEATURES:-2}
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
echo "Running $scheme on $destination with $WORKERS workers, handing out each: ${units[*]}, with a test per ${LAYOUT:-step}"

# Xcode runs each worker on a clone of the simulator. A simulator's first boot on a fresh runner does
# a lot of one-off work (it took 291 seconds in one run), and each clone would repeat it while its tests wait
# to launch the app, which then times out. So boot the simulator once, wait until it has finished, and shut
# it down for Xcode to clone. A simulator that never finishes booting would keep bootstatus waiting, so
# after 8 minutes the tests start anyway.
if [[ -n "${udid:-}" ]]; then
  start=$(date +%s)
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b > /dev/null &
  waiting=$!
  while kill -0 "$waiting" 2>/dev/null && (( $(date +%s) - start < 480 )); do sleep 2; done
  if kill -0 "$waiting" 2>/dev/null; then
    kill "$waiting"
    echo "::warning::The simulator hadn't finished booting after 8 minutes; running the tests anyway."
  elif wait "$waiting"; then
    echo "Booted the simulator once first, in $(( $(date +%s) - start )) seconds"
  else
    echo "::warning::The simulator failed to boot before the tests; running them anyway."
  fi
  xcrun simctl shutdown "$udid" 2>/dev/null || true
fi

# The sandboxed UI test runner on macOS and Mac Catalyst records in its own temporary folder, in the container of
# the container of the fixture's test runner, such as org.cucumberswift.ParallelUITests.xctrunner. Nothing else
# empties it, so a local run would also count the records of an earlier one. Only the containers of the
# fixtures' own bundle IDs, org.cucumberswift.Parallel*, are touched, never another app's.
# Found again after the run, because a clean runner has no such container until the tests have run.
runner_folders() {
  local name="$1"
  ls -dt "$HOME"/Library/Containers/org.cucumberswift.Parallel*/Data/tmp/"$name" 2>/dev/null
  return 0
}
runner_records() {
  runner_folders parallel-test-records
  return 0
}

# How many processes wrote a scenario record into folder $1: the Simulator clones that ran scenarios.
scenario_workers() {
  local folder=$1
  ls "$folder" | awk -F. '$3 == "scenario" { print $1 }' | sort -u | wc -l | tr -d ' '
  return 0
}

# Whether Xcode spreads this platform's and kind's tests over its workers, as "Running Scenarios in Parallel"
# says and #491 measured with Xcode 26: tests without a host app everywhere, tests hosted in an app on
# macOS, and UI tests on tvOS. Elsewhere it runs them all in one worker.
runs_in_parallel() {
  case "$KIND/$PLATFORM" in
    Hostless/*|"Hosted/macOS"|"UI/tvOS Simulator") return 0 ;;
    *) return 1 ;;
  esac
}

# Runs the tests once, handing out each $1 (scenario or feature), and checks the records. With $2 = serial,
# parallel testing is off in Xcode (CucumberSwift's setting stays on), and the scenarios must run in the
# order of the feature files: that is what XCTest's order by class name gives (#388). Under Xcode's parallel
# testing a worker gets its classes in an order of Xcode's own, so the order is only checked in a serial run.
run_unit() {
  local unit=$1 mode=${2:-parallel}
  # A run without the setting, and a serial run, have files of their own, so that each holds only its run's records.
  local name_suffix="$1${2:+-$2}${WITHOUT_SETTING:+-without-setting}"
  local records="$temp/parallel-test-records-$name_suffix" log="parallel-test-$name_suffix.log" result="$temp/parallel-test-$name_suffix.xcresult"
  local report="$temp/parallel-test-report-$name_suffix/report.json"
  local status layout=${LAYOUT:-step} one_test_per_scenario parallel_flags=(-parallel-testing-worker-count "$WORKERS")
  [[ "$mode" = serial ]] && parallel_flags=(-parallel-testing-enabled NO)
  # One test per scenario is not affected by a missing setting, so that run has a test per step.
  [[ "${WITHOUT_SETTING:-}" = "YES" ]] && layout=step
  if [[ "$layout" = alternate ]]; then
    [[ "$unit" = scenario ]] && layout=step || layout=scenario
  fi
  [[ "$layout" = scenario ]] && one_test_per_scenario=YES || one_test_per_scenario=NO
  echo "::group::Each $unit, with a test per $layout, $mode"
  rm -rf "$records" "$result" "$(dirname "$report")"
  mkdir -p "$records" "$(dirname "$report")"
  for name in parallel-test-records parallel-test-report; do
    runner_folders "$name" | while IFS= read -r folder; do rm -rf "$folder"; done
  done

  # A Simulator clone whose test runner fails to launch leaves one worker running every scenario, which is the
  # environment failing, not CucumberSwift or the fixture (#375). The message alone doesn't show it: Xcode 16.4
  # prints it at teardown of a run that passed, and a real failure can come with it. So the run is repeated once
  # only with all of this evidence together: the message, a run that failed (xcodebuild's status, or its
  # records), and fewer clones with scenario records than workers, which shows a clone never ran its share. The
  # repeat is reported, the first attempt's log is kept beside the second's (parallel-test-*-attempt-1.log, which
  # the job uploads on a failure), and a failure that comes back fails the job. A failure without all three is
  # never repeated.
  local attempt failed clones
  for attempt in 1 2; do
    .github/scripts/keep-package-resolved.sh xcodebuild test -project Tests/ParallelFixtures/ParallelFixtures.xcodeproj -scheme "$scheme" -destination "$destination" \
      "${parallel_flags[@]}" -resultBundlePath "$result" \
      PARALLEL_TEST_RECORDS="$records" PARALLEL_TEST_REPORT="$report" CUCUMBER_PARALLEL_TESTING_UNIT="$unit" \
      CUCUMBER_ONE_TEST_PER_SCENARIO="$one_test_per_scenario" \
      PARALLEL_FIXTURE_WITHOUT_SETTING="${WITHOUT_SETTING:-}" > "$log" 2>&1
    status=$?
    if [[ "$attempt" -eq 1 && "$mode" != serial && -n "${udid:-}" ]] && grep -qE "Failed to launch app with identifier: .*\.xctrunner|NSMachErrorDomain Code=-308" "$log"; then
      runner_records | while IFS= read -r folder; do cp "$folder"/* "$records"/ 2>/dev/null || true; done
      failed=no
      if [[ "$status" -ne 0 ]] || ! python3 .github/scripts/parallel_records.py "$records" --unit "$unit" --expected-scenarios "$EXPECTED_SCENARIOS" > /dev/null 2>&1; then failed=yes; fi
      clones=$(scenario_workers "$records")
      if [[ "$failed" = yes && "$clones" -lt "$WORKERS" ]]; then
        echo "::warning::A simulator clone's test runner failed to launch: only $clones of $WORKERS clones ran scenarios. Running the $unit tests once more."
        grep -E "Failed to launch app with identifier|NSMachErrorDomain" "$log" | head -3 | cut -c1-300
        cp "$log" "${log%.log}-attempt-1.log"
        rm -rf "$records" "$result" "$(dirname "$report")"
        mkdir -p "$records" "$(dirname "$report")"
        for name in parallel-test-records parallel-test-report; do
          runner_folders "$name" | while IFS= read -r folder; do rm -rf "$folder"; done
        done
        continue
      fi
    fi
    break
  done
  runner_records | while IFS= read -r folder; do cp "$folder"/* "$records"/ 2>/dev/null || true; done
  # It writes the report there too, and has only one worker, so there is nothing to merge it with.
  [[ -s "$report" ]] || cp "$(runner_folders parallel-test-report | head -1)/report.json" "$report" 2>/dev/null || true

  echo "Tests: $(grep -cE "^Test [Cc]ase .* passed" "$log") passed, $(grep -cE "^Test [Cc]ase .* failed" "$log") failed"
  grep -E 'error: ' "$log" | sed -E 's|^.*/Features/||; s|^.*/Tests/||' | sort | uniq -c | sort -rn | head -40
  grep -oE 'Could not record [^"]*' "$log" | sort -u | head -5
  grep -E '^CucumberSwift: the hook at ' "$log" | sort -u | head -5
  # Each failing test and why, from the result bundle: the log names a failing test, not always why. The
  # whole list goes to a file that the run without the setting checks; only the first 30 are shown.
  # An aborted xcodebuild (exit 134, say) can leave no result bundle, so there is no summary to read.
  local failures="$temp/parallel-test-failures-$unit$suffix.txt"
  : > "$failures"
  local summary=""
  if [[ ! -e "$result" ]]; then
    echo "No test results summary: xcodebuild left no result bundle (exit status $status). See $log."
  elif ! summary=$(xcrun xcresulttool get test-results summary --path "$result" 2>/dev/null) || [[ -z "$summary" ]]; then
    echo "No test results summary: xcresulttool could not read the result bundle (xcodebuild exit status $status). See $log."
  else
    echo "$summary" | python3 -c '
import json, sys
for failure in json.load(sys.stdin).get("testFailures", []):
    print("Failed:", failure.get("testName"), "--", " ".join(failure.get("failureText", "").split())[:2000])
' > "$failures" || true
    head -30 "$failures"
    # XCUITest itself timing out on a busy Simulator is the environment failing, not a test, and is said so (#375).
    # Not repeated: another run of the unit could outlast the job.
    if [[ -s "$failures" && "${WITHOUT_SETTING:-}" != "YES" ]] && ! grep '^Failed:' "$failures" \
      | grep -qvE 'Timed out while evaluating UI query|kAXErrorIPCTimeout|Failed to get list of active applications'; then
      echo "::error::Environment failure: XCUITest timed out driving the Simulator, in every failing test of this run. Not a CucumberSwift failure." >&2
    fi
  fi
  # A fixture app that crashed leaves a report: show what it died of.
  for crash in $(ls -t "$HOME"/Library/Logs/DiagnosticReports/ParallelFixtureApp* 2>/dev/null | head -3); do
    echo "Crash report $(basename "$crash"):"
    grep -E '"(exception|termination|asi)"' "$crash" | head -5
  done
  grep -E -A4 'xcodebuild: error|encountered an error|\*\* (BUILD|TEST) FAILED' "$log" | head -30

  # The run must fail, every failure in the result bundle must be CucumberSwift's message, which names the
  # setting, at least one must be, and no scenario may have run: the message alone doesn't show that the
  # scenarios were held back, nor that nothing else failed.
  if [[ "${WITHOUT_SETTING:-}" = "YES" ]]; then
    local message="parallel testing is off" matching others ran
    matching=$(grep '^Failed:' "$failures" | grep -c "$message" || true)
    others=$(grep '^Failed:' "$failures" | grep -vc "$message" || true)
    ran=$(ls "$records" | wc -l | tr -d ' ')
    echo "::endgroup::"
    if [[ "$status" -ne 0 && "$matching" -ge 1 && "$others" -eq 0 && "$ran" -eq 0 ]]; then
      echo "The run without Cucumber.parallelTesting failed only with CucumberSwift's message ($matching failures), and ran no scenario"
      return 0
    fi
    echo "The end of the log:"; tail -40 "$log" | cut -c1-400
    echo "::error::The run without Cucumber.parallelTesting must fail only with CucumberSwift's message and run no scenario: xcodebuild exit status $status, $matching failures with the message, $others with another, $ran scenario records." >&2
    return 1
  fi

  if [[ -z "$(ls "$records")" ]]; then
    echo "No records. Containers with a records folder:"
    ls -d "$HOME"/Library/Containers/*/Data/tmp/parallel-test-records 2>/dev/null || echo "none"
  fi
  # The workers Xcode gave the plain XCTest classes, named in each result line.
  local control
  control=$(grep -oE "PlainXCTestControl[0-9]+.* (passed|failed) on '[^']*'" "$log" | sed -E "s/^.* on '//; s/'$//" | sort -u | wc -l | tr -d ' ')
  [[ "$control" -gt 0 ]] || control=1
  echo "Plain XCTest classes ran in $control workers"
  # Where the docs say the scenarios run in parallel, the run fails unless they ran in every worker, or with the
  # feature unit in as many workers as there are features (#491). Elsewhere Xcode runs every test in one worker,
  # plain XCTest classes too, and a run in more than one is said, because the docs would then be out of date.
  if [[ "$mode" != serial ]]; then
    local ran_in wanted=$WORKERS
    ran_in=$(scenario_workers "$records")
    [[ "$unit" = feature && "$EXPECTED_FEATURES" -lt "$wanted" ]] && wanted=$EXPECTED_FEATURES
    if runs_in_parallel; then
      if [[ "$ran_in" -lt "$wanted" ]]; then
        echo "::error::Only $ran_in of $wanted workers ran scenarios in the $unit run, where they should all run some: $PLATFORM $KIND tests run in parallel." >&2
        status=1
      fi
    elif [[ "$ran_in" -gt 1 ]]; then
      echo "::notice::The scenarios ran in $ran_in workers in the $unit run. The docs say $PLATFORM $KIND tests run in one worker."
    fi
  fi
  if [[ "$mode" = serial ]]; then
    python3 .github/scripts/parallel_records.py "$records" --unit "$unit" --expected-scenarios "$EXPECTED_SCENARIOS" \
      --check-order || status=1
  else
    python3 .github/scripts/parallel_records.py "$records" --unit "$unit" --expected-scenarios "$EXPECTED_SCENARIOS" \
      --min-workers $(( control < 2 ? control : 2 )) || status=1
  fi

  # The Cucumber JSON report the workers wrote between them: every scenario exactly once, under its feature,
  # in feature-file order, and each feature once, whichever unit Xcode handed out.
  local report_check report_status
  report_check=$(REPORT="$report" RECORDS="$records" EXPECTED="$EXPECTED_SCENARIOS" EXPECTED_FEATURES="$EXPECTED_FEATURES" python3 -c '
import json, os, sys
try:
    features = json.load(open(os.environ["REPORT"]))
except (OSError, ValueError) as error:
    print("The report is missing or is not JSON: %s" % error)
    sys.exit(1)
problems = []
seen = {}
# Features are in the order of their files, as a serial run lists them, whichever worker wrote first.
def bundle_path(feature):
    uri = feature.get("uri") or ""
    return uri.rsplit(".xctest/", 1)[-1]
paths = [bundle_path(feature) for feature in features]
if paths != sorted(paths):
    problems.append("features are not in the order of their files: %s" % ", ".join(paths))
for feature in features:
    lines = [scenario["line"] for scenario in feature.get("elements", [])]
    if lines != sorted(lines):
        problems.append("%s: scenarios are not in feature-file order" % feature.get("name"))
    for scenario in feature.get("elements", []):
        key = (feature.get("uri"), scenario["line"], scenario["name"])
        seen[key] = seen.get(key, 0) + 1
        if not scenario.get("steps"):
            problems.append("%s has no steps" % scenario["name"])
problems += ["%s ran %d times in the report" % (key[2], n) for key, n in seen.items() if n > 1]
# Every scenario that recorded a run is in the report, under its own feature. A scenario record is named
# <process>.<sequence>.scenario.<feature>.<line and title>.<UUID>, as ParallelFixtureSupport writes it.
def label(name):
    return "".join(c if c.isalnum() else "-" for c in name)
in_report = set(label("%s line %d %s" % (feature.get("name"), scenario["line"], scenario["name"]))
                for feature in features for scenario in feature.get("elements", []))
recorded = set()
for name in os.listdir(os.environ["RECORDS"]):
    parts = name.split(".")
    if len(parts) == 6 and parts[2] == "scenario":
        recorded.add("%s-%s" % (parts[3], parts[4]))
problems += ["%s ran but is not in the report, or is under another feature" % name for name in sorted(recorded - in_report)]
problems += ["%s is in the report but never ran" % name for name in sorted(in_report - recorded)]
if len(seen) != int(os.environ["EXPECTED"]):
    problems.append("the report holds %d of %s scenarios" % (len(seen), os.environ["EXPECTED"]))
if len(features) != int(os.environ["EXPECTED_FEATURES"]):
    problems.append("the report holds %d features, not %s: a feature was split between workers" % (len(features), os.environ["EXPECTED_FEATURES"]))
print("Report: %d scenarios in %d features" % (len(seen), len(features)))
print("\n".join(problems))
sys.exit(1 if problems else 0)
')
  report_status=$?
  echo "$report_check"
  if [[ "$report_status" -ne 0 ]]; then
    echo "::error::The Cucumber JSON report does not hold every scenario exactly once." >&2
    status=1
  fi
  echo "::endgroup::"
  [[ "$status" -eq 0 ]] || echo "::error::The $mode run handing out each $unit, with a test per $layout, failed." >&2
  return "$status"
}

status=0
for unit in "${units[@]}"; do
  run_unit "$unit" || status=1
done
# One run for each unit with parallel testing off in Xcode, to check the order of a serial run (#388).
if [[ "${SERIAL:-no}" = yes && "${WITHOUT_SETTING:-}" != "YES" ]]; then
  for unit in "${units[@]}"; do
    run_unit "$unit" serial || status=1
  done
fi
exit $status
