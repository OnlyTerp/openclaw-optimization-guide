#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${OPENCLAW_PORT:-18789}"
HOST="${OPENCLAW_HOST:-127.0.0.1}"
HEALTH_URL="http://${HOST}:${PORT}/health"
RETRIES="${HEALTHCHECK_RETRIES:-60}"
SLEEP_SEC="${HEALTHCHECK_SLEEP:-2}"

echo "healthcheck: target=${HEALTH_URL} retries=${RETRIES} sleep=${SLEEP_SEC}s"

check_http() {
  curl -fsS --max-time 3 "${HEALTH_URL}" > /dev/null 2>&1
}

check_tcp() {
  if command -v nc > /dev/null 2>&1; then
    nc -z -w 2 "${HOST}" "${PORT}" > /dev/null 2>&1
  else
    bash -c "exec 3<>/dev/tcp/${HOST}/${PORT}" 2>/dev/null
  fi
}

check_proc() {
  pgrep -f "openclaw.*gateway.*--port ${PORT}" > /dev/null
}

for i in $(seq 1 "${RETRIES}"); do
  if check_http; then
    echo "healthcheck: HTTP /health OK (try ${i})"
    exit 0
  fi

  if check_tcp; then
    echo "healthcheck: try ${i}/${RETRIES}: TCP port ${PORT} open, waiting for HTTP /health"
  elif check_proc; then
    echo "healthcheck: try ${i}/${RETRIES}: gateway process found, waiting for port and HTTP"
  else
    echo "healthcheck: try ${i}/${RETRIES}: no HTTP, no TCP, no gateway process yet"
  fi

  sleep "${SLEEP_SEC}"
done

echo "healthcheck: FAILED after ${RETRIES} tries"

echo
echo "=== PROCESS CHECK ==="
pgrep -afi 'openclaw|gateway|18789' || true

echo
echo "=== PORT CHECK ==="
ss -ltnp | grep "${PORT}" || true

echo
echo "=== USER SERVICE STATUS ==="
systemctl --user status openclaw-gateway.service --no-pager -l || true

echo
echo "=== USER SERVICE LOGS ==="
journalctl --user -u openclaw-gateway.service -n 120 --no-pager || true

exit 1
