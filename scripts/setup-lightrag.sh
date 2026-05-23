#!/usr/bin/env bash
# One-time setup: create ~/.lightrag/ and write the real .env from the template.
# Run this once after installing lightrag-hku. Safe to re-run — won't overwrite
# an existing .env unless you pass --force.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="${REPO_DIR}/lightrag/.env.template"
LIGHTRAG_DIR="${HOME}/.lightrag"
ENV_FILE="${LIGHTRAG_DIR}/.env"
DATA_DIR="${LIGHTRAG_DIR}/data"
FORCE="${1:-}"

mkdir -p "${LIGHTRAG_DIR}" "${DATA_DIR}"

if [ -f "${ENV_FILE}" ] && [ "${FORCE}" != "--force" ]; then
  echo "setup-lightrag: ${ENV_FILE} already exists. Pass --force to overwrite."
  exit 0
fi

# Only GEMINI_API_KEY is required — it covers both LLM and embedding (both free).
if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "ERROR: GEMINI_API_KEY is not set. Add it to ~/.bashrc and run: source ~/.bashrc" >&2
  exit 1
fi

# shellcheck disable=SC2016
sed \
  -e "s|\${GEMINI_API_KEY}|${GEMINI_API_KEY}|g" \
  -e "s|\${HOME}|${HOME}|g" \
  "${TEMPLATE}" > "${ENV_FILE}"

chmod 600 "${ENV_FILE}"
echo "setup-lightrag: wrote ${ENV_FILE}"
echo "setup-lightrag: data dir: ${DATA_DIR}"
echo "setup-lightrag: run next: bash scripts/start-lightrag.sh"
