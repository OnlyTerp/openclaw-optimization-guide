#!/usr/bin/env bash
# scripts/ralph.sh — run the Ralph loop until PRD is done or budget is exhausted
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
cd "$PROJECT_ROOT"

[ ! -f PRD.json ]        && { echo "PRD.json missing"; exit 1; }
[ ! -f loop-prompt.md ]  && { echo "loop-prompt.md missing"; exit 1; }

max_iter=$(jq -r '.budget.max_iterations // 40'  PRD.json)
max_usd=$(jq  -r '.budget.max_usd // 20'         PRD.json)
max_hours=$(jq -r '.budget.max_wall_hours // 4'  PRD.json)

start=$(date +%s)
total_usd=0.00
i=0

while : ; do
  i=$((i+1))
  status=$(jq -r '.status' PRD.json)
  [ "$status" = "done" ] && { echo "[ralph] PRD.done — exiting at iter $i"; break; }

  elapsed=$(( ($(date +%s) - start) / 3600 ))
  [ "$elapsed" -ge "$max_hours" ] && { echo "[ralph] wall-clock budget exhausted"; break; }
  [ "$i" -gt "$max_iter" ]         && { echo "[ralph] iteration budget exhausted"; break; }

  echo "[ralph] === iter $i (elapsed ${elapsed}h, spent \$$total_usd) ==="

  # Fresh OpenClaw session per iteration. --ephemeral keeps it out of your main history.
  out_json=$(openclaw run \
      --prompt-file loop-prompt.md \
      --ephemeral \
      --output json)

  iter_usd=$(echo "$out_json" | jq -r '.usage.cost_usd // 0')
  total_usd=$(echo "$total_usd $iter_usd" | awk '{print $1 + $2}')

  (( $(echo "$total_usd >= $max_usd" | bc -l) )) && { echo "[ralph] USD budget exhausted"; break; }

  # Let the dreaming scheduler consolidate anything learned before the next iteration.
  sleep 2
done

# Final summary.
echo
echo "[ralph] final status=$(jq -r '.status' PRD.json) iterations=$i spent=\$${total_usd}"
jq '.tasks[] | {id, status}' PRD.json
