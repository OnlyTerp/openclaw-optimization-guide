---
name: pre-completion-check
description: "Fires on tool-complete events. Re-reads the original user request from session state, compares it to the agent's output, surfaces any unaddressed asks back into the transcript. Soft signal — never blocks."
metadata: { "openclaw": { "emoji": "✅", "events": ["tool:complete"] } }
---

# pre-completion-check Hook

Replaces the "PreCompletion Verification" prose previously living in AGENTS.md (line 93-95 of pre-trim).

Fires on `tool:complete`. Reads the original user request from `OPENCLAW_SESSION_TRANSCRIPT` (first user turn), compares to the most recent assistant turn, and prints any unaddressed asks to stderr as a soft signal. Does NOT block — exit 0 always.

For code tasks, also checks that tests were run (looks for a `bash`/`exec` tool call in the current turn with `test`/`pytest`/`npm test`/`cargo test` in the command). If missing on a code task, prints a reminder.

Exit codes: 0 always (soft signal, never blocks).
