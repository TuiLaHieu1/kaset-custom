#!/usr/bin/env bash
set -euo pipefail

FILTER="${1:-ParserPerformanceTests}"
LABEL="${2:-$(date -u +%Y%m%dT%H%M%SZ)-$(git rev-parse --short HEAD)}"
BENCH_ROOT="${BENCH_ROOT:-}"
if [[ -z "$BENCH_ROOT" ]]; then
  BENCH_ROOT="/tmp/kaset-perf2-bench"
fi
OUT="$BENCH_ROOT/$LABEL"
mkdir -p "$OUT"

{
  echo "filter=$FILTER"
  echo "label=$LABEL"
  date -u
  git rev-parse HEAD
  sw_vers
  swift --version
  xcodebuild -version 2>/dev/null || true
} | tee "$OUT/env.txt"

run_tests() {
  local mode="$1"
  if [[ "$mode" == "skip-build" ]]; then
    swift test -c release --skip-build --filter "$FILTER" --skip KasetUITests
  else
    swift test -c release --filter "$FILTER" --skip KasetUITests
  fi
}

set +e
run_tests build-and-run 2>&1 | tee "$OUT/test.log"
status=${PIPESTATUS[0]}
set -e

perl -ne 'if (/Test Case '\''-\[.* ([^\] ]+)\]'\'' measured \[[^\]]+\] average: ([0-9.]+)/) { print "$1\t$2\n" }' \
  "$OUT/test.log" | tee "$OUT/performance.tsv"

printf 'benchmark_dir=%s\n' "$OUT" | tee "$OUT/location.txt"
exit "$status"
