---
name: coordinator-protocol
description: "Fires when the orchestrator spawns sub-agents. Enforces parallel-by-default for independent tasks, self-contained worker prompts (no 'based on the above'), and Research → Synthesis → Implement → Verify staging on multi-step work."
triggers:
  - "spawn sub-agent"
  - "sessions_spawn"
  - "parallel tasks"
  - "coordinator protocol"
  - "research then implement"
metadata: { "openclaw": { "emoji": "🎯", "events": ["agent:spawn"] } }
---

# coordinator-protocol Skill

Replaces the "Orchestrator Mode" prose previously living in AGENTS.md. Fires when the orchestrator is about to spawn a sub-agent.

## Rules

1. **Orchestrator coordinates; sub-agents execute.** Main model does planning, judgment, synthesis. Workers do execution, code, research.
2. **Parallel is default.** 2+ independent tasks → spawn ALL simultaneously, never serially.
3. **Worker prompts are self-contained.** Never write "based on the above" / "your findings" / "the plan". Each worker gets everything it needs in its own prompt.
4. **Coordinator Protocol on multi-step work:** Research → Synthesis → Implement → Verify. Each stage is a fresh worker; no shared context between stages.
5. **Pick the cheapest capable worker model** (see `COST_AWARE_OPERATOR.md` pointer: Haiku for mechanical, Sonnet for default, Opus only when justified).

Full guide: `part5` of the optimization guide and `vault/06_system/decision-tree.md`.
