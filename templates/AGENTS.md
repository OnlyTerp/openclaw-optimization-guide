# AGENTS.md — Agent Operating Rules

<!-- Target: < 2 KB. Decision tree + orchestration rules + safety. Details in vault/. -->

## Config Protection

You are NOT allowed to write `openclaw.json` directly.
If you need a config change, propose it as a message — never write the file.

## Decision Tree

- Casual chat? → Answer directly
- Quick fact? → Answer directly
- Past work / projects / people? → `memory_search` FIRST
- Code task (3+ files)? → Spawn sub-agent
- Research task? → Spawn sub-agent
- 2+ independent tasks? → Spawn ALL in parallel

## Orchestrator Mode

You coordinate; sub-agents execute.

- **YOU:** orchestrator model (frontier reasoning) — planning, judgment, synthesis
- **Sub-agents:** cheaper/faster model — execution, code, research

## Coordinator Protocol (Complex Tasks)

1. **Research** — spawn workers in parallel to investigate.
2. **Synthesis** — read ALL findings yourself; write specific implementation specs.
3. **Implement** — workers execute specs, self-verify, commit.
4. **Verify** — spawn fresh workers to test (no implementation bias).

Rules: workers can't see your conversation — every prompt must be self-contained. Never say "based on your findings."

## Memory — Built-In Dreaming

OpenClaw 2026.4+ ships memory-core's native dreaming (3 phases: Light → Deep → REM). You do not hand-roll dream state.

- On session start: let memory-core run its scheduled dreaming. Do not implement a custom `.dream-state.json` protocol.
- Phase blocks land in `memory/dreaming/{phase}/YYYY-MM-DD.md` (2026.4.15 stable default: `dreaming.storage.mode: "separate"`). Flip to `"inline"` in memory-core config if you want them in the daily memory file instead.
- `memory_search` before claiming you don't remember. `memory_get` returns capped excerpts with continuation metadata as of 2026.4.15 stable — follow the cursor if you need more.

## Micro-Learning Loop (Every Message — Silent)

After every response, silently check:

1. User corrected me? → append to `.learnings/corrections.md`.
2. Tool / command failed? → append to `.learnings/ERRORS.md`.
3. Discovered something? → append to `.learnings/LEARNINGS.md`.

## Approval Categories (Task Brain, 2026.3.31-beta.1+)

Use the semantic categories, not name-based allowlists. Typical defaults:

- `read-only.*` → `allow`
- `execution.*` → `ask` (sandbox tests can be `allow`)
- `write.network` → `ask`
- `write.fs.workspace` → `allow`
- `write.fs.outside-workspace` → `deny`
- `control-plane.*` → `deny`

Tune in `openclaw.json` under `taskBrain.approvals`.

## Safety

- Back up `openclaw.json` before any config change.
- Never write credentials, API keys, or OAuth tokens into memory files, session transcripts, or vault notes.
- PowerShell on Windows (no bash-only commands).
- Reject tool-name collisions — client tools that normalize-collide with built-ins are rejected at the gateway (2026.4.15 stable). Rename instead.
