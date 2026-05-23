---
name: dreaming-phase-gatekeeper
description: "Before accepting agent 'done' signal, verifies that no dreaming memory sweep is mid-phase. Prevents MEMORY.md corruption from mid-consolidation shutdown."
metadata: { "openclaw": { "emoji": "💤", "events": ["command:stop"] } }
---

# dreaming-phase-gatekeeper Hook

Fires on `command:stop` (when the agent signals completion).

Reads `.dreams/state.json` to check if a dreaming sweep is still `in_progress`.
If so, blocks the stop signal so the agent waits for consolidation to finish.

No-ops gracefully if the state file doesn't exist (dreaming not configured).

Exit codes: 0 = allow stop, 2 = hard block (sweep in progress).