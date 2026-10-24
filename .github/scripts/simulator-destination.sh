#!/usr/bin/env bash
# Prints the xcodebuild destination of a simulator on this runner, such as
# platform=tvOS Simulator,id=<udid>, for the jobs that run tests on one.
#
#   .github/scripts/simulator-destination.sh <iOS Simulator|tvOS Simulator|watchOS Simulator>
#
# The first iPhone, Apple TV or Apple Watch of the runtime the selected Xcode comes with, so the job doesn't
# depend on a device name: the newest runtime not newer than the Xcode's SDK, or else the oldest
# newer one of the same major version, or else the newest. A runner can have newer runtimes than
# an older Xcode, such as iOS 18.6 and 26.2 beside Xcode 16.4, and the tests run on the runtimes
# each Xcode comes with. The runtime goes to stderr, for the job's log.
set -euo pipefail

case "${1:-}" in
  "iOS Simulator") runtime="iOS"; device="iPhone"; sdk="iphonesimulator" ;;
  "tvOS Simulator") runtime="tvOS"; device="Apple TV"; sdk="appletvsimulator" ;;
  "watchOS Simulator") runtime="watchOS"; device="Apple Watch"; sdk="watchsimulator" ;;
  *)
    echo "usage: $0 <iOS Simulator|tvOS Simulator|watchOS Simulator>" >&2
    exit 2 ;;
esac

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
match = next(((r, d) for r in runtimes for d in devices[r] if d["name"].startswith(os.environ["DEVICE"])), None)
if match:
    runtime, device = match
    print(device["name"] + ", " + runtime.rsplit(".", 1)[1] + ", for SDK " + os.environ["SDK_VERSION"], file=sys.stderr)
    print(device["udid"])
')
if [[ -z "$udid" ]]; then
  echo "::error::No $device simulator is available on this runner." >&2
  exit 1
fi
echo "platform=$1,id=$udid"
