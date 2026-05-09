#!/usr/bin/env bash
# scripts/ralph-doctor.sh — Ralph dependency doctor for openclaw-optimization-guide
#
# Read-only by default. Inspects the host for everything Ralph needs to loop:
#   REQUIRED for iter-0  : claude CLI, gh (auth), git remote auth, ANTHROPIC_API_KEY,
#                          .ralph writable, PROMPT.md/AGENTS.md/IMPLEMENTATION_PLAN.md
#   RECOMMENDED          : Ollama at 11434 + qwen3-embedding model, OPENROUTER_API_KEY,
#                          DEEPSEEK_API_KEY, gateway /health on 18789
#
# Output:
#   - Human readable status to stderr
#   - JSON report at .ralph/doctor.json (overwritten each run)
#   - Exit 0 unless a REQUIRED-iter-0 check fails (then exit 1)
#
# Never installs anything. Never modifies anything outside .ralph/.
# To install optional deps, run scripts/install-optional-deps.sh.
#
# Usage:
#   bash scripts/ralph-doctor.sh             # full report
#   bash scripts/ralph-doctor.sh --quiet     # only print JSON path + exit code
#   bash scripts/ralph-doctor.sh --json-only # print only JSON to stdout
#
# Triggered by:
#   - scripts/ralph-loop.sh (after preflight, before first iteration)
#   - manual: bash scripts/ralph-doctor.sh

set -uo pipefail

# ---------- Configuration ----------
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RALPH_DIR="$REPO_ROOT/.ralph"
REPORT="$RALPH_DIR/doctor.json"
GATEWAY_PORT="${OPENCLAW_PORT:-18789}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
EMBED_MODEL="${EMBED_MODEL:-qwen3-embedding:0.6b}"

QUIET=0
JSON_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --quiet)     QUIET=1 ;;
    --json-only) JSON_ONLY=1; QUIET=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
  esac
done

mkdir -p "$RALPH_DIR" 2>/dev/null || true

# ---------- Logging ----------
say() {
  if [ "$QUIET" -eq 0 ]; then
    echo "$@" >&2
  fi
}

# ---------- Result accumulators ----------
# Each check appends a JSON object to CHECKS_JSON.
CHECKS_JSON=""
REQUIRED_FAILS=0
RECOMMENDED_FAILS=0

json_escape() {
  # Minimal JSON string escape: backslash, double quote, newlines, tabs.
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

record() {
  # record <name> <tier: required|recommended> <status: ok|warn|fail> <detail>
  local name="$1" tier="$2" status="$3" detail="$4"
  local sym="?"
  case "$status" in
    ok)   sym="OK"   ;;
    warn) sym="WARN" ;;
    fail) sym="FAIL" ;;
  esac
  say "[$sym] [$tier] $name — $detail"

  if [ "$tier" = "required" ] && [ "$status" = "fail" ]; then
    REQUIRED_FAILS=$((REQUIRED_FAILS+1))
  fi
  if [ "$tier" = "recommended" ] && { [ "$status" = "fail" ] || [ "$status" = "warn" ]; }; then
    RECOMMENDED_FAILS=$((RECOMMENDED_FAILS+1))
  fi

  local entry
  entry="$(printf '{"name":"%s","tier":"%s","status":"%s","detail":"%s"}' \
    "$(json_escape "$name")" "$(json_escape "$tier")" \
    "$(json_escape "$status")" "$(json_escape "$detail")")"
  if [ -z "$CHECKS_JSON" ]; then
    CHECKS_JSON="$entry"
  else
    CHECKS_JSON="$CHECKS_JSON,$entry"
  fi
}

# ---------- Checks ----------
say "=== Ralph Dependency Doctor ==="
say "repo_root=$REPO_ROOT"
say "host=$(hostname 2>/dev/null || echo unknown) user=$(whoami 2>/dev/null || echo unknown)"
say "time=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
say ""

# REQUIRED: bootstrap files
for f in PROMPT.md AGENTS.md IMPLEMENTATION_PLAN.md; do
  if [ -f "$REPO_ROOT/$f" ]; then
    record "bootstrap_file:$f" required ok "present"
  else
    record "bootstrap_file:$f" required fail "missing at repo root"
  fi
done

# REQUIRED: .ralph writable
if mkdir -p "$RALPH_DIR" 2>/dev/null && touch "$RALPH_DIR/.doctor-write-test" 2>/dev/null; then
  rm -f "$RALPH_DIR/.doctor-write-test" 2>/dev/null || true
  record "ralph_dir_writable" required ok "$RALPH_DIR"
else
  record "ralph_dir_writable" required fail "cannot write to $RALPH_DIR"
fi

# REQUIRED: claude CLI (or opencode as fallback)
if command -v claude >/dev/null 2>&1; then
  CLAUDE_VER="$(claude --version 2>/dev/null | head -1 || echo unknown)"
  record "cli_claude" required ok "$(command -v claude) ${CLAUDE_VER}"
elif command -v opencode >/dev/null 2>&1; then
  OPENCODE_VER="$(opencode --version 2>/dev/null | head -1 || echo unknown)"
  record "cli_claude" required ok "opencode fallback at $(command -v opencode) ${OPENCODE_VER}"
else
  record "cli_claude" required fail "neither 'claude' nor 'opencode' on PATH"
fi

# REQUIRED: ANTHROPIC_API_KEY (look in env then common files)
ANTHROPIC_FOUND=""
ANTHROPIC_SOURCE=""
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  ANTHROPIC_FOUND=1
  ANTHROPIC_SOURCE="environment"
else
  for envfile in \
    "$REPO_ROOT/.ralph/.env" \
    "$HOME/.openclaw/.env" \
    "$HOME/.config/openclaw/.env" \
    "/etc/openclaw/.env"; do
    if [ -f "$envfile" ] && grep -q '^ANTHROPIC_API_KEY=' "$envfile" 2>/dev/null; then
      ANTHROPIC_FOUND=1
      ANTHROPIC_SOURCE="$envfile"
      break
    fi
  done
fi
if [ -n "$ANTHROPIC_FOUND" ]; then
  record "anthropic_api_key" required ok "found in $ANTHROPIC_SOURCE"
else
  record "anthropic_api_key" required fail "not in env or known .env files"
fi

# REQUIRED: git author
GIT_NAME="$(git -C "$REPO_ROOT" config user.name 2>/dev/null || true)"
GIT_EMAIL="$(git -C "$REPO_ROOT" config user.email 2>/dev/null || true)"
if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
  record "git_author" required ok "$GIT_NAME <$GIT_EMAIL>"
else
  record "git_author" required fail "user.name or user.email unset (ralph-loop.sh sets defaults at preflight, but doctor checks current state)"
fi

# REQUIRED: git remote reachable
if git -C "$REPO_ROOT" ls-remote --heads origin >/dev/null 2>&1; then
  record "git_remote_auth" required ok "git ls-remote origin succeeded"
else
  record "git_remote_auth" required fail "git ls-remote origin failed; deploy key or PAT misconfigured"
fi

# REQUIRED: gh CLI authenticated (used by Ralph to open PRs)
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    GH_VER="$(gh --version 2>/dev/null | head -1 || echo unknown)"
    record "gh_cli" required ok "$GH_VER, authenticated"
  else
    record "gh_cli" required fail "gh installed but not authenticated"
  fi
else
  record "gh_cli" required fail "gh not on PATH"
fi

# RECOMMENDED: Ollama reachable + embedding model
OLLAMA_REACH=0
OLLAMA_BODY=""
if OLLAMA_BODY="$(curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null)"; then
  OLLAMA_REACH=1
fi
if [ "$OLLAMA_REACH" -eq 1 ]; then
  if printf '%s' "$OLLAMA_BODY" | grep -q "qwen3-embedding"; then
    record "ollama_qwen3_embedding" recommended ok "$OLLAMA_URL reachable, qwen3-embedding present"
  else
    record "ollama_qwen3_embedding" recommended warn "$OLLAMA_URL reachable but qwen3-embedding model not pulled (run scripts/install-optional-deps.sh embed-model)"
  fi
else
  record "ollama_qwen3_embedding" recommended warn "Ollama not reachable at $OLLAMA_URL (Memory Bridge iter-1+ degrades; run scripts/install-optional-deps.sh ollama)"
fi

# RECOMMENDED: secondary keys
for k in OPENROUTER_API_KEY DEEPSEEK_API_KEY; do
  FOUND=""
  if [ -n "${!k:-}" ]; then
    FOUND="environment"
  else
    for envfile in \
      "$REPO_ROOT/.ralph/.env" \
      "$HOME/.openclaw/.env" \
      "$HOME/.config/openclaw/.env" \
      "/etc/openclaw/.env"; do
      if [ -f "$envfile" ] && grep -q "^${k}=" "$envfile" 2>/dev/null; then
        FOUND="$envfile"
        break
      fi
    done
  fi
  if [ -n "$FOUND" ]; then
    record "fallback_key:$k" recommended ok "found in $FOUND"
  else
    record "fallback_key:$k" recommended warn "not set; fallback chain partially degraded"
  fi
done

# RECOMMENDED: gateway /health
if curl -fsS --max-time 3 "http://127.0.0.1:${GATEWAY_PORT}/health" >/dev/null 2>&1; then
  record "gateway_health" recommended ok "/health on port $GATEWAY_PORT responding"
else
  record "gateway_health" recommended warn "/health on port $GATEWAY_PORT unreachable (deploy may be down — see PR #21 fixes)"
fi

# Disk + memory snapshot (informational; never fails)
DISK_LINE="$(df -h "$HOME" 2>/dev/null | tail -1 | awk '{printf "used=%s avail=%s pct=%s", $3, $4, $5}')"
MEM_LINE="$(free -h 2>/dev/null | awk '/^Mem:/{printf "total=%s used=%s avail=%s", $2, $3, $7}')"
record "disk" recommended ok "${DISK_LINE:-unknown}"
record "memory" recommended ok "${MEM_LINE:-unknown}"

# ---------- Summary + JSON ----------
SUMMARY_STATE="ok"
if [ "$REQUIRED_FAILS" -gt 0 ]; then
  SUMMARY_STATE="required_failed"
elif [ "$RECOMMENDED_FAILS" -gt 0 ]; then
  SUMMARY_STATE="degraded"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null)"
[ -z "$HEAD_SHA" ] && HEAD_SHA="unknown"
BRANCH="$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null)"
[ -z "$BRANCH" ] && BRANCH="unknown"

cat > "$REPORT" <<EOF
{
  "timestamp": "$TS",
  "repo_root": "$(json_escape "$REPO_ROOT")",
  "head": "$HEAD_SHA",
  "branch": "$(json_escape "$BRANCH")",
  "summary": "$SUMMARY_STATE",
  "required_fails": $REQUIRED_FAILS,
  "recommended_fails": $RECOMMENDED_FAILS,
  "checks": [$CHECKS_JSON]
}
EOF

if [ "$JSON_ONLY" -eq 1 ]; then
  cat "$REPORT"
else
  say ""
  say "=== Summary ==="
  say "state=$SUMMARY_STATE required_fails=$REQUIRED_FAILS recommended_fails=$RECOMMENDED_FAILS"
  say "report: $REPORT"
fi

if [ "$REQUIRED_FAILS" -gt 0 ]; then
  exit 1
fi
exit 0
