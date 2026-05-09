#!/usr/bin/env bash
# Restore the backup tied to the CURRENT deploy over ~/.openclaw/workspace/,
# restart gateway, and exit non-zero so the workflow is marked failed even
# after recovery.
#
# Source of truth for which backup to restore (in priority order):
#   1. $ROLLBACK_BACKUP_DIR (env override, e.g. for manual recovery)
#   2. ~/.openclaw/.last-sync-backup (written by sync-workspace.sh THIS deploy)
#
# DO NOT silently fall back to "latest folder in .sync-backups". rsync
# --backup-dir only contains files that changed on this deploy, so an
# unrelated older backup is not a safe restore target.
set -uo pipefail

BACKUP_ROOT="${HOME}/.openclaw/.sync-backups"
LAST_BACKUP_FILE="${HOME}/.openclaw/.last-sync-backup"
DST="${HOME}/.openclaw/workspace/"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "rollback: triggered"

# Resolve target backup directory in priority order.
TARGET=""
if [ -n "${ROLLBACK_BACKUP_DIR:-}" ]; then
  TARGET="${ROLLBACK_BACKUP_DIR}"
  echo "rollback: using ROLLBACK_BACKUP_DIR=${TARGET}"
elif [ -s "${LAST_BACKUP_FILE}" ]; then
  TARGET="$(cat "${LAST_BACKUP_FILE}")"
  echo "rollback: using ${LAST_BACKUP_FILE} -> ${TARGET}"
else
  echo "rollback: ABORT — no ROLLBACK_BACKUP_DIR set and ${LAST_BACKUP_FILE} is missing or empty."
  echo "rollback: refusing to restore an arbitrary 'latest' backup; that is unsafe."
  echo "rollback: if you need to manually recover, set ROLLBACK_BACKUP_DIR to a known-good backup path under ${BACKUP_ROOT} and re-run."
  exit 1
fi

if [ -z "${TARGET}" ]; then
  echo "rollback: ABORT — resolved backup path is empty."
  exit 1
fi

if [ ! -d "${TARGET}" ]; then
  echo "rollback: ABORT — backup directory does not exist: ${TARGET}"
  exit 1
fi

# rsync --backup-dir only stores files that were overwritten on this deploy.
# An empty TARGET means nothing changed -- there is nothing to roll back.
if [ -z "$(ls -A "${TARGET}" 2>/dev/null || true)" ]; then
  echo "rollback: backup directory ${TARGET} is empty — sync-workspace did not change any files this deploy."
  echo "rollback: nothing to restore. Failing deploy without modifying workspace."
  bash "${SCRIPT_DIR}/restart-gateway.sh" || true
  exit 1
fi

SRC="${TARGET%/}/"
echo "rollback: restoring ${SRC} -> ${DST}"
rsync -avc "${SRC}" "${DST}"

echo "rollback: restarting gateway"
bash "${SCRIPT_DIR}/restart-gateway.sh" || true

echo "rollback: complete (workflow will exit non-zero so failure is visible)"
exit 1
