#!/bin/bash
# Runs Fixtures/CoverageMergePackage's feature files with code coverage in every way the merge scores, with
# each runner, and fails unless cucumberswift coverage merge gives each way the same scores (#515):
#
# - XCTest: one scenario at a time; with Xcode's parallel testing, in 3 workers; and in 2 shards, one
#   for each tag, @shard1 and @shard2, as CUCUMBER_TAGS picks them.
# - Swift Testing: one scenario at a time; and in the same 2 shards, run at the same time.
# - Both runners in one `swift test` of the package, which writes a run folder for each.
#
# The merged scores of a run one scenario at a time must also be the ones its runner printed while it ran,
# and both runners must give the same scores. Times differ from run to run, so they are left out.
#
#   .github/scripts/coverage-merge-fixture.sh [work folder]
#
# Used by the Fixture tests job in CI.yml, and by `mise run test-coverage-merge`.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
fixture="$root/Fixtures/CoverageMergePackage"
work="${1:-$(mktemp -d)}"
derived="$work/DerivedData"
coverage="$work/coverage"
logs="$work/logs"
rm -rf "$coverage" "$logs"
mkdir -p "$coverage" "$logs"
keep="$root/.github/scripts/keep-package-resolved.sh"

# Resolving the tool's package rewrites Package.resolved without the Macros trait. Whatever the script's end,
# the file is the one the caller had, with any edits of theirs.
cp "$root/Package.resolved" "$work/Package.resolved.saved"
trap 'cp "$work/Package.resolved.saved" "$root/Package.resolved"' EXIT

echo "Building cucumberswift coverage merge"
swift build --package-path "$root" --scratch-path "$work/tool" --product cucumberswift > "$logs/tool.log" 2>&1 \
  || { cat "$logs/tool.log"; exit 1; }
merge="$work/tool/debug/cucumberswift"
cp "$work/Package.resolved.saved" "$root/Package.resolved"

cd "$fixture"
xcodebuild_tests() {
  "$keep" xcodebuild "$@" -scheme CoverageMergePackage-Package -destination platform=macOS -derivedDataPath "$derived" \
    -enableCodeCoverage YES -skipMacroValidation CODE_SIGNING_ALLOWED=NO
}
echo "Building the fixture's tests with code coverage"
xcodebuild_tests build-for-testing > "$logs/build.log" 2>&1 || { tail -50 "$logs/build.log"; exit 1; }

# Runs one target's tests into the coverage folder $1, with the log $2 and the extra arguments after them.
# CucumberSwift never measures the files in its own package folder, which holds the fixture, so
# CUCUMBER_COVERAGE_SOURCES names the fixture's code.
run_tests() {
  local folder=$1 log=$2
  shift 2
  if ! TEST_RUNNER_CUCUMBER_COVERAGE=YES TEST_RUNNER_CUCUMBER_COVERAGE_PATH="$coverage/$folder" \
    TEST_RUNNER_CUCUMBER_COVERAGE_SOURCES=CoverageMergePackage/Sources \
    xcodebuild_tests test-without-building -resultBundlePath "$work/$log.xcresult" "$@" > "$logs/$log.log" 2>&1; then
    tail -80 "$logs/$log.log"
    echo "error: the $log run failed; its log is $logs/$log.log" >&2
    exit 1
  fi
}

echo "Running the XCTest scenarios one at a time, in 3 workers, and in 2 shards"
run_tests xctest-serial xctest-serial -only-testing:CalculatorXCTests -parallel-testing-enabled NO
TEST_RUNNER_CUCUMBER_PARALLEL_TESTING=YES run_tests xctest-parallel xctest-parallel -only-testing:CalculatorXCTests \
  -parallel-testing-enabled YES -parallel-testing-worker-count 3
TEST_RUNNER_CUCUMBER_TAGS=shard1 run_tests xctest-shards xctest-shard1 -only-testing:CalculatorXCTests -parallel-testing-enabled NO
TEST_RUNNER_CUCUMBER_TAGS=shard2 run_tests xctest-shards xctest-shard2 -only-testing:CalculatorXCTests -parallel-testing-enabled NO

echo "Running the Swift Testing scenarios one at a time, and in 2 shards at the same time"
run_tests swift-serial swift-serial -only-testing:CalculatorSwiftTests
TEST_RUNNER_CUCUMBER_TAGS=shard1 run_tests swift-shards swift-shard1 -only-testing:CalculatorSwiftTests &
first=$!
TEST_RUNNER_CUCUMBER_TAGS=shard2 run_tests swift-shards swift-shard2 -only-testing:CalculatorSwiftTests &
second=$!
wait "$first"
wait "$second"

echo "Running both runners in one swift test"
# `swift test` runs the XCTest runner and the Swift Testing runner from one test binary, and each writes a run
# folder in the same coverage folder.
CUCUMBER_COVERAGE=YES CUCUMBER_COVERAGE_PATH="$coverage/swift-test" CUCUMBER_COVERAGE_SOURCES=CoverageMergePackage/Sources \
  "$keep" swift test --package-path "$fixture" --scratch-path "$work/swiftpm" --enable-code-coverage > "$logs/swift-test.log" 2>&1 \
  || { tail -80 "$logs/swift-test.log"; echo "error: the swift test run failed; its log is $logs/swift-test.log" >&2; exit 1; }

# The merge's output without times, and with each feature file's name for its path, which each runner gives
# differently.
normalized() {
  local file=$1
  sed -E -e 's/[0-9]+\.[0-9]+ ?s([^[:alnum:]]|$)/<time>\1/g' -e 's#^[^ ]*/([^/]+\.feature):#\1:#' "$file"
}

status=0
for way in xctest-serial xctest-parallel xctest-shards swift-serial swift-shards; do
  runs=$(find "$coverage/$way" -name manifest.json | wc -l | tr -d ' ')
  "$merge" coverage merge "$coverage/$way" > "$logs/$way.merged" || { cat "$logs/$way.merged"; echo "error: the merge of $way failed" >&2; exit 1; }
  echo "$way: $runs runs: $(head -1 "$logs/$way.merged")"
  if ! grep -q "^CucumberSwift coverage: 10 scenarios from" "$logs/$way.merged"; then
    echo "error: $way: the merge didn't score the fixture's 10 scenarios" >&2
    status=1
  fi
  tail -n +2 "$logs/$way.merged" | normalized /dev/stdin > "$logs/$way.scores"
done
# Each shard must have run some of the scenarios, not all: merging runs that each ran all 10 would remove the
# repeats and still score the same. So each shard's run is merged alone, and the counts add up to the 10.
for way in xctest-shards swift-shards; do
  total=0
  for manifest in "$coverage/$way"/*/manifest.json; do
    count=$("$merge" coverage merge "$(dirname "$manifest")" | head -1 | sed -E 's/^CucumberSwift coverage: ([0-9]+) scenarios? from.*/\1/')
    echo "$way: $(basename "$(dirname "$manifest")") ran $count scenarios"
    if [[ ! "$count" =~ ^[0-9]+$ ]] || [[ "$count" -eq 0 || "$count" -ge 10 ]]; then
      echo "error: $way: a shard ran $count of the 10 scenarios, not some of them" >&2
      status=1
    else
      total=$((total + count))
    fi
  done
  [[ "$total" -eq 10 ]] || { echo "error: $way: the shards ran $total scenarios together, not the 10 without repeats" >&2; status=1; }
done
# One swift test must have written a run folder for each runner, and merging them must score each runner's
# features as the runner's serial run did: the lines of both serial runs, together.
"$merge" coverage merge "$coverage/swift-test" > "$logs/swift-test.merged" || { cat "$logs/swift-test.merged"; echo "error: the merge of swift-test failed" >&2; exit 1; }
runs=$(find "$coverage/swift-test" -name manifest.json | wc -l | tr -d ' ')
echo "swift-test: $runs runs: $(head -1 "$logs/swift-test.merged")"
[[ "$runs" -eq 2 ]] || { echo "error: swift test wrote $runs run folders, not one for each runner" >&2; status=1; }
tail -n +2 "$logs/swift-test.merged" | normalized /dev/stdin | sort > "$logs/swift-test.scores"
sort "$logs/xctest-serial.scores" "$logs/swift-serial.scores" > "$logs/both-serial.scores"
if diff -u "$logs/both-serial.scores" "$logs/swift-test.scores"; then
  echo "swift test's merged run gives the scores of both runners' serial runs."
else
  echo "error: swift test's merged run gives other scores than the runners' serial runs" >&2
  status=1
fi
[[ "$(find "$coverage/xctest-parallel" -name manifest.json | wc -l)" -ge 2 ]] \
  || { echo "error: the parallel XCTest run used one worker, so it proves nothing" >&2; status=1; }

# Fails unless the scores in $1 and $2 are the same.
same() {
  local first=$1 second=$2
  if diff -u "$logs/$first.scores" "$logs/$second.scores"; then
    echo "$second gives the same scores as $first."
  else
    echo "error: $second gives other scores than $first" >&2
    status=1
  fi
}
same xctest-serial xctest-parallel
same xctest-serial xctest-shards
same swift-serial swift-shards
same xctest-serial swift-serial

# A run one scenario at a time printed each feature's and each Rule's summary as it went. The merge must print
# the same ones, and the Swift Testing runner's issues, which it prints in the same form.
for runner in xctest swift; do
  grep -hE '^(CucumberSwift coverage: .*% of the code its scenarios ran|[^ ]*\.feature:[0-9]+: (warning|error): )' "$logs/$runner-serial.log" \
    | normalized /dev/stdin | sort -u > "$logs/$runner-printed"
  pattern='^CucumberSwift coverage: .*% of the code its scenarios ran'
  [[ "$runner" = swift ]] && pattern="$pattern|\\.feature:[0-9]+: (warning|error): "
  grep -E "$pattern" "$logs/$runner-serial.scores" | sort -u > "$logs/$runner-expected"
  if [[ ! -s "$logs/$runner-printed" ]] || ! diff -u "$logs/$runner-expected" "$logs/$runner-printed"; then
    echo "error: the merge doesn't print what the $runner runner printed while its scenarios ran" >&2
    status=1
  else
    echo "The merge prints what the $runner runner printed: $(wc -l < "$logs/$runner-printed" | tr -d ' ') lines."
  fi
done

cat "$logs/xctest-parallel.merged"
exit "$status"
