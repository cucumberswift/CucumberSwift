#!/bin/bash
# Temporary, for #491: measures how many workers the parallel fixture uses, per testing unit and worker count.
# Runs .github/scripts/parallel-fixture.sh with UNIT=both REPEATS times at each of WORKERS_LIST, alternating the
# worker counts, and writes one TSV row per unit run to parallel-measure/results.tsv, with each run's logs and
# records listing beside it. It never fails on a fixture failure: that is a result, recorded in the row.
#
#   PLATFORM=... KIND=... [WORKERS_LIST="2 3"] [REPEATS=3] .github/scripts/parallel-measure.sh
set -u
WORKERS_LIST=${WORKERS_LIST:-2 3}
REPEATS=${REPEATS:-3}
out=parallel-measure
temp=${RUNNER_TEMP:-$(mktemp -d)}
mkdir -p "$out"
results="$out/results.tsv"
printf "xcode\tplatform\tkind\tworkers\trep\tunit\tscenario_workers\tcontrol_workers\ttesting_s\tpassed\tfailed\tfixture_status\tclone_warning\tdestinations\n" > "$results"
xcode=$(xcodebuild -version | head -1 | awk '{print $2}')
for rep in $(seq 1 "$REPEATS"); do
  for workers in $WORKERS_LIST; do
    run="$out/w$workers-r$rep"
    mkdir -p "$run"
    echo "::group::$PLATFORM $KIND, $workers workers, repeat $rep"
    WORKERS=$workers UNIT=both .github/scripts/parallel-fixture.sh > "$run/fixture.out" 2>&1
    status=$?
    tail -40 "$run/fixture.out"
    echo "::endgroup::"
    for unit in scenario feature; do
      log="parallel-test-$unit.log"
      records="$temp/parallel-test-records-$unit"
      ls "$records" > "$run/records-$unit.txt" 2>/dev/null
      scenario_workers=$(awk -F. '$3 == "scenario" { print $1 }' "$run/records-$unit.txt" | sort -u | wc -l | tr -d ' ')
      control_workers=$(grep -oE "PlainXCTestControl[0-9]+.* (passed|failed) on '[^']*'" "$log" 2>/dev/null \
        | sed -E "s/^.* on '//; s/'$//" | sort -u | wc -l | tr -d ' ')
      # Xcode's own time for the test action, without the build.
      testing=$(grep -oE '[0-9.]+ elapsed -- Testing started completed' "$log" 2>/dev/null | tail -1 | awk '{print $1}')
      passed=$(grep -cE "^Test [Cc]ase .* passed" "$log" 2>/dev/null)
      failed=$(grep -cE "^Test [Cc]ase .* failed" "$log" 2>/dev/null)
      warning=$(grep -c "Only .* clones ran scenarios in the $unit run" "$run/fixture.out")
      # The run destinations (Simulator clones, or My Mac) that ran any test, without their process IDs.
      destinations=$(grep -ohE "(passed|failed) on '[^']*'" "$log" 2>/dev/null | sed -E "s/^.* on '//; s/ - .*//" | sort -u | paste -sd ';' -)
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$xcode" "$PLATFORM" "$KIND" "$workers" "$rep" "$unit" \
        "$scenario_workers" "$control_workers" "${testing:-NA}" "$passed" "$failed" "$status" "$warning" "${destinations:-NA}" >> "$results"
      mv "$log" "$run/" 2>/dev/null
    done
  done
done
column -t -s $'\t' "$results"
{ echo '```'; column -t -s $'\t' "$results"; echo '```'; } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
exit 0
