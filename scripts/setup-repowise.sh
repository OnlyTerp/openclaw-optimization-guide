#!/usr/bin/env bash
# Install Repowise and index the openclaw-optimization-guide repo.
# Idempotent — safe to re-run on every deploy.
set -euo pipefail

VENV="${HOME}/openclaw-knowledge/sandbox/venvs/core"
REPO_DIR="${HOME}/openclaw-optimization-guide"

# shellcheck disable=SC1090
source "${VENV}/bin/activate"

if ! pip show repowise > /dev/null 2>&1; then
  echo "setup-repowise: installing..."
  pip install --quiet repowise
  echo "setup-repowise: installed"
else
  echo "setup-repowise: already installed"
fi

if ! command -v repowise > /dev/null 2>&1; then
  echo "setup-repowise: binary not found after install — skipping init"
  exit 0
fi

echo "setup-repowise: indexing ${REPO_DIR}"
cd "${REPO_DIR}"
# Try both CLI shapes — repowise has changed its interface between versions.
repowise index . 2>/dev/null || repowise init . 2>/dev/null || repowise init 2>/dev/null || true
echo "setup-repowise: done"
