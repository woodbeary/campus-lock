#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

min_line_coverage="${COVERAGE_MIN_LINES:-80}"

swift test --enable-code-coverage

codecov_json="$(swift test --show-codecov-path)"
profdata="$(dirname "$codecov_json")/default.profdata"
test_binary="$(find .build -path '*/debug/CampusLockPackageTests.xctest/Contents/MacOS/CampusLockPackageTests' -type f | head -n 1)"

if [[ -z "$test_binary" || ! -f "$test_binary" ]]; then
  echo "Missing SwiftPM test binary for coverage report."
  exit 1
fi

if [[ ! -f "$profdata" ]]; then
  echo "Missing coverage profile at $profdata."
  exit 1
fi

report="$(xcrun llvm-cov report \
  "$test_binary" \
  -instr-profile "$profdata" \
  -ignore-filename-regex='Tests|CampusLockPackageTests|runner.swift')"

echo "$report"

line_coverage="$(awk '$1 == "TOTAL" { gsub("%", "", $10); print $10 }' <<<"$report")"

if [[ -z "$line_coverage" ]]; then
  echo "Could not parse TOTAL line coverage."
  exit 1
fi

python3 - "$line_coverage" "$min_line_coverage" <<'PY'
import sys

line_coverage = float(sys.argv[1])
minimum = float(sys.argv[2])

if line_coverage < minimum:
    print(f"Line coverage {line_coverage:.2f}% is below required {minimum:.2f}%.")
    raise SystemExit(1)

print(f"Line coverage {line_coverage:.2f}% meets required {minimum:.2f}%.")
PY
