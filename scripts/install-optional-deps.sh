#!/usr/bin/env bash
# scripts/install-optional-deps.sh — explicit installer for Ralph's optional deps.
#
# Never auto-runs. Never assumes systemd. Only installs what you name.
# All commands print before running so you can copy/paste manually if you prefer.
#
# Subcommands:
#   ollama       Install Ollama (Linux, official script) and start it as a
#                background process under the current user (no systemd).
#   embed-model  Pull the qwen3-embedding:0.6b model (Ollama must be running).
#   all          Run ollama then embed-model.
#   status       Print whether each optional dep is installed/reachable.
#   help         Show this help.
#
# Usage:
#   bash scripts/install-optional-deps.sh status
#   bash scripts/install-optional-deps.sh ollama
#   bash scripts/install-optional-deps.sh embed-model
#   bash scripts/install-optional-deps.sh all
#
# Notes:
#   - The OpenClaw gateway is NOT managed by systemd in this environment.
#     We deliberately mirror that pattern here: ollama is launched with
#     nohup so it survives the ssh session without requiring sudo or units.
#   - Re-running any subcommand is safe (idempotent).

set -uo pipefail

OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
EMBED_MODEL="${EMBED_MODEL:-qwen3-embedding:0.6b}"
OLLAMA_LOG="${OLLAMA_LOG:-$HOME/.openclaw/logs/ollama.log}"

log() { echo "[install-optional-deps] $*"; }

cmd_status() {
  log "=== status ==="
  if command -v ollama >/dev/null 2>&1; then
    log "ollama binary: $(command -v ollama) ($(ollama --version 2>&1 | head -1))"
  else
    log "ollama binary: NOT INSTALLED"
  fi
  if curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    log "ollama daemon: reachable at $OLLAMA_URL"
    if curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" | grep -q "qwen3-embedding"; then
      log "embed model: qwen3-embedding present"
    else
      log "embed model: NOT PULLED (run: $0 embed-model)"
    fi
  else
    log "ollama daemon: NOT REACHABLE at $OLLAMA_URL"
  fi
}

cmd_ollama() {
  log "=== install ollama ==="
  if command -v ollama >/dev/null 2>&1; then
    log "ollama already installed at $(command -v ollama); skipping download"
  else
    log "Running official installer: curl -fsSL https://ollama.com/install.sh | sh"
    if ! curl -fsSL https://ollama.com/install.sh | sh; then
      log "FAIL: ollama install script returned non-zero"
      return 1
    fi
  fi

  if curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    log "ollama daemon already running at $OLLAMA_URL"
    return 0
  fi

  mkdir -p "$(dirname "$OLLAMA_LOG")" 2>/dev/null || true
  log "Starting ollama serve in background (no systemd) -> log: $OLLAMA_LOG"
  nohup ollama serve >>"$OLLAMA_LOG" 2>&1 &
  disown 2>/dev/null || true

  # Wait up to 20s for the daemon to come up
  for i in $(seq 1 20); do
    if curl -fsS --max-time 2 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
      log "ollama daemon up after ${i}s"
      return 0
    fi
    sleep 1
  done
  log "WARN: ollama did not become reachable on $OLLAMA_URL within 20s — check $OLLAMA_LOG"
  return 1
}

cmd_embed_model() {
  log "=== pull embed model: $EMBED_MODEL ==="
  if ! command -v ollama >/dev/null 2>&1; then
    log "FAIL: ollama not installed; run: $0 ollama"
    return 1
  fi
  if ! curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    log "FAIL: ollama daemon not reachable at $OLLAMA_URL; run: $0 ollama"
    return 1
  fi
  if curl -fsS --max-time 3 "$OLLAMA_URL/api/tags" | grep -q "qwen3-embedding"; then
    log "$EMBED_MODEL already pulled; skipping"
    return 0
  fi
  log "ollama pull $EMBED_MODEL"
  if ollama pull "$EMBED_MODEL"; then
    log "OK: pulled $EMBED_MODEL"
    return 0
  fi
  log "FAIL: ollama pull $EMBED_MODEL returned non-zero"
  return 1
}

cmd_all() {
  cmd_ollama && cmd_embed_model
}

cmd_help() {
  sed -n '2,30p' "$0"
}

main() {
  local sub="${1:-help}"
  case "$sub" in
    ollama)      cmd_ollama ;;
    embed-model) cmd_embed_model ;;
    all)         cmd_all ;;
    status)      cmd_status ;;
    help|-h|--help) cmd_help ;;
    *)
      log "Unknown subcommand: $sub"
      cmd_help
      exit 2
      ;;
  esac
}

main "$@"
