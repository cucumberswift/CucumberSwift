#!/bin/bash
# Runs a command of the cucumberswift tool from the CucumberSwift checkout that Carthage made, for a Run Script
# build phase: `cucumberswift.sh lint --stamp … --features …`. Carthage builds only the framework, so the tool
# builds with SwiftPM from the same checkout, in a clean environment: Xcode's build settings in a Run Script
# phase (SDKROOT, the deployment target) would point SwiftPM at the iOS SDK instead of the Mac's.
#
# The checkout is $CUCUMBERSWIFT_CHECKOUT, or Carthage/Checkouts/CucumberSwift in the project. This fixture
# sets it to the CucumberSwift being tested, which plays the checkout's part.

set -euo pipefail

checkout="${CUCUMBERSWIFT_CHECKOUT:-${SRCROOT:?Run this from a Run Script build phase, or set CUCUMBERSWIFT_CHECKOUT.}/Carthage/Checkouts/CucumberSwift}"
exec env -i HOME="$HOME" PATH="$PATH" ${DEVELOPER_DIR:+DEVELOPER_DIR="$DEVELOPER_DIR"} \
  swift run --quiet --package-path "$checkout" --scratch-path "${CUCUMBERSWIFT_BUILD:-$checkout/.build}" cucumberswift "$@"
