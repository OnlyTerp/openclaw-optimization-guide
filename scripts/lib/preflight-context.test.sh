#!/usr/bin/env bash
# Test for scripts/lib/preflight-context.js (Memory Bridge preflight)
# Asserts the JSON output has all required keys per IMPLEMENTATION_PLAN.md iter-01.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="$SCRIPT_DIR/preflight-context.js"

PASS=0
FAIL=0

pass() { echo "ok   - $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL - $1"; FAIL=$((FAIL+1)); }

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "FAIL - jq is required for this test"
    exit 2
  fi
}
require_node() {
  if ! command -v node >/dev/null 2>&1; then
    echo "FAIL - node is required for this test"
    exit 2
  fi
}

require_jq
require_node

if [ ! -f "$TARGET" ]; then
  fail "script exists at $TARGET"
  echo "1..1"
  echo "Tests: $PASS passed, $FAIL failed"
  exit 1
fi

TMP_OUT=$(mktemp)
TMP_ERR=$(mktemp)
trap 'rm -f "$TMP_OUT" "$TMP_ERR"' EXIT

# Happy path: run against this repo
if node "$TARGET" "$REPO_ROOT" >"$TMP_OUT" 2>"$TMP_ERR"; then
  pass "exit 0 on valid repo path"
else
  fail "exit 0 on valid repo path (stderr: $(cat "$TMP_ERR"))"
fi

# stdout must be valid JSON
if jq -e . >/dev/null 2>&1 <"$TMP_OUT"; then
  pass "stdout is valid JSON"
else
  fail "stdout is valid JSON (got: $(head -c 200 "$TMP_OUT"))"
fi

assert_key() {
  local key="$1"
  if jq -e "$key" >/dev/null 2>&1 <"$TMP_OUT"; then
    pass "JSON has $key"
  else
    fail "JSON has $key"
  fi
}

# Required keys per iter-01 spec
assert_key '.schema'
assert_key '.repo'
assert_key '.repo.path'
assert_key '.repo.name'
assert_key '.repo.branch'
assert_key '.repo.head'
assert_key '.repo.totalFiles'
assert_key '.gitLog'
assert_key '.todoFixme'
assert_key '.todoFixme.todo'
assert_key '.todoFixme.fixme'
assert_key '.fileCountByExtension'
assert_key '.largestFiles'
assert_key '.partFiles'

# Type / shape assertions
if [ "$(jq '.gitLog | type' <"$TMP_OUT")" = '"array"' ]; then
  pass ".gitLog is an array"
else
  fail ".gitLog is an array"
fi

GIT_LOG_LEN=$(jq '.gitLog | length' <"$TMP_OUT")
if [ "$GIT_LOG_LEN" -gt 0 ] && [ "$GIT_LOG_LEN" -le 20 ]; then
  pass ".gitLog has 1..20 entries (got $GIT_LOG_LEN)"
else
  fail ".gitLog has 1..20 entries (got $GIT_LOG_LEN)"
fi

if [ "$(jq '.largestFiles | type' <"$TMP_OUT")" = '"array"' ]; then
  pass ".largestFiles is an array"
else
  fail ".largestFiles is an array"
fi

LARGEST_LEN=$(jq '.largestFiles | length' <"$TMP_OUT")
if [ "$LARGEST_LEN" -le 10 ] && [ "$LARGEST_LEN" -gt 0 ]; then
  pass ".largestFiles has 1..10 entries (got $LARGEST_LEN)"
else
  fail ".largestFiles has 1..10 entries (got $LARGEST_LEN)"
fi

if [ "$(jq '.partFiles | type' <"$TMP_OUT")" = '"array"' ]; then
  pass ".partFiles is an array"
else
  fail ".partFiles is an array"
fi

# This repo contains part*.md files at root, so the array should be non-empty
PART_LEN=$(jq '.partFiles | length' <"$TMP_OUT")
if [ "$PART_LEN" -gt 0 ]; then
  pass ".partFiles is non-empty for this repo (got $PART_LEN)"
else
  fail ".partFiles is non-empty for this repo (got $PART_LEN)"
fi

# Each largestFiles entry should have path and sizeBytes
if jq -e 'all(.largestFiles[]; has("path") and has("sizeBytes"))' >/dev/null <"$TMP_OUT"; then
  pass ".largestFiles entries have path + sizeBytes"
else
  fail ".largestFiles entries have path + sizeBytes"
fi

if jq -e 'all(.partFiles[]; has("name") and has("sizeBytes"))' >/dev/null <"$TMP_OUT"; then
  pass ".partFiles entries have name + sizeBytes"
else
  fail ".partFiles entries have name + sizeBytes"
fi

if jq -e 'all(.gitLog[]; has("sha") and has("subject"))' >/dev/null <"$TMP_OUT"; then
  pass ".gitLog entries have sha + subject"
else
  fail ".gitLog entries have sha + subject"
fi

# Failure mode: invalid path → exit 1, stdout empty, stderr is JSON error
TMP_OUT2=$(mktemp)
TMP_ERR2=$(mktemp)
if node "$TARGET" "/nonexistent/path/that/should/not/exist" >"$TMP_OUT2" 2>"$TMP_ERR2"; then
  fail "exit 1 on bad repo path"
else
  pass "exit 1 on bad repo path"
fi

if [ ! -s "$TMP_OUT2" ]; then
  pass "stdout empty on failure (no partial output)"
else
  fail "stdout empty on failure (got $(wc -c <"$TMP_OUT2") bytes)"
fi

if jq -e . >/dev/null 2>&1 <"$TMP_ERR2"; then
  pass "stderr is structured JSON on failure"
else
  fail "stderr is structured JSON on failure (got: $(head -c 200 "$TMP_ERR2"))"
fi

rm -f "$TMP_OUT2" "$TMP_ERR2"

TOTAL=$((PASS+FAIL))
echo "1..$TOTAL"
echo "Tests: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
  exit 1
fi
exit 0
