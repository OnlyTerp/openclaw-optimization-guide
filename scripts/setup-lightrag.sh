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

# Substitute env vars into the template.
# Required on this server: GROQ_API_KEY, OPENAI_API_KEY
if [ -z "${GROQ_API_KEY:-}" ]; then
  echo "ERROR: GROQ_API_KEY is not set. Add it to ~/.bashrc and run: source ~/.bashrc" >&2
  exit 1
fi
if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY is not set. Add it to ~/.bashrc and run: source ~/.bashrc" >&2
  exit 1
fi

# shellcheck disable=SC2016
sed \
  -e "s|\${GROQ_API_KEY}|${GROQ_API_KEY}|g" \
  -e "s|\${OPENAI_API_KEY}|${OPENAI_API_KEY}|g" \
  -e "s|\${HOME}|${HOME}|g" \
  "${TEMPLATE}" > "${ENV_FILE}"

chmod 600 "${ENV_FILE}"
echo "setup-lightrag: wrote ${ENV_FILE}"
echo "setup-lightrag: data directory: ${DATA_DIR}"
echo "setup-lightrag: done. Run: bash scripts/start-lightrag.sh"
