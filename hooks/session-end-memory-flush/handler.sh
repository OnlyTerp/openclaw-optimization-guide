#!/usr/bin/env bash
# Hook 8: session-end-memory-flush
# Appends session summary to dreaming inbox before compaction.
# Feeds the Deep-phase scoring loop without any manual effort.
inbox="${OPENCLAW_VAULT:-.}/memory/dreaming/inbox/$(date -u +%Y-%m-%d).md"
mkdir -p "$(dirname "$inbox")"

{
  echo ""
  echo "### session ${OPENCLAW_SESSION_ID:-unknown} — $(date -uIseconds)"
  echo "**agent:** ${OPENCLAW_AGENT_ROLE:-main}"
  echo "**turns:** ${OPENCLAW_TURN_COUNT:-?}"
  echo "**tokens:** ${OPENCLAW_TOKEN_TOTAL:-?}"
  echo ""
  echo "${OPENCLAW_SESSION_SUMMARY:-(no summary provided)}"
} >> "$inbox" 2>/dev/null || true
exit 0
