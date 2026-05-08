#!/usr/bin/env bash
# Restart the OpenClaw gateway, fully detached from this SSH session.
set -euo pipefail

PORT="${OPENCLAW_PORT:-18789}"
BIN="${OPENCLAW_BIN:-${HOME}/.npm-global/bin/openclaw}"
LOG_DIR="${HOME}/.openclaw/logs"
LOG_FILE="${LOG_DIR}/gateway.log"

mkdir -p "${LOG_DIR}"

echo "restart-gateway: stopping existing gateway processes..."
pkill -9 -f "openclaw gateway" || true
sleep 2

echo "restart-gateway: starting new gateway on port ${PORT}..."
setsid bash -c "nohup node \"${BIN}\" gateway --port ${PORT} > \"${LOG_FILE}\" 2>&1 < /dev/null &"
sleep 3

if pgrep -f "openclaw gateway" > /dev/null; then
  echo "restart-gateway: gateway running."
  exit 0
else
  echo "restart-gateway: ERROR - gateway did not start. See ${LOG_FILE}."
  exit 1
fi
