#!/usr/bin/env bash
# Copy hook files from repo into ~/.openclaw/hooks/ and enable them.
# Safe to run on every deploy: rsync is idempotent, enable is idempotent.
set -euo pipefail

# Non-interactive SSH sessions don't source ~/.bashrc.
export PATH="$HOME/.npm-global/bin:$PATH"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_SRC="${REPO_DIR}/hooks"
HOOKS_DST="${HOME}/.openclaw/hooks"

if [ ! -d "${HOOKS_SRC}" ]; then
  echo "sync-hooks: no hooks/ directory in repo, nothing to sync."
  exit 0
fi

mkdir -p "${HOOKS_DST}"

for hook_src in "${HOOKS_SRC}"/*/; do
  hook_name="$(basename "${hook_src}")"
  hook_dst="${HOOKS_DST}/${hook_name}"
  mkdir -p "${hook_dst}"
  rsync -avc "${hook_src}" "${hook_dst}/"
  echo "sync-hooks: synced ${hook_name}"

  # Enable the hook — openclaw returns 0 whether already enabled or not.
  openclaw hooks enable "${hook_name}" 2>/dev/null || true
  echo "sync-hooks: enabled ${hook_name}"
done

echo "sync-hooks: done"
