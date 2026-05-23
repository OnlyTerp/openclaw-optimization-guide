#!/usr/bin/env bash
# Start the LightRAG file watcher. Idempotent — skips if already running.
set -euo pipefail

VENV="${HOME}/openclaw-knowledge/sandbox/venvs/core"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WATCHER_SCRIPT="${SCRIPT_DIR}/lightrag-watcher.py"
PID_FILE="${HOME}/.lightrag/watcher.pid"
LOG_FILE="${HOME}/.lightrag/watcher.log"

if [ -f "${PID_FILE}" ]; then
  PID="$(cat "${PID_FILE}")"
  if kill -0 "${PID}" 2>/dev/null; then
    echo "start-lightrag-watcher: already running (pid ${PID})"
    exit 0
  fi
  rm -f "${PID_FILE}"
fi

# shellcheck disable=SC1090
source "${VENV}/bin/activate"

# Ensure watchdog + requests are available in the venv.
pip install --quiet watchdog requests 2>/dev/null || true

nohup python3 "${WATCHER_SCRIPT}" > "${LOG_FILE}" 2>&1 &
echo $! > "${PID_FILE}"
echo "start-lightrag-watcher: started (pid $(cat "${PID_FILE}")). Log: ${LOG_FILE}"
