#!/usr/bin/env bash
# scripts/fan-out.sh <tasks-dir>
set -euo pipefail
tasks_dir="$(realpath "${1:?pass a directory containing one *.md task-prompt per agent}")"
base_repo="$(pwd)"

mkdir -p "$base_repo/.worktrees"
declare -a pids=()

for task in "$tasks_dir"/*.md; do
  abs_task="$(realpath "$task")"   # pin before we cd into the worktree
  name=$(basename "$task" .md)
  wt="$base_repo/.worktrees/$name"
  branch="agent/$name"

  git worktree add "$wt" -b "$branch" >/dev/null
  (
    cd "$wt"
    openclaw run --prompt-file "$abs_task" --ephemeral --output json \
      > "$base_repo/.worktrees/$name.log" 2>&1
  ) &
  pids+=($!)
  echo "[fan-out] spawned $name (pid ${pids[-1]}) in $wt"
done

# Don't let one failing agent orphan the rest: track failures but keep waiting.
set +e
failures=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failures++))
done
set -e
echo "[fan-out] all agents done ($failures failed of ${#pids[@]}). Branches: agent/*"
[[ $failures -eq 0 ]] || exit 1
