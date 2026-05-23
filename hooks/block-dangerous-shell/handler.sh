#!/usr/bin/env bash
# Hook 1: block-dangerous-shell
# Blocks: rm -rf /, git reset --hard, git push --force to main/master/prod,
# curl|sh, dd of=/dev/, forkbombs.
# Exit 2 = hard block. Exit 0 = allow.
cmd="${OPENCLAW_TOOL_ARGS_COMMAND:-}"

deny_patterns=(
  'rm -rf /( |$)'
  'rm -rf [~/]+( |$)'
  'git reset --hard'
  'git push.*--force.*(main|master|prod)'
  'curl[^|]*\| *(sh|bash)'
  'dd .*of=/dev/'
  ':\(\)\{ :\|:& \};:'
)

for pat in "${deny_patterns[@]}"; do
  if [[ "$cmd" =~ $pat ]]; then
    echo "BLOCKED by block-dangerous-shell: matched /$pat/" >&2
    exit 2
  fi
done
exit 0
