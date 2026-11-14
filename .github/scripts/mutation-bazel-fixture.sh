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
# coverage only the code under test. The disk cache and the repository cache are the ones that the Bazel job's
# earlier steps use (both in the folder of the third argument, $RUNNER_TEMP there), so the copy starts with what they
# built and fetched instead of cold.
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

# The seconds each part took, which the job's timings can't show: the tool prints its own output only when it ends.
started=$SECONDS

# The job's earlier steps leave a Bazel server for Tests/ running, with the memory it built up. The tool starts its
# own for the copy it makes, so stop the old one before the Swift build and the runs need the memory.
(cd "$fixture" && bazel shutdown) || echo "::notice::bazel shutdown failed, or no Bazel server was running."

# Our CI builds the tool once with .github/scripts/build-mutation-tool.sh, which it caches, and sets MUTATION_TOOL to
# its path. Without it, build the tool here on its own and run the binary, so a failure to start is not mistaken for a
# failed build.
if [[ -n "${MUTATION_TOOL:-}" ]]; then
  tool="$MUTATION_TOOL"
else
  build=(swift build --package-path "$repo" --traits Macros --product cucumberswift)
  "${build[@]}"
  tool="$("${build[@]}" --show-bin-path)/cucumberswift"
fi

built=$SECONDS

# What a run killed by a signal (status 128 + the signal) leaves to explain it: the memory, the processes that held it,
# the binary's signature and the kernel's own account of a kill.
diagnose() {
  echo "::group::The tool was killed by signal $(($1 - 128))"
  echo "Memory: $(sysctl -n hw.memsize) bytes"
  vm_stat || true
  memory_pressure 2>&1 | head -15 || true
  ps -Ao rss,comm -m | head -8 || true
  codesign --verify --strict -vv "$tool" 2>&1 || true
  log show --last 3m --predicate 'eventMessage CONTAINS[c] "killed" OR eventMessage CONTAINS[c] "AMFI" OR eventMessage CONTAINS[c] "memorystatus" OR eventMessage CONTAINS[c] "jetsam"' 2>&1 | tail -30 || true
  echo "::endgroup::"
}

status=0
"$tool" mutation-test \
  --root "$fixture" --sources Grades --bazel-target //:CucumberSwiftCoverageTests \
  --bazel-arg "--override_module=cucumberswift=$1" --bazel-arg "--override_module=cucumberswift_expressions=$2" \
  --bazel-disk-cache "$folder/bazel-disk-cache" --bazel-arg "--repository_cache=$folder/bazel-repository-cache" \
  --bazel-arg --instrumentation_filter=//:Grades --bazel-arg --xcode_version=26.2 \
  --format xcode --baseline-runs 1 --output "$reports" 2>&1 | tee "$log" || status=$?
echo "Bazel fixture timings: the tool's build $((built - started)) s, its run $((SECONDS - built)) s."
if [[ "$status" -gt 128 ]]; then diagnose "$status"; fi
if [[ "$status" -ne 0 ]]; then
  echo "::error::Bazel fixture: cucumberswift mutation-test exited with $status"
  exit 1
fi
cd "$repo"
python3 .github/scripts/mutation_fixture.py "$fixture" "$reports" "$log"
