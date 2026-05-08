#!/usr/bin/env bash
# Pull workspace files from the OpenClaw server into server-config/workspace/.
# Designed to run on the GitHub Actions runner; the runner needs SSH key
# auth set up before this is invoked.
#
# Required env vars:
#   SERVER_HOST - hostname or IP (e.g., 167.99.237.49)
#   SERVER_USER - SSH username (e.g., clawadmin)
#   REPO_DIR    - path to the repo checkout (default: $GITHUB_WORKSPACE or $PWD)
set -euo pipefail

: "${SERVER_HOST:?SERVER_HOST required}"
: "${SERVER_USER:?SERVER_USER required}"
REPO_DIR="${REPO_DIR:-${GITHUB_WORKSPACE:-$(pwd)}}"

DST="${REPO_DIR}/server-config/workspace/"
SSH_OPTS="${SSH_OPTS:--o StrictHostKeyChecking=accept-new -o ConnectTimeout=10}"

mkdir -p "${DST}"

echo "bootstrap: pulling ${SERVER_USER}@${SERVER_HOST}:~/.openclaw/workspace/ -> ${DST}"
# shellcheck disable=SC2086
rsync -avc \
  -e "ssh ${SSH_OPTS}" \
  --include='*/' \
  --include='*.md' \
  --exclude='*' \
  --prune-empty-dirs \
  "${SERVER_USER}@${SERVER_HOST}:~/.openclaw/workspace/" \
  "${DST}"

echo "bootstrap: sanitizing (defense in depth)"
find "${DST}" \( \
    -name 'secrets.env*' -o \
    -name 'gateway.token' -o \
    -name '*.bak' -o \
    -name '*.bak.*' -o \
    -name '*.clobbered.*' -o \
    -name '*.last-good' \
  \) -delete 2>/dev/null || true

echo "bootstrap: captured files:"
find "${DST}" -type f | sort
