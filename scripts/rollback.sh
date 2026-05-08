#!/usr/bin/env bash
# Restore the most recent ~/.openclaw/.sync-backups/<ts>/ over
# ~/.openclaw/workspace/, restart gateway, and exit non-zero so the
# workflow is marked failed even after recovery.
set -uo pipefail

BACKUP_ROOT="${HOME}/.openclaw/.sync-backups"
DST="${HOME}/.openclaw/workspace/"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "rollback: triggered"

if [ ! -d "${BACKUP_ROOT}" ]; then
  echo "rollback: no backup directory at ${BACKUP_ROOT}; nothing to restore."
  exit 1
fi

# shellcheck disable=SC2012
LATEST="$(ls -1t "${BACKUP_ROOT}" 2>/dev/null | head -n 1 || true)"
if [ -z "${LATEST}" ]; then
  echo "rollback: no backups found in ${BACKUP_ROOT}; nothing to restore."
  exit 1
fi

SRC="${BACKUP_ROOT}/${LATEST}/"
echo "rollback: restoring ${SRC} -> ${DST}"
rsync -avc "${SRC}" "${DST}"

echo "rollback: restarting gateway"
bash "${SCRIPT_DIR}/restart-gateway.sh" || true

echo "rollback: complete (workflow will exit non-zero so failure is visible)"
exit 1
