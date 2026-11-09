#!/bin/bash
# Runs the parity suite in Fixtures/Parity for one combination of build tool, runner, run mode and platform,
# normalizes what it left with .github/scripts/parity.py, and compares that with Fixtures/Parity/golden.json
# (#561). `mise run test-parity` runs it for each combination it is given.
#
#   .github/scripts/parity-fixture.sh <tool> <runner> <mode> [platform]
#
#   tool      swiftpm or xcode
#   runner    xctest or swift-testing
#   mode      serial or parallel
#   platform  macOS, the default
#
# Each run gets its own folder in PARITY_OUTPUT, or a temporary folder: the test output (output.log), the
# Cucumber JSON report (report.json), the trace (trace/) and the normalized result (result.json). With
# PARITY_GOLDEN=YES, the result is written to golden.json instead of compared, for a deliberate change to
# the suite, and with PARITY_GOLDEN=TESTS only the runner's test count is. The suite fails some scenarios on purpose, so the run's own exit status is part of the result,
# and this script fails only when the result differs.
set -u
tool=${1:?usage: parity-fixture.sh <swiftpm|xcode> <xctest|swift-testing> <serial|parallel> [platform]}
runner=${2:?usage: parity-fixture.sh <swiftpm|xcode> <xctest|swift-testing> <serial|parallel> [platform]}
mode=${3:?usage: parity-fixture.sh <swiftpm|xcode> <xctest|swift-testing> <serial|parallel> [platform]}
platform=${4:-macOS}
combination="$tool/$runner/$mode/$platform"
root="$(cd "$(dirname "$0")/../.." && pwd)"
fixture="$root/Fixtures/Parity"

case "$runner" in xctest|swift-testing) ;; *) echo "error: the runner must be xctest or swift-testing, not '$runner'" >&2; exit 2 ;; esac
case "$mode" in serial|parallel) ;; *) echo "error: the mode must be serial or parallel, not '$mode'" >&2; exit 2 ;; esac
if [ "$platform" != macOS ]; then
  echo "error: $combination: only macOS runs so far" >&2
  exit 2
fi

out="${PARITY_OUTPUT:-$(mktemp -d)}/${combination//\//-}"
rm -rf "$out"
mkdir -p "$out/trace"
log="$out/output.log"
report="$out/report.json"
echo "$combination: running, with its output in $out"

status=0
case "$tool" in
  swiftpm)
    args=(--package-path "$fixture/SwiftPM" --enable-code-coverage)
    if [ "$runner" = xctest ]; then args+=(--disable-swift-testing); else args+=(--disable-xctest); fi
    parallel=NO
    if [ "$mode" = parallel ]; then
      parallel=YES
      # Swift Testing runs the scenarios together in one process once CucumberSwift is told to. XCTest runs
      # them in worker processes with --parallel.
      if [ "$runner" = xctest ]; then args+=(--parallel); fi
    fi
    PARITY_TRACE_DIR="$out/trace" CUCUMBER_REPORT_PATH="$report" CUCUMBER_PARALLEL_TESTING=$parallel \
      swift test "${args[@]}" > "$log" 2>&1 || status=$?
    ;;
  xcode)
    # Generated here, not committed, as for the other Tuist fixtures. Resolving the project rewrites the
    # checkout's Package.resolved, so each step puts it back.
    "$root/.github/scripts/keep-package-resolved.sh" tuist generate --no-open --path "$fixture/Xcode" > "$out/generate.log" 2>&1 \
      || { cat "$out/generate.log"; echo "error: $combination: tuist generate failed" >&2; exit 1; }
    if [ "$runner" = xctest ]; then scheme=ParityXCTests; else scheme=ParitySwiftTests; fi
    args=(-project "$fixture/Xcode/Parity.xcodeproj" -scheme "$scheme" -destination 'platform=macOS'
      -derivedDataPath "${PARITY_DERIVED_DATA:-$fixture/Xcode/Derived}" -enableCodeCoverage YES
      -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO)
    parallel=NO
    if [ "$mode" = parallel ]; then
      parallel=YES
      # XCTest runs the scenarios in Xcode's worker processes. Swift Testing runs them together in one
      # process once CucumberSwift is told to, and Xcode's setting doesn't change that.
      args+=(-parallel-testing-enabled YES -parallel-testing-worker-count 3)
    else
      args+=(-parallel-testing-enabled NO)
    fi
    # xcodebuild passes each TEST_RUNNER_ variable to the tests without the prefix.
    TEST_RUNNER_PARITY_TRACE_DIR="$out/trace" TEST_RUNNER_CUCUMBER_REPORT_PATH="$report" \
      TEST_RUNNER_CUCUMBER_PARALLEL_TESTING=$parallel \
      "$root/.github/scripts/keep-package-resolved.sh" xcodebuild test "${args[@]}" > "$log" 2>&1 || status=$?
    ;;
  *)
    echo "error: the tool must be swiftpm or xcode, not '$tool'" >&2
    exit 2
    ;;
esac

# Xcode's parallel workers print to their own output, which xcodebuild's log leaves out, so the test count and the
# failures come from the result bundle, for every run it makes.
summary=()
if [ "$tool" = xcode ]; then
  bundle=$(sed -n '/^Test session results, code coverage, and logs:/{n;s/^[[:space:]]*//;p;}' "$log" | tail -1)
  if [ -n "$bundle" ] && cp -R "$bundle" "$out/result.xcresult" && xcrun xcresulttool get test-results tests --path "$bundle" > "$out/xcresult-tests.json" 2>/dev/null \
    && xcrun xcresulttool get test-results summary --path "$bundle" > "$out/xcresult-summary.json" 2>/dev/null; then
    summary=(--xcresult-summary "$out/xcresult-summary.json")
  else
    echo "error: $combination: xcodebuild left no result bundle that xcresulttool can read, in $log" >&2
    exit 1
  fi
fi
python3 "$root/.github/scripts/parity.py" normalize --combination "$combination" --log "$log" --report "$report" \
  --trace "$out/trace" --status "$status" --out "$out/result.json" ${summary[@]+"${summary[@]}"} || exit 1
if [ "${PARITY_GOLDEN:-}" = YES ]; then
  python3 "$root/.github/scripts/parity.py" golden --result "$out/result.json"
elif [ "${PARITY_GOLDEN:-}" = TESTS ]; then
  python3 "$root/.github/scripts/parity.py" golden --tests-only --result "$out/result.json"
else
  python3 "$root/.github/scripts/parity.py" compare --result "$out/result.json"
fi
