---
name: loop-detector
description: "Fires on every command. Tracks edit count per file in the current session. Warns at 4 edits to the same file without other progress; hard-blocks at 6."
metadata: { "openclaw": { "emoji": "🔁", "events": ["command"] } }
---

# loop-detector Hook

Replaces the "Loop Detection" prose previously living in AGENTS.md (line 97-99 of pre-trim).

Fires on `command`. For edit/write tool calls, increments a per-file counter in session state. If the same file is edited 4+ times without an edit to any other file in between, prints a warning to stderr. At 6+ consecutive edits, exits 2 (block) so the agent has to break out of the loop and reconsider.

State stored at `/tmp/openclaw-loop-{SESSION_ID}.json`. Fails OPEN on hook errors (exit 0) — a broken loop detector shouldn't block productive work.

Exit codes: 0 = continue, 2 = block (loop detected).
