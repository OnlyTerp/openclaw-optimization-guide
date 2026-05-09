#!/usr/bin/env bash
# Sync server-config/workspace/ -> ~/.openclaw/workspace/ with timestamped
# pre-overwrite backups, drift dry-run, and bounded backup retention.
#
# Records the exact backup path for this deploy at:
#   ~/.openclaw/.last-sync-backup
# rollback.sh reads that file so it restores the backup tied to THIS deploy
# rather than guessing the latest folder by mtime.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${REPO_DIR}/server-config/workspace/"
DST="${HOME}/.openclaw/workspace/"
BACKUP_ROOT="${HOME}/.openclaw/.sync-backups"
TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"
LAST_BACKUP_FILE="${HOME}/.openclaw/.last-sync-backup"
DRIFT_FILE="/tmp/drift-${TS}.diff"

if [ ! -d "${SRC}" ]; then
  echo "sync-workspace: source ${SRC} does not exist; nothing to sync."
  exit 0
fi

# Ensure parent dirs for backup file + roots exist before we record anything.
mkdir -p "${DST}" "${BACKUP_ROOT}" "$(dirname "${LAST_BACKUP_FILE}")"

# Record backup path BEFORE rsync so even a partial sync can be rolled back
# to the snapshot we just took.
echo "${BACKUP_DIR}" > "${LAST_BACKUP_FILE}"
echo "sync-workspace: backup path recorded -> ${LAST_BACKUP_FILE}"
echo "sync-workspace: backup path = ${BACKUP_DIR}"

echo "Drift dry-run (server vs repo) -> ${DRIFT_FILE}"
rsync -avcni "${SRC}" "${DST}" > "${DRIFT_FILE}" || true
if [ -s "${DRIFT_FILE}" ]; then
  echo "Drift detected; full diff saved to ${DRIFT_FILE}"
else
  echo "No drift."
fi

# NO --delete-after. The repo is a partial mirror (bootstrap only captures
# whitelisted files). If we deleted server files that aren't in the repo,
# we'd wipe runtime state like .openclaw/workspace-state.json and break
# the gateway -- which is exactly what happened on 2026-05-08.
# Files added/changed in the repo flow to the server; files only on the
# server stay there. To remove a server file, do it manually.
echo "Syncing ${SRC} -> ${DST} (backups in ${BACKUP_DIR})"
rsync -avc \
  --backup --backup-dir="${BACKUP_DIR}" \
  "${SRC}" "${DST}"

# Retain only the 10 most recent backup directories.
if [ -d "${BACKUP_ROOT}" ]; then
  cd "${BACKUP_ROOT}"
  # shellcheck disable=SC2012
  ls -1t | tail -n +11 | xargs -r rm -rf
fi

echo "sync-workspace: done."
