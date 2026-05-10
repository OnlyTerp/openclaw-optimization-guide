#!/usr/bin/env bash
# Verify the repo-level ShellCheck policy stays aligned with CI.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validate_yml="${repo_root}/.github/workflows/validate.yml"
shellcheckrc="${repo_root}/.shellcheckrc"

if [[ ! -f "${shellcheckrc}" ]]; then
  echo "missing .shellcheckrc" >&2
  exit 1
fi

if ! grep -Eq '^disable=([^#]*,)?SC2009(,|$)' "${shellcheckrc}"; then
  echo ".shellcheckrc must disable SC2009 to prevent ps/grep info churn" >&2
  exit 1
fi

if ! grep -Eq '^disable=([^#]*,)?SC1091(,|$)' "${shellcheckrc}"; then
  echo ".shellcheckrc must disable SC1091 for sourced runtime files" >&2
  exit 1
fi

if ! grep -Eq '^disable=([^#]*,)?SC2034(,|$)' "${shellcheckrc}"; then
  echo ".shellcheckrc must disable SC2034 for env/config helper variables" >&2
  exit 1
fi

if ! grep -q 'shellcheck --severity=warning "${files\[@\]}"' "${validate_yml}"; then
  echo "validate.yml must run shellcheck with --severity=warning" >&2
  exit 1
fi

printf 'ShellCheck policy guard OK\n'
