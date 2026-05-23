---
name: session-start-protocol
description: "Fires on agent:bootstrap. Loads .learnings/HOT.md as active rules, scans .learnings/corrections.md for 3+ repeated patterns to promote, archives HOT entries unreferenced in 30+ days."
metadata: { "openclaw": { "emoji": "🌅", "events": ["agent:bootstrap"] } }
---

# session-start-protocol Hook

Replaces the "Session Start (ONCE per session)" prose previously living in AGENTS.md (line 123-127 of pre-trim).

Fires once per session on `agent:bootstrap`. Reads `.learnings/HOT.md` and emits its contents to stdout as a system note so the agent loads active rules. Scans `.learnings/corrections.md` (and any `.learnings/lanes/*/corrections.md`) for entries that repeat 3+ times and prints them as promotion candidates. Moves HOT entries with no timestamp reference in the last 30 days to `.learnings/archive/`.

Exit codes: 0 always (soft signal, never blocks).
