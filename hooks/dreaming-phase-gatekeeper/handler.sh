#!/usr/bin/env bash
# Hook 5: dreaming-phase-gatekeeper
# Blocks the stop signal if a dreaming memory sweep is still in progress.
state="${OPENCLAW_VAULT:-.}/memory/.dreams/state.json"
[ ! -f "$state" ] && exit 0

last=$(jq -r '.lastSweep.phase // "none"' "$state" 2>/dev/null || echo "none")
status=$(jq -r '.lastSweep.status // "none"' "$state" 2>/dev/null || echo "none")

if [ "$status" = "in_progress" ]; then
  echo "BLOCKED: dreaming sweep is mid-$last; wait or force-resume." >&2
  exit 2
fi
exit 0
