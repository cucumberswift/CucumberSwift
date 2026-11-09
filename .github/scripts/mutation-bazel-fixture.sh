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
# folders the arguments name, as the Bazel job's other commands get them with --override_module. Tests/.bazelrc
# applies its instrumentation filter to `bazel coverage` only, so the run passes the filter itself and builds with
# coverage only the code under test.
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

# The job's earlier steps leave a Bazel server for Tests/ running, with the memory it built up. The tool starts its
# own for the copy it makes, so stop the old one before the Swift build and the runs need the memory.
(cd "$fixture" && bazel shutdown) || true

# Build the tool on its own and run the binary, so a failure to start is not mistaken for a failed build.
build=(swift build --package-path "$repo" --traits Macros --product cucumberswift-mutation-test)
"${build[@]}"
tool="$("${build[@]}" --show-bin-path)/cucumberswift-mutation-test"

# What a run killed by a signal (status 128 + the signal) leaves to explain it: the memory, the processes that held it,
# the binary's signature and the kernel's own account of a kill.
diagnose() {
  echo "::group::The tool was killed by signal $(($1 - 128))"
  echo "Memory: $(sysctl -n hw.memsize) bytes"
  vm_stat || true
  memory_pressure 2>&1 | head -15 || true
  ps -Ao rss,comm -m | head -8 || true
  codesign --verify --verbose=2 "$tool" 2>&1 || true
  log show --last 15m --predicate 'eventMessage CONTAINS[c] "jetsam" OR eventMessage CONTAINS[c] "memorystatus" OR eventMessage CONTAINS[c] "cucumberswift-mutation-test"' 2>&1 | tail -30 || true
  echo "::endgroup::"
}

status=0
"$tool" \
  --root "$fixture" --sources Grades --bazel-target //:CucumberSwiftCoverageTests \
  --bazel-arg "--override_module=cucumberswift=$1" --bazel-arg "--override_module=cucumberswift_expressions=$2" \
  --bazel-arg --instrumentation_filter=//:Grades --bazel-arg --xcode_version=26.2 \
  --format xcode --output "$reports" 2>&1 | tee "$log" || status=$?
if [[ "$status" -gt 128 ]]; then diagnose "$status"; fi
if [[ "$status" -ne 0 ]]; then
  echo "::error::Bazel fixture: cucumberswift-mutation-test exited with $status"
  exit 1
fi
cd "$repo"
python3 .github/scripts/mutation_fixture.py "$fixture" "$reports" "$log"
