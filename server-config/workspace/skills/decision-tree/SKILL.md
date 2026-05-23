---
name: decision-tree
description: "Routing rules for what to answer directly vs spawn a sub-agent vs memory_search first. Replaces the AGENTS.md decision tree without polluting the third-party clawrouter skill."
triggers:
  - "decision tree"
  - "should I spawn a sub-agent"
  - "should I memory_search"
  - "route this request"
metadata: { "openclaw": { "emoji": "🌳", "events": ["agent:turn:start"] } }
---

# decision-tree Skill

Fires at the start of each turn. Routes the request to the right execution mode.

## Rules (in order)

1. **Casual chat / quick fact** → answer directly, no tools.
2. **Past work / projects / people / decisions** → `memory_search` FIRST (hot-path memory rule). Don't claim "I don't remember" without searching.
3. **Code task (3+ files or 50+ lines)** → spawn sub-agent (worker model, see `skills/coordinator-protocol/`).
4. **Research task (needs web / multi-source synthesis)** → spawn sub-agent.
5. **2+ independent tasks in one prompt** → spawn ALL workers in parallel (default), never serially.
6. **Long-running project (multi-session)** → `skills/multi-session-discipline/` — read `progress.txt` first.
7. **Touching `vault/`** → `skills/vault-orientation/` fires (claim-named files, MOC update on exit).
8. **Touching `inbox/`** → `hooks/auto-capture/` family routes; never file into a lane on first capture.
9. **Sensitive writing (co-parenting, public publish, MEMORY.md edits, external send)** → approval gate fires (`SECURITY.md` items 1, 2, 3, 11). Draft and show, never send and tell.
10. **Cost-sensitive choice** → COST_AWARE_OPERATOR.md summary (Sonnet default, not Opus). Full rules: `vault/06_system/cost-aware-operator.md`.

## Why this is a skill, not clawrouter content

`clawrouter` is a third-party blockrun.ai skill — modifying it directly would break on updates. This skill holds Kevin's private routing logic; clawrouter handles model selection within those routes.
