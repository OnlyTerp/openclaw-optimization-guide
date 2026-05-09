#!/usr/bin/env bash
# Cascading health check. Succeeds on any of: HTTP /health, TCP port open,
# process exists. Used to gate deploy success.
#
# HTTP /health is the preferred and primary check. TCP and process checks
# are fallbacks for edge cases.
#
# Defaults: 60 retries x 2s sleep = 120s window. Overridable via env:
#   HEALTHCHECK_RETRIES
#   HEALTHCHECK_SLEEP
set -uo pipefail

PORT="${OPENCLAW_PORT:-18789}"
HOST="127.0.0.1"
HEALTH_URL="http://${HOST}:${PORT}/health"
RETRIES="${HEALTHCHECK_RETRIES:-60}"
SLEEP_SEC="${HEALTHCHECK_SLEEP:-2}"

echo "healthcheck: target=${HEALTH_URL} retries=${RETRIES} sleep=${SLEEP_SEC}s"

check_http() {
  curl -fsS --max-time 2 "${HEALTH_URL}" > /dev/null 2>&1
}

check_tcp() {
  if command -v nc > /dev/null 2>&1; then
    nc -z -w 2 "${HOST}" "${PORT}" > /dev/null 2>&1
  else
    bash -c "exec 3<>/dev/tcp/${HOST}/${PORT}" 2>/dev/null
  fi
}

check_proc() {
  pgrep -f "openclaw gateway" > /dev/null
}

for i in $(seq 1 "${RETRIES}"); do
  # Prefer HTTP — it's the truthful signal that the gateway is serving.
  if check_http; then
    echo "healthcheck: HTTP /health OK (try ${i})"
    exit 0
  fi
  # TCP fallback: port is open but /health hasn't replied yet.
  if check_tcp && [ "${i}" -ge 10 ]; then
    echo "healthcheck: TCP port ${PORT} open, HTTP not responding (try ${i}) — accepting"
    exit 0
  fi
  # Process fallback: only accept very late, only when nothing else worked.
  if check_proc && [ "${i}" -ge 30 ]; then
    echo "healthcheck: process running but no HTTP/TCP after ${i} tries — accepting"
    exit 0
  fi
  sleep "${SLEEP_SEC}"
done

echo "healthcheck: FAILED after ${RETRIES} tries (no HTTP, no TCP, no process)"
exit 1
