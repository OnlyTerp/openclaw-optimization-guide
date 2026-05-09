# Ralph Dependency Doctor

Read-only health check for the Ralph autonomy loop on the OpenClaw server.
Verifies everything Ralph needs before any LLM call is made, writes a JSON
report to `.ralph/doctor.json`, and exits non-zero only when a REQUIRED-iter-0
check fails.

## What it checks

REQUIRED for iter-0 to run at all:

- `PROMPT.md`, `AGENTS.md`, `IMPLEMENTATION_PLAN.md` at repo root
- `.ralph/` writable
- `claude` CLI on PATH (or `opencode` as fallback)
- `ANTHROPIC_API_KEY` in environment or one of the known `.env` files
- Git `user.name` and `user.email` configured
- `git ls-remote origin` succeeds (push auth works)
- `gh` CLI installed and authenticated

RECOMMENDED (warns only, never blocks):

- Ollama daemon reachable at `http://127.0.0.1:11434`
- `qwen3-embedding:0.6b` model pulled in Ollama
- `OPENROUTER_API_KEY`, `DEEPSEEK_API_KEY` for fallback chain
- Gateway `/health` on port 18789 responding
- Disk and memory snapshot (informational)

## How to run

Manual:

    bash scripts/ralph-doctor.sh

Quiet (only writes JSON):

    bash scripts/ralph-doctor.sh --quiet

JSON to stdout (for piping):

    bash scripts/ralph-doctor.sh --json-only

Output report path:

    .ralph/doctor.json

## Exit codes

- `0` — all REQUIRED checks passed (RECOMMENDED may still warn)
- `1` — at least one REQUIRED check failed; iter-0 will not work

## Wiring into the loop

`scripts/ralph-loop.sh` calls the doctor immediately after `preflight` and
before the first iteration. If REQUIRED checks fail the loop aborts before
any LLM call. The workflow `.github/workflows/ralph-loop.yml` also tails
`.ralph/doctor.json` after the loop finishes so the report is visible from
the iPad without SSH.

## Installing optional deps

Use the explicit installer; nothing auto-installs.

    bash scripts/install-optional-deps.sh status        # see what's missing
    bash scripts/install-optional-deps.sh ollama        # install + start (no systemd)
    bash scripts/install-optional-deps.sh embed-model   # pull qwen3-embedding:0.6b
    bash scripts/install-optional-deps.sh all           # both

The installer mirrors the rest of the OpenClaw stack: no systemd units,
processes are started under `nohup` and survive the SSH session via
`disown`. The Ollama log goes to `~/.openclaw/logs/ollama.log`.

## Tests

    bash scripts/test-ralph-doctor.sh

Six assertions, all sandboxed in `mktemp` directories — never touches the
live `.ralph/`.

## PRESERVE list — never touched

The doctor reads but never modifies:

- `configs/balanced.openclaw.json`
- `server-config/`, `templates/`
- `~/.openclaw/.env`, `~/.openclaw/workspace/`, `~/.openclaw/.sync-backups/`, `~/.openclaw/logs/`
- `skills/open-ralph/`
- `.clawhub/`, `.openclaw/`, `workspace/`

Only `.ralph/doctor.json` is written.

## Related PRs

- PR #21 — deploy/healthcheck/rollback hardening (gateway recovery)
- PR #22 — Ralph preflight read-only workflow (server probe)
- PR #23 — Ralph loop-ready (PATH export, iter-0 unblocked)
- This change (iter-doctor) — pre-iteration dependency doctor
