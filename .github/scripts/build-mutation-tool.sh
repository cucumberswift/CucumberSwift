#!/bin/bash
# Builds the mutation testing tool once for a CI job, from this checkout, into a build folder that the job caches
# with actions/cache (#518):
#
#     .github/scripts/build-mutation-tool.sh <build folder>
#
# The tool is `cucumberswift`, whose `mutation-test` command runs mutation testing. It prints the tool's path, for the
# job's mutation steps to run. The cache restores the build folder of an earlier
# run, and SwiftPM rebuilds what changed since then: a fresh checkout recompiles CucumberSwift's own modules, but not
# swift-syntax. So a cache from older sources still builds the tool from this checkout's sources.
set -euo pipefail

folder=${1:?usage: build-mutation-tool.sh <build folder>}
repo=$(cd "$(dirname "$0")/../.." && pwd)
started=$(date +%s)
swift build --package-path "$repo" --scratch-path "$folder" --traits Macros --product cucumberswift >&2
echo "Built the mutation testing tool in $(($(date +%s) - started)) s." >&2
echo "$folder/debug/cucumberswift"
