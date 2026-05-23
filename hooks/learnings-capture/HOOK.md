---
name: learnings-capture
description: "Micro-Learning Loop. Fires on tool errors and detected user corrections. Appends one line to .learnings/{ERRORS,corrections,LEARNINGS}.md so the agent gets better over time without burning tokens on the rule every turn."
metadata: { "openclaw": { "emoji": "📚", "events": ["tool:error", "command:correction", "command:discovery"] } }
---

# learnings-capture Hook

Replaces the "Micro-Learning Loop" prose previously living in AGENTS.md (pre-trim line 105-114).

Sibling to `hooks/auto-capture/` — different concern. `auto-capture` does AI-driven knowledge extraction into `vault/00_inbox/`. This hook does fast, mechanical, single-line appends to `.learnings/` files (no LLM call).

## Behavior

- `tool:error` → append one line to `.learnings/ERRORS.md`:
  `[YYYY-MM-DD] <tool>: <message> → what to do instead`
- `command:correction` (user corrected the agent) → append to `.learnings/corrections.md` (or `.learnings/lanes/<lane>/corrections.md` if a lane was active and the correction is lane-specific).
- `command:discovery` (agent flagged a discovery worth keeping) → append to `.learnings/LEARNINGS.md` (or lane-specific).

## Hard rule (carried from AGENTS.md pre-trim)

If a correction is about co-parenting, school advocacy, or any locked lane, log only to that lane's folder. Never copy locked-lane corrections into the shared HOT.md or the root LEARNINGS.md.

## Exit codes

0 always (soft signal, never blocks).
