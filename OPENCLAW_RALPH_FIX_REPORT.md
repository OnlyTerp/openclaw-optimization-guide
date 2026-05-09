# OpenClaw Ralph Fix Report — iter-doctor

Branch: claude/iter-doctor-bootstrap
Iteration: dependency-doctor bootstrap
Date: 2026-05-09 UTC

## Summary

Adds a read-only Ralph dependency doctor that runs after preflight and before
the first iteration in scripts/ralph-loop.sh. The doctor verifies every
prerequisite Ralph needs, emits a JSON report at .ralph/doctor.json, and exits
non-zero only when a REQUIRED-iter-0 check fails. Optional installs are split
into an explicit, idempotent installer with named subcommands. None of this
changes existing behavior on a healthy server — the doctor passes silently and
the loop proceeds.

## Files added

- scripts/ralph-doctor.sh
- scripts/install-optional-deps.sh
- scripts/test-ralph-doctor.sh
- docs/RALPH_DEPENDENCY_DOCTOR.md
- OPENCLAW_RALPH_FIX_REPORT.md  (this file)

## Files modified

- scripts/ralph-loop.sh
  - Adds a "Doctor" block in main() between preflight and is_complete.
  - Calls bash scripts/ralph-doctor.sh --quiet.
  - On non-zero exit, writes status=doctor_failed and exits 5.
- .github/workflows/ralph-loop.yml
  - Tails .ralph/doctor.json after the existing ralph.log + status.json tail
    so the report is visible from the iPad without SSH.

## What the doctor checks

REQUIRED for iter-0 (failure exits 1):

- PROMPT.md, AGENTS.md, IMPLEMENTATION_PLAN.md present at repo root
- .ralph/ writable
- claude CLI on PATH (or opencode fallback)
- ANTHROPIC_API_KEY in env or known .env files
- git user.name and user.email set
- git ls-remote origin succeeds (push auth)
- gh CLI installed and authenticated

RECOMMENDED (warns only, never blocks):

- Ollama at http://127.0.0.1:11434 + qwen3-embedding model
- OPENROUTER_API_KEY, DEEPSEEK_API_KEY for fallback chain
- Gateway /health on port 18789
- Disk + memory snapshot

## Validation performed locally

- bash -n on all three new scripts: clean.
- shellcheck on all three new scripts: clean (matches validate.yml CI).
- Test harness (scripts/test-ralph-doctor.sh) sandboxed in mktemp dirs:
  8 of 8 assertions PASS.
- Dry run against synthetic repo with bootstrap files but no API keys:
  exit code 1, summary=required_failed, doctor.json well-formed JSON.
- Dry run against synthetic repo with bootstrap + git author:
  branch field correctly resolves "master".

## Why exit 0 unless REQUIRED fails

The current preflight in ralph-loop.sh already aborts on missing API keys and
missing CLI. The doctor adds structured, JSON-recorded checks the iPad can see
post-run via the workflow tail. RECOMMENDED items (Ollama, secondary keys,
gateway health) are warnings — they degrade later iterations but do not block
iter-0, which matches how IMPLEMENTATION_PLAN.md was split in PR #23.

## Why no systemd in the installer

The OpenClaw gateway is launched via the openclaw CLI, not systemd (verified
by ralph-preflight in PR #22 and documented in restart-gateway.sh). The
installer mirrors that pattern: ollama is started under nohup with disown
and logs to ~/.openclaw/logs/ollama.log. No sudo, no unit files, no
assumption about the host init system.

## Safety snapshot at build time

- Workstation pwd: /home/user/workspace
- Host: e2b.local (build sandbox)
- Disk: 53% used, 10G avail
- Memory: 7.3Gi avail of 7.8Gi
- Repo state checked via gh api (read-only): scripts/ has 8 files,
  .github/workflows/ has 8 workflows, no docs/ dir yet.
- Backups: no live server filesystem touched. .ralph/backups/ on the
  server is created by Ralph itself when it runs the doctor block — the
  doctor only writes .ralph/doctor.json.

## PRESERVE list — never touched by this change

- configs/balanced.openclaw.json
- server-config/, templates/
- ~/.openclaw/.env, ~/.openclaw/workspace/, ~/.openclaw/.sync-backups/, ~/.openclaw/logs/
- skills/open-ralph/
- .clawhub/, .openclaw/, workspace/

## Related PRs (context)

- PR #21 OPEN — deploy/healthcheck/rollback hardening
- PR #22 MERGED — read-only Ralph preflight workflow
- PR #23 OPEN — Ralph loop-ready (PATH export, iter-0 unblocked)
- This PR (iter-doctor) — pre-iteration dependency doctor

## Rollback

Revert this PR with gh pr revert. The doctor block in ralph-loop.sh and the
tail line in ralph-loop.yml are additive — removing them returns to the
PR #23 baseline. No state outside .ralph/ is touched.
