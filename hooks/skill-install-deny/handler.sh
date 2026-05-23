#!/usr/bin/env bash
# Hook 4: skill-install-deny
# Blocks skill installation for slugs outside the allowlist.
# Edit ALLOWED to add trusted namespaces for your org.
slug="${OPENCLAW_TOOL_ARGS_SLUG:-}"

ALLOWED=(
  "openclaw-team/*"
  "onlyterp/*"
  "peskye/*"
)

for pat in "${ALLOWED[@]}"; do
  if [[ "$slug" == $pat ]]; then
    exit 0
  fi
done

echo "BLOCKED by skill-install-deny: $slug is not in the allowlist." >&2
echo "To override: install manually after reviewing diff + tool scope." >&2
exit 2
