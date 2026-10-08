#!/usr/bin/env bash
# Runs Fixtures/SwiftTestingAndXCTestMacrosTuist with an older Xcode: an Xcode project that uses the
# step definition macros through a local package that turns on CucumberSwift's Macros trait, the
# route "Checking Step Definitions" gives for Xcode 16.3 to 26.3. Fixture tests runs the fixture
# with a newer Xcode. Used by CI's Catalyst tests (Xcode 16) job.
#
#   [TUIST_DEVELOPER_DIR=<a newer Xcode's Contents/Developer>] .github/scripts/macros-trait-fixture.sh <version>
#
# The version is an Xcode at /Applications/Xcode_<version>.app, such as 16.3. The fixture runs on an
# iPhone simulator of that Xcode's own iOS version, installing that iOS platform if it is missing.
# The pinned Tuist can't generate projects with Xcode 16.0's Swift 6.0, so TUIST_DEVELOPER_DIR can
# name a newer Xcode for that step.
set -euo pipefail

version=${1:?usage: macros-trait-fixture.sh <version>}
export DEVELOPER_DIR="/Applications/Xcode_${version}.app/Contents/Developer"
if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "::error::Xcode $version is not at /Applications/Xcode_${version}.app" >&2
  exit 1
fi
name=SwiftTestingAndXCTestMacrosTuist
fixture="Fixtures/$name"
# sed reads to the end: head would close the pipe early, and xcodebuild aborts on the broken pipe.
xcodebuild -version | sed -n 1p

ios=$(xcrun --sdk iphonesimulator --show-sdk-version)
runtime="com.apple.CoreSimulator.SimRuntime.iOS-${ios//./-}"
# Downloading a platform fails with "Unable to connect to simulator" until simctl has started the
# simulator service.
if ! xcrun simctl list runtimes | grep -q "$runtime"; then
  start=$(date +%s)
  xcodebuild -downloadPlatform iOS
  echo "Installed the iOS $ios platform in $(( $(date +%s) - start )) seconds"
fi
udid=$(xcrun simctl create "$name iPhone" "iPhone 16" "$runtime")
trap 'xcrun simctl delete "$udid" 2>/dev/null || true' EXIT

if [[ -n "${TUIST_DEVELOPER_DIR:-}" ]]; then
  DEVELOPER_DIR="$TUIST_DEVELOPER_DIR" tuist generate --no-open --path "$fixture"
else
  tuist generate --no-open --path "$fixture"
fi
derived="$fixture/Derived/xcodebuild-$version"
find "$derived" -name '*.lint-stamp' -delete 2>/dev/null || true
log=$(mktemp)
status=0
xcodebuild test -project "$fixture/$name.xcodeproj" -scheme "$name" -destination "platform=iOS Simulator,id=$udid" \
  -derivedDataPath "$derived" -skipMacroValidation CODE_SIGNING_ALLOWED=NO > "$log" 2>&1 || status=$?
grep -E '^Test (Suite|Case) .*(passed|failed)|✔|✘|error: |\*\* TEST' "$log" | tail -40 || true
if [[ "$status" -ne 0 ]]; then
  echo "::error::$name failed with Xcode $version" >&2
  exit "$status"
fi
# The warnings from CucumberSwift, as mise run test-fixtures checks them.
.github/scripts/fixture-warnings.sh "$fixture" "$log"
echo "$name passed with Xcode $version on iOS $ios"
