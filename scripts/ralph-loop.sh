#!/usr/bin/env bash
# scripts/ralph-loop.sh — Ralph audit loop for openclaw-optimization-guide
#
# Reads PROMPT.md, AGENTS.md, IMPLEMENTATION_PLAN.md every iteration.
# Runs the next unchecked iteration. Greps IMPLEMENTATION_PLAN.md for
# "STATUS: COMPLETE" to exit 0.
#
# Designed for clawadmin@167.99.237.49 but runs anywhere with the env set.
#
# Triggered by:
#   - .github/workflows/ralph-loop.yml (workflow_dispatch from iPad)
#   - manual: bash scripts/ralph-loop.sh

set -uo pipefail

# ---------- Configuration ----------
MAX_ITERS="${MAX_ITERS:-6}"
MAX_SECONDS="${MAX_SECONDS:-3600}"
RETRY_LIMIT="${RETRY_LIMIT:-1}"
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RALPH_DIR="$REPO_ROOT/.ralph"
LOG="$RALPH_DIR/ralph.log"
STATUS_FILE="$RALPH_DIR/status.json"
ITER_LOG_DIR="$RALPH_DIR/iterations"

cd "$REPO_ROOT" || { echo "FATAL: cannot cd to $REPO_ROOT"; exit 2; }

# ---------- Logging ----------
mkdir -p "$RALPH_DIR" "$ITER_LOG_DIR"
touch "$LOG"

log() {
  local msg
  msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
  echo "$msg" | tee -a "$LOG"
}

# ---------- Env loading ----------
# Try common env file locations so the loop picks up ANTHROPIC_API_KEY etc
# without depending on systemd EnvironmentFile or shell rc.
for envfile in \
  "$REPO_ROOT/.ralph/.env" \
  "$HOME/.openclaw/.env" \
  "$HOME/.config/openclaw/.env" \
  "/etc/openclaw/.env"; do
  if [ -f "$envfile" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$envfile"
    set +a
    log "Loaded env from $envfile"
    break
  fi
done

# ---------- Preflight ----------
preflight() {
  local errors=0

  log "=== Preflight ==="
  log "Repo root: $REPO_ROOT"
  log "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  log "HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

  # Required files
  for f in PROMPT.md AGENTS.md IMPLEMENTATION_PLAN.md; do
    if [ ! -f "$REPO_ROOT/$f" ]; then
      log "FAIL: missing $f at repo root"
      errors=$((errors+1))
    else
      log "OK: $f present ($(wc -l <"$REPO_ROOT/$f") lines)"
    fi
  done

  # API key
  if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    log "FAIL: ANTHROPIC_API_KEY not set. Sonnet calls will 401 and fall back to free tier."
    log "  Fix: add ANTHROPIC_API_KEY=... to one of:"
    log "    $REPO_ROOT/.ralph/.env"
    log "    \$HOME/.openclaw/.env"
    errors=$((errors+1))
  else
    log "OK: ANTHROPIC_API_KEY present (length ${#ANTHROPIC_API_KEY})"
  fi

  # Optional but recommended
  for k in OPENROUTER_API_KEY DEEPSEEK_API_KEY; do
    if [ -z "${!k:-}" ]; then
      log "WARN: $k not set (fallback chain partially degraded)"
    else
      log "OK: $k present"
    fi
  done

  # Claude / OpenCode CLI
  local cli=""
  if command -v claude >/dev/null 2>&1; then
    cli="claude"
    log "OK: claude CLI at $(command -v claude)"
  elif command -v opencode >/dev/null 2>&1; then
    cli="opencode"
    log "OK: opencode CLI at $(command -v opencode)"
  else
    log "FAIL: neither 'claude' nor 'opencode' on PATH"
    errors=$((errors+1))
  fi
  echo "$cli" > "$RALPH_DIR/cli.txt"

  # Ollama for Memory Bridge (iteration 1+)
  if curl -fsS --max-time 3 http://localhost:11434/api/tags >/dev/null 2>&1; then
    if curl -fsS --max-time 3 http://localhost:11434/api/tags | grep -q "qwen3-embedding"; then
      log "OK: Ollama running with qwen3-embedding model"
    else
      log "WARN: Ollama running but qwen3-embedding:0.6b not pulled"
      log "  Fix: ollama pull qwen3-embedding:0.6b"
    fi
  else
    log "WARN: Ollama not reachable at localhost:11434 (Memory Bridge iter 1 will fail)"
  fi

  # Git author
  if [ -z "$(git config user.email 2>/dev/null)" ] || [ -z "$(git config user.name 2>/dev/null)" ]; then
    log "WARN: git user.email/user.name not configured. Setting Ralph defaults."
    git config user.email "ralph@openclaw.local" 2>/dev/null || true
    git config user.name "Ralph (OpenClaw)" 2>/dev/null || true
  fi
  log "OK: git author $(git config user.name) <$(git config user.email)>"

  # Push auth
  if git ls-remote --heads origin >/dev/null 2>&1; then
    log "OK: git remote reachable"
  else
    log "FAIL: git ls-remote origin failed. Cannot push branches or open PRs."
    log "  Fix: ensure deploy key, gh auth, or PAT is configured for clawadmin"
    errors=$((errors+1))
  fi

  # gh CLI for PR creation (preferred path)
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    log "OK: gh CLI authenticated"
  else
    log "WARN: gh CLI not authenticated. PRs will need to be opened manually."
  fi

  # .ralph writable
  if ! touch "$RALPH_DIR/.write-test" 2>/dev/null; then
    log "FAIL: cannot write to $RALPH_DIR"
    errors=$((errors+1))
  else
    rm -f "$RALPH_DIR/.write-test"
    log "OK: .ralph/ writable"
  fi

  if [ "$errors" -gt 0 ]; then
    log "=== Preflight FAILED with $errors errors. Aborting before any LLM call. ==="
    return 1
  fi
  log "=== Preflight PASSED ==="
  return 0
}

# ---------- Status helpers ----------
write_status() {
  local state="$1"
  local iter="$2"
  local note="${3:-}"
  cat > "$STATUS_FILE" <<EOF
{
  "state": "$state",
  "iteration": $iter,
  "note": "$note",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "head": "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)",
  "branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
}
EOF
}

# ---------- Completion check ----------
is_complete() {
  if grep -q "^STATUS: COMPLETE$" "$REPO_ROOT/IMPLEMENTATION_PLAN.md" 2>/dev/null; then
    return 0
  fi
  return 1
}

# ---------- Iteration runner ----------
run_iteration() {
  local n="$1"
  local cli
  cli="$(cat "$RALPH_DIR/cli.txt" 2>/dev/null || echo claude)"
  local iter_log
  iter_log="$ITER_LOG_DIR/iter-$(printf '%03d' "$n").log"

  log "--- Iteration $n start (cli=$cli) ---"
  write_status "running" "$n" "iteration in progress"

  # Hard checkout to master before each iteration so each iteration branches
  # from a clean tip. Iterations themselves create claude/iter-NN-* branches.
  git fetch origin master --quiet 2>/dev/null || true
  git checkout master --quiet 2>/dev/null || true
  git pull --ff-only origin master --quiet 2>/dev/null || true

  # Standing prompt: the three files plus a wrapper instruction.
  local prompt
  prompt="$(cat <<'PROMPT_END'
You are Ralph. Read these three files in order and execute the NEXT UNCHECKED iteration in IMPLEMENTATION_PLAN.md.

  1. PROMPT.md  (standing instructions)
  2. AGENTS.md  (operating rules, PRESERVE list, build lane, keep-going rules)
  3. IMPLEMENTATION_PLAN.md  (numbered iterations)

Hard rules:
  - Do exactly one iteration this run.
  - Create a branch claude/iter-NN-<slug>, commit, push, open a PR.
  - Tick the iteration's checkboxes in IMPLEMENTATION_PLAN.md on the same branch.
  - Append a one-line summary to .ralph/ralph.log.
  - Never modify PRESERVE items. Never run `git push --force`.
  - If the iteration cannot complete, write the reason to .ralph/notes.md and exit cleanly without ticking checkboxes.

Begin.
PROMPT_END
)"

  local attempt=0
  local exit_code=1
  while [ "$attempt" -le "$RETRY_LIMIT" ]; do
    attempt=$((attempt+1))
    log "Iteration $n attempt $attempt with $cli"
    if [ "$cli" = "claude" ]; then
      # bypassPermissions lets claude write/commit/push without interactive prompts.
      # Fall back to --dangerously-skip-permissions on older claude builds (<2.1).
      if claude --help 2>&1 | grep -q -- '--permission-mode'; then
        printf '%s\n' "$prompt" | claude --print --output-format text --permission-mode bypassPermissions >>"$iter_log" 2>&1
      else
        printf '%s\n' "$prompt" | claude --print --output-format text --dangerously-skip-permissions >>"$iter_log" 2>&1
      fi
      exit_code=$?
    elif [ "$cli" = "opencode" ]; then
      # opencode equivalent: run with auto-approve so file/git ops do not block.
      printf '%s\n' "$prompt" | opencode run --model anthropic/sonnet --auto-approve >>"$iter_log" 2>&1
      exit_code=$?
    else
      log "FAIL: no CLI configured"
      return 1
    fi
    if [ "$exit_code" -eq 0 ]; then
      break
    fi
    log "Iteration $n attempt $attempt exited $exit_code, retrying"
  done

  log "--- Iteration $n end (exit=$exit_code) ---"
  return "$exit_code"
}

# ---------- Main loop ----------
main() {
  log "############################################################"
  log "Ralph loop start  pid=$$  max_iters=$MAX_ITERS  budget=${MAX_SECONDS}s"
  log "############################################################"

  if ! preflight; then
    write_status "preflight_failed" 0 "see ralph.log"
    exit 3
  fi

  # ---------- Dependency doctor ----------
  log "=== Doctor ==="
  if ! bash "$REPO_ROOT/scripts/ralph-doctor.sh" --quiet; then
    log "Doctor: REQUIRED checks failed. See $RALPH_DIR/doctor.json"
    write_status "doctor_failed" 0 "see .ralph/doctor.json"
    exit 5
  fi
  log "Doctor: OK (see $RALPH_DIR/doctor.json)"

  if is_complete; then
    log "STATUS: COMPLETE already present. Nothing to do."
    write_status "already_complete" 0 ""
    exit 0
  fi

  local start_ts
  start_ts="$(date +%s)"
  local n=0

  while [ "$n" -lt "$MAX_ITERS" ]; do
    n=$((n+1))
    local now elapsed
    now="$(date +%s)"
    elapsed=$((now - start_ts))
    if [ "$elapsed" -ge "$MAX_SECONDS" ]; then
      log "Time budget exhausted after $elapsed s. Stopping."
      write_status "time_budget" "$n" "exceeded ${MAX_SECONDS}s"
      exit 0
    fi

    if is_complete; then
      log "STATUS: COMPLETE detected after iteration $((n-1)). Exiting clean."
      write_status "complete" "$((n-1))" ""
      exit 0
    fi

    if ! run_iteration "$n"; then
      log "Iteration $n failed after retries. Stopping loop."
      write_status "iteration_failed" "$n" "see iterations/iter-$(printf '%03d' "$n").log"
      exit 4
    fi
  done

  log "Reached MAX_ITERS=$MAX_ITERS without STATUS: COMPLETE. Exiting for re-run."
  write_status "max_iters" "$n" "re-run loop to continue"
  exit 0
}

main "$@"
