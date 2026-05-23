#!/usr/bin/env bash
# Start LightRAG server in the background. Idempotent — skips if already running.
set -euo pipefail

VENV="${HOME}/openclaw-knowledge/sandbox/venvs/core"
ENV_FILE="${HOME}/.lightrag/.env"
LOG_FILE="${HOME}/.lightrag/lightrag.log"
PID_FILE="${HOME}/.lightrag/lightrag.pid"

if [ ! -f "${ENV_FILE}" ]; then
  echo "ERROR: ${ENV_FILE} not found. Run: bash scripts/setup-lightrag.sh" >&2
  exit 1
fi

if [ -f "${PID_FILE}" ]; then
  PID="$(cat "${PID_FILE}")"
  if kill -0 "${PID}" 2>/dev/null; then
    echo "start-lightrag: already running (pid ${PID})"
    exit 0
  fi
  rm -f "${PID_FILE}"
fi

# Activate venv where lightrag-hku was installed.
# shellcheck disable=SC1090
source "${VENV}/bin/activate"

# LightRAG reads .env from CWD — must start from the directory that contains it.
cd "$(dirname "${ENV_FILE}")"

nohup env "$(grep -v '^#' "${ENV_FILE}" | xargs)" \
  lightrag-server \
  > "${LOG_FILE}" 2>&1 &

echo $! > "${PID_FILE}"
echo "start-lightrag: started (pid $(cat "${PID_FILE}")). Log: ${LOG_FILE}"
