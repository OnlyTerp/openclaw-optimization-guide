#!/usr/bin/env bash
# Sync server-config/workspace/ -> ~/.openclaw/workspace/ with timestamped
# pre-overwrite backups, drift dry-run, and bounded backup retention.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${REPO_DIR}/server-config/workspace/"
DST="${HOME}/.openclaw/workspace/"
BACKUP_ROOT="${HOME}/.openclaw/.sync-backups"
TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"
DRIFT_FILE="/tmp/drift-${TS}.diff"

if [ ! -d "${SRC}" ]; then
  echo "sync-workspace: source ${SRC} does not exist; nothing to sync."
  exit 0
fi

mkdir -p "${DST}" "${BACKUP_ROOT}"

echo "Drift dry-run (server vs repo) -> ${DRIFT_FILE}"
rsync -avcni --delete-after "${SRC}" "${DST}" > "${DRIFT_FILE}" || true
if [ -s "${DRIFT_FILE}" ]; then
  echo "Drift detected; full diff saved to ${DRIFT_FILE}"
else
  echo "No drift."
fi

echo "Syncing ${SRC} -> ${DST} (backups in ${BACKUP_DIR})"
rsync -avc \
  --backup --backup-dir="${BACKUP_DIR}" \
  --delete-after \
  "${SRC}" "${DST}"

# Retain only the 10 most recent backup directories.
if [ -d "${BACKUP_ROOT}" ]; then
  cd "${BACKUP_ROOT}"
  # shellcheck disable=SC2012
  ls -1t | tail -n +11 | xargs -r rm -rf
fi

echo "sync-workspace: done."
