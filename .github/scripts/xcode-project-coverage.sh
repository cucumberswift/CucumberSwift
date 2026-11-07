#!/usr/bin/env bash
# Runs Fixtures/CoverageDefaultsTuist, an Xcode project tested with Code Coverage on, on an iOS, a tvOS
# and a watchOS Simulator and on Mac Catalyst (#538). Fixture tests runs it on macOS. On each destination,
# each runner, XCTest and Swift Testing, must give the Grading feature the scores expected-output lists,
# the ones it gets on macOS, and the fixture must run as many tests as expected-tests lists.
# Used by the nightly run of CI's tvOS and watchOS tests job.
#
#   mise exec -- .github/scripts/xcode-project-coverage.sh <log folder>
#
# Needs the Tuist that .mise.toml pins. Each destination's output goes to <log folder>.
set -uo pipefail

logs=${1:?usage: xcode-project-coverage.sh <log folder>}
name=CoverageDefaultsTuist
fixture="Fixtures/$name"
# The Grading feature's scores on macOS, the line expected-output lists.
scores=$(grep '^CucumberSwift coverage: Grading: ' "$fixture/expected-output")
if [[ -z "$scores" ]]; then
  echo "::error::$fixture/expected-output lists no scores for the Grading feature"
  exit 1
fi
mkdir -p "$logs"
# Resolving the project rewrites the checkout's Package.resolved, so each step puts it back.
.github/scripts/keep-package-resolved.sh tuist generate --no-open --path "$fixture" || exit 1

status=0
for platform in iOS tvOS watchOS Catalyst; do
  if [[ "$platform" = Catalyst ]]; then
    destination='platform=macOS,variant=Mac Catalyst'
  else
    destination=$(.github/scripts/simulator-destination.sh "$platform Simulator") || { status=1; continue; }
  fi
  log="$logs/$name-$platform.log"
  .github/scripts/keep-package-resolved.sh xcodebuild test -project "$fixture/$name.xcodeproj" -scheme "$name" \
    -destination "$destination" -derivedDataPath "$fixture/Derived/xcodebuild" \
    -skipMacroValidation -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO > "$log" 2>&1 || status=1
  grep -E 'error:|\*\* TEST (FAILED|SUCCEEDED)' "$log" | sort -u | head -20
  python3 .github/scripts/fixture_tests.py "$fixture" "$log" || status=1
  count=$(grep -cF "$scores" "$log" || true)
  echo "$platform: ${count:-0} coverage summaries with the macOS scores (2 expected, one for each runner)"
  if [[ "${count:-0}" -ne 2 ]]; then
    grep 'CucumberSwift coverage: Grading: ' "$log" | sort -u
    echo "::error::CucumberSwift gave the Grading feature the macOS scores ${count:-0} times on $platform, not 2."
    status=1
  fi
done
exit $status
