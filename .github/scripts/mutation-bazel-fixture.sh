#!/bin/bash
# Runs mutation testing on the Bazel test fixture in Tests/ with the command-line tool, as a Bazel project's
# script would, and checks the result against Tests/expected-mutants (#522):
#
#     .github/scripts/mutation-bazel-fixture.sh <cucumberswift module folder> <cucumberswift_expressions folder> [<folder for the reports and the log>]
#
# The tool builds //:CucumberSwiftCoverageTests with `bazel build` and code coverage, runs each mutant's
# scenarios with `bazel test`, and mutates the Grades library. .github/scripts/mutation_fixture.py then fails unless
# every mutant has the status that Tests/expected-mutants lists, and the output has a warning for each survivor. The
# tool needs the Macros trait for swift-syntax, and copies Tests/ to a temporary folder, where `..` doesn't reach CucumberSwift, so the modules come from the two
# folders the arguments name, as the Bazel job's other commands get them with --override_module.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <cucumberswift module folder> <cucumberswift_expressions folder> [<folder for the reports and the log>]" >&2
  exit 2
fi
repo=$(cd "$(dirname "$0")/../.." && pwd)
fixture="$repo/Tests"
folder="${3:-${RUNNER_TEMP:-$(mktemp -d)}}"
reports="$folder/mutation-Bazel"
log="$folder/mutation-Bazel.log"
rm -rf "$reports"

status=0
swift run --package-path "$repo" --traits Macros cucumberswift-mutation-test \
  --root "$fixture" --sources Grades --bazel-target //:CucumberSwiftCoverageTests \
  --bazel-arg "--override_module=cucumberswift=$1" --bazel-arg "--override_module=cucumberswift_expressions=$2" \
  --bazel-arg --xcode_version=26.2 \
  --format xcode --output "$reports" 2>&1 | tee "$log" || status=$?
if [[ "$status" -ne 0 ]]; then
  echo "::error::Bazel fixture: cucumberswift-mutation-test exited with $status"
  exit 1
fi
cd "$repo"
python3 .github/scripts/mutation_fixture.py "$fixture" "$reports" "$log"
