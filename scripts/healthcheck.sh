#!/usr/bin/env bash
# Cascading health check. Succeeds on any of: HTTP /health, TCP port open,
# process exists. Used to gate deploy success.
set -uo pipefail

PORT="${OPENCLAW_PORT:-18789}"
HOST="127.0.0.1"
HEALTH_URL="http://${HOST}:${PORT}/health"
RETRIES="${HEALTHCHECK_RETRIES:-10}"
SLEEP_SEC="${HEALTHCHECK_SLEEP:-1}"

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
  if check_http; then
    echo "healthcheck: HTTP /health OK (try ${i})"
    exit 0
  fi
  if check_tcp; then
    echo "healthcheck: TCP port ${PORT} open (try ${i})"
    exit 0
  fi
  if check_proc && [ "${i}" -ge 5 ]; then
    echo "healthcheck: process running but no HTTP/TCP after ${i} tries — accepting (try ${i})"
    exit 0
  fi
  sleep "${SLEEP_SEC}"
done

echo "healthcheck: FAILED after ${RETRIES} tries"
exit 1
