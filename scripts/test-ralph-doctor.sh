#!/usr/bin/env bash
# scripts/test-ralph-doctor.sh — local test harness for ralph-doctor.sh.
#
# Six assertions, all run in a temporary REPO_ROOT so we never touch
# the live .ralph/ in the repo we're checked out in.
#
# Usage:
#   bash scripts/test-ralph-doctor.sh
#
# Exit 0 = all assertions passed. Exit 1 = at least one failed.

set -uo pipefail

REPO_ROOT_REAL="$(cd "$(dirname "$0")/.." && pwd)"
DOCTOR="$REPO_ROOT_REAL/scripts/ralph-doctor.sh"

if [ ! -x "$DOCTOR" ] && [ ! -f "$DOCTOR" ]; then
  echo "FAIL: cannot find $DOCTOR"
  exit 1
fi

PASS=0
FAIL=0

assert() {
  local name="$1" cond="$2"
  if [ "$cond" -eq 0 ]; then
    echo "  PASS: $name"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $name"
    FAIL=$((FAIL+1))
  fi
}

# Make a sandbox repo root with no bootstrap files, no git, no env
SANDBOX="$(mktemp -d -t ralph-doctor-test-XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

echo "=== test 1: missing bootstrap files trigger required_failed and exit 1 ==="
OUT="$(REPO_ROOT="$SANDBOX" bash "$DOCTOR" --json-only 2>/dev/null || true)"
EXIT_CODE_T1=$(REPO_ROOT="$SANDBOX" bash "$DOCTOR" --json-only >/dev/null 2>&1; echo $?)
assert "exit code is 1 when REQUIRED checks fail" "$([ "$EXIT_CODE_T1" -eq 1 ] && echo 0 || echo 1)"
assert "JSON contains required_failed summary" "$(printf '%s' "$OUT" | grep -q '"summary": "required_failed"' && echo 0 || echo 1)"

echo ""
echo "=== test 2: doctor.json is created in REPO_ROOT/.ralph/ ==="
REPORT="$SANDBOX/.ralph/doctor.json"
assert "doctor.json exists at $REPORT" "$([ -f "$REPORT" ] && echo 0 || echo 1)"

echo ""
echo "=== test 3: --quiet suppresses stderr human output ==="
STDERR_BYTES="$(REPO_ROOT="$SANDBOX" bash "$DOCTOR" --quiet 2>&1 >/dev/null | wc -c | tr -d ' ')"
assert "stderr is empty under --quiet" "$([ "${STDERR_BYTES:-0}" -eq 0 ] && echo 0 || echo 1)"

echo ""
echo "=== test 4: --json-only prints valid JSON to stdout ==="
JSON_OUT="$(REPO_ROOT="$SANDBOX" bash "$DOCTOR" --json-only 2>/dev/null || true)"
if command -v python3 >/dev/null 2>&1; then
  if printf '%s' "$JSON_OUT" | python3 -c 'import sys,json; json.load(sys.stdin)' >/dev/null 2>&1; then
    assert "stdout is parseable JSON" 0
  else
    assert "stdout is parseable JSON" 1
  fi
else
  # Best-effort sniff if python3 missing
  if printf '%s' "$JSON_OUT" | grep -q '"checks":'; then
    assert "stdout looks like JSON (no python3 to fully validate)" 0
  else
    assert "stdout looks like JSON (no python3 to fully validate)" 1
  fi
fi

echo ""
echo "=== test 5: required check names are all reported ==="
EXPECTED_NAMES=(
  "bootstrap_file:PROMPT.md"
  "bootstrap_file:AGENTS.md"
  "bootstrap_file:IMPLEMENTATION_PLAN.md"
  "ralph_dir_writable"
  "cli_claude"
  "anthropic_api_key"
  "git_author"
  "git_remote_auth"
  "gh_cli"
)
MISSING=0
for n in "${EXPECTED_NAMES[@]}"; do
  if ! printf '%s' "$JSON_OUT" | grep -q "\"name\":\"$n\""; then
    echo "    missing in JSON: $n"
    MISSING=$((MISSING+1))
  fi
done
assert "all required check names appear in checks[]" "$([ "$MISSING" -eq 0 ] && echo 0 || echo 1)"

echo ""
echo "=== test 6: passing bootstrap files alone is not enough — git/key still required_fail ==="
SANDBOX2="$(mktemp -d -t ralph-doctor-test2-XXXXXX)"
touch "$SANDBOX2/PROMPT.md" "$SANDBOX2/AGENTS.md" "$SANDBOX2/IMPLEMENTATION_PLAN.md"
EXIT_CODE_T6=$(REPO_ROOT="$SANDBOX2" bash "$DOCTOR" --json-only >/dev/null 2>&1; echo $?)
JSON2="$(REPO_ROOT="$SANDBOX2" bash "$DOCTOR" --json-only 2>/dev/null || true)"
assert "still exits 1 when bootstrap present but no git/keys" "$([ "$EXIT_CODE_T6" -eq 1 ] && echo 0 || echo 1)"
assert "JSON contains at least one anthropic_api_key entry" "$(printf '%s' "$JSON2" | grep -q '"name":"anthropic_api_key"' && echo 0 || echo 1)"
rm -rf "$SANDBOX2"

echo ""
echo "=== summary ==="
echo "PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
