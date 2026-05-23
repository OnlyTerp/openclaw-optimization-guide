#!/usr/bin/env bash
# Non-destructive OpenClaw scorecard evidence collector.
# Writes redacted command output under ~/openclaw-scorecard-evidence/<timestamp>/.

set -u -o pipefail

TS="${OPENCLAW_SCORECARD_TS:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_ROOT="${OPENCLAW_SCORECARD_EVIDENCE_ROOT:-$HOME/openclaw-scorecard-evidence}"
EVIDENCE_DIR="$EVIDENCE_ROOT/$TS"
REPO_ROOT="${OPENCLAW_SCORECARD_REPO_ROOT:-$(pwd)}"
OPENCLAW_ROOT="${OPENCLAW_CONFIG_ROOT:-$HOME/.openclaw}"

mkdir -p "$EVIDENCE_DIR"

redact() {
  sed -E \
    -e 's/(sk-[A-Za-z0-9_-]{20,})/[REDACTED_KEY]/g' \
    -e 's/(sk-ant-[A-Za-z0-9_-]{20,})/[REDACTED_KEY]/g' \
    -e 's/(Bearer[[:space:]]+)[A-Za-z0-9._~+\/-]+/\1[REDACTED_TOKEN]/Ig' \
    -e 's/((OPENAI|ANTHROPIC|OPENROUTER|DEEPSEEK|DEEPINFRA|GOOGLE|GEMINI|GITHUB|GH|TOKEN|API_KEY|SECRET|PASSWORD)[A-Z0-9_]*[[:space:]]*=[[:space:]]*)[^[:space:]]+/\1[REDACTED_KEY]/Ig' \
    -e 's/((Authorization|X-Api-Key|api[_-]?key)[[:space:]]*[:=][[:space:]]*)[^[:space:]]+/\1[REDACTED_KEY]/Ig'
}

run_capture() {
  local name="$1"
  shift
  local cmd="$1"
  shift || true
  {
    printf '$ %q' "$cmd"
    for arg in "$@"; do printf ' %q' "$arg"; done
    printf '\n\n'
    "$cmd" "$@"
  } 2>&1 | redact > "$EVIDENCE_DIR/$name.txt"
}

run_shell() {
  local name="$1"
  local cmd="$2"
  {
    printf '$ %s\n\n' "$cmd"
    bash -lc "$cmd"
  } 2>&1 | redact > "$EVIDENCE_DIR/$name.txt"
}

section() {
  printf '%s\n' "$1" >> "$EVIDENCE_DIR/INDEX.txt"
}

: > "$EVIDENCE_DIR/INDEX.txt"
{
  echo "timestamp=$TS"
  echo "evidence_dir=$EVIDENCE_DIR"
  echo "repo_root=$REPO_ROOT"
  echo "openclaw_root=$OPENCLAW_ROOT"
} > "$EVIDENCE_DIR/metadata.txt"

section "A. System/OpenClaw basics"
run_shell system_basics 'date -u; hostname; pwd; whoami; uname -a'
run_shell openclaw_version 'command -v openclaw || true; openclaw --version || true'
run_shell openclaw_doctor 'openclaw doctor || true'
run_shell openclaw_memory_status 'openclaw memory status || true'
run_shell openclaw_plugins_list 'openclaw plugins list || true'
run_shell openclaw_skills_list 'openclaw skills list || true'

section "B. File size/context checks"
run_shell context_files_find 'for f in "$HOME/.openclaw/SOUL.md" "$HOME/.openclaw/AGENTS.md" "$HOME/.openclaw/MEMORY.md" "$HOME/.openclaw/TOOLS.md" "templates/SOUL.md" "templates/AGENTS.md" "templates/MEMORY.md" "templates/TOOLS.md" "SOUL.md" "AGENTS.md" "MEMORY.md" "TOOLS.md"; do [ -e "$f" ] && printf "%s\n" "$f"; done'
run_shell context_files_sizes 'for f in "$HOME/.openclaw/SOUL.md" "$HOME/.openclaw/AGENTS.md" "$HOME/.openclaw/MEMORY.md" "$HOME/.openclaw/TOOLS.md" "templates/SOUL.md" "templates/AGENTS.md" "templates/MEMORY.md" "templates/TOOLS.md" "SOUL.md" "AGENTS.md" "MEMORY.md" "TOOLS.md"; do if [ -f "$f" ]; then ls -la "$f"; wc -c "$f"; printf "%s\n" "--- head: $f ---"; head -40 "$f"; fi; done'
run_shell loaded_context_guess 'for f in "$HOME/.openclaw"/*.json "$HOME/.openclaw"/*.yaml "$HOME/.openclaw"/*.yml ./*.json ./*.yaml ./*.yml configs/*.json; do [ -f "$f" ] && printf "%s\n" "--- $f ---" && rg -n "SOUL|AGENTS|MEMORY|TOOLS|context|template|profile|root" "$f" || true; done'

section "C. Config checks"
run_shell openclaw_config_find 'find "$HOME/.openclaw" . -maxdepth 5 -type f \( -name "*.json" -o -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | sort | head -300'
run_shell config_grep 'if command -v rg >/dev/null 2>&1; then rg -n "cache-ttl|cacheTtl|reasoning|reserveTokens|localModelLean|compaction|skills\.autoUpdate|control-plane|outside-workspace|Task Brain|taskBrain|memory_search|spawn sub-agent|fallback|openrouter|deepseek|kimi|sonnet" "$HOME/.openclaw" . 2>/dev/null || true; else find "$HOME/.openclaw" . -type f 2>/dev/null | xargs grep -InE "cache-ttl|cacheTtl|reasoning|reserveTokens|localModelLean|compaction|skills\.autoUpdate|control-plane|outside-workspace|Task Brain|taskBrain|memory_search|spawn sub-agent|fallback|openrouter|deepseek|kimi|sonnet" 2>/dev/null || true; fi'

section "D. Memory/vault checks"
run_shell memory_dirs 'find "$HOME" -maxdepth 4 -type d \( -iname "*vault*" -o -iname "*notes*" -o -iname "01_thinking" -o -iname "inbox" \) 2>/dev/null | sort | head -300'
run_shell memory_files 'find "$HOME" -maxdepth 5 -type f \( -iname "*MOC*.md" -o -iname "DREAMS.md" -o -iname "*.md" \) 2>/dev/null | sort | head -200'
run_shell crontab 'crontab -l || true'
run_shell memory_grep 'if command -v rg >/dev/null 2>&1; then rg -n "dream|DREAMS|auto-capture|autocapture|inbox|lightrag|memory-core|memory-lancedb" "$HOME/.openclaw" "$HOME" 2>/dev/null || true; else find "$HOME/.openclaw" "$HOME" -type f 2>/dev/null | xargs grep -InE "dream|DREAMS|auto-capture|autocapture|inbox|lightrag|memory-core|memory-lancedb" 2>/dev/null || true; fi'

section "E. Orchestration checks"
run_shell orchestration_files 'find . "$HOME/.openclaw" -maxdepth 5 -type f \( -iname "*ralph*" -o -iname "*repowise*" -o -iname "*preflight*" -o -iname "*codex*" -o -iname "*coordinator*" \) 2>/dev/null | sort | head -300'
run_shell orchestration_grep 'if command -v rg >/dev/null 2>&1; then rg -n "Coordinator Protocol|parallel independent|spawn sub-agent|worker prompt|preflight-context|repowise|ralph-loop|fallback|failover" . "$HOME/.openclaw" 2>/dev/null || true; else find . "$HOME/.openclaw" -type f 2>/dev/null | xargs grep -InE "Coordinator Protocol|parallel independent|spawn sub-agent|worker prompt|preflight-context|repowise|ralph-loop|fallback|failover" 2>/dev/null || true; fi'
run_shell processes 'ps aux | grep -Ei "ralph|openclaw|gateway|memory|ollama" | grep -v grep || true'

section "F. Security checks"
run_shell security_grep 'if command -v rg >/dev/null 2>&1; then rg -n "Task Brain|taskBrain|semantic categor|deny|allowlist|skills\.autoUpdate|ClawHub|pin|version|redact|secret|credential|OPENAI|ANTHROPIC|OPENROUTER|DEEPSEEK|CANVAS|model auth" "$HOME/.openclaw" . 2>/dev/null || true; else find "$HOME/.openclaw" . -type f 2>/dev/null | xargs grep -InE "Task Brain|taskBrain|semantic categor|deny|allowlist|skills\.autoUpdate|ClawHub|pin|version|redact|secret|credential|OPENAI|ANTHROPIC|OPENROUTER|DEEPSEEK|CANVAS|model auth" 2>/dev/null || true; fi'
run_shell openclaw_dir_listing 'ls -la "$HOME/.openclaw" 2>/dev/null || true'
run_shell secret_permissions 'stat -c "%a %n" "$HOME/.openclaw/.env" "$HOME/.openclaw"/*env 2>/dev/null || true'

section "G. Observability checks"
run_shell user_units 'systemctl --user list-units 2>/dev/null | grep -Ei "openclaw|gateway|memory|ralph" || true'
run_shell system_units 'systemctl list-units 2>/dev/null | grep -Ei "openclaw|gateway|memory|ralph" || true'
run_shell learnings_dirs 'find "$HOME" . -maxdepth 5 \( -type d -iname ".learnings" -o -type d -iname "*learning*" \) 2>/dev/null | sort | head -200'
run_shell rollback_files 'find "$HOME" . -maxdepth 5 -type f \( -iname "*rollback*" -o -iname "*restore*" -o -iname "*backup*" -o -iname "*sync*" \) 2>/dev/null | sort | head -300'
run_shell observability_grep 'if command -v rg >/dev/null 2>&1; then rg -n "langfuse|otel|opentelemetry|trace|rollback|restore|stale|cleanup|reserveTokens|sync|learnings" "$HOME/.openclaw" . 2>/dev/null || true; else find "$HOME/.openclaw" . -type f 2>/dev/null | xargs grep -InE "langfuse|otel|opentelemetry|trace|rollback|restore|stale|cleanup|reserveTokens|sync|learnings" 2>/dev/null || true; fi'

section "H. Speed pillar verification (post-trim)"
# Reports actual hot-path file sizes on the deployed workspace so PR #49
# scorecard items 1, 2, 5 can be verified from CI logs without terminal access.
run_shell speed_hotpath_sizes 'WS="$HOME/.openclaw/workspace"; for f in SOUL.md IDENTITY.md USER.md AGENTS.md SECURITY.md COST_AWARE_OPERATOR.md MEMORY.md TOOLS.md HEARTBEAT.md; do p="$WS/$f"; [ -f "$p" ] && wc -c "$p"; done; echo "---scorecard-named-files-total---"; for f in SOUL.md AGENTS.md MEMORY.md TOOLS.md; do p="$WS/$f"; [ -f "$p" ] && wc -c "$p"; done | awk "{s+=\$1} END {print s\" bytes total (target <8192)\"}"'
run_shell speed_reasoning_status 'openclaw status 2>&1 || true; echo "---"; if command -v rg >/dev/null 2>&1; then rg -n "reasoning" "$HOME/.openclaw"/*.json "$HOME/.openclaw/config"/*.json 2>/dev/null || true; fi'
run_shell speed_cron_audit 'crontab -l 2>/dev/null | grep -i openclaw || echo "no openclaw cron entries"; echo "---openclaw cron config---"; if command -v rg >/dev/null 2>&1; then rg -n "sessionTarget|delivery.*mode|transcriptDir|cron" "$HOME/.openclaw"/*.json 2>/dev/null || true; fi'
run_shell speed_skills_installed 'WS="$HOME/.openclaw/workspace/skills"; for s in coordinator-protocol vault-orientation multi-session-discipline decision-tree clawrouter; do [ -d "$WS/$s" ] && echo "OK $s" || echo "MISSING $s"; done'
run_shell speed_hooks_installed 'for h in auto-capture learnings-capture pre-completion-check loop-detector session-start-protocol; do [ -d "hooks/$h" ] && echo "OK hooks/$h" || echo "MISSING hooks/$h"; done'

printf 'Evidence written to %s\n' "$EVIDENCE_DIR"
