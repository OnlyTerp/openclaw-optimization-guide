---
name: multi-session-discipline
description: "Fires on multi-session projects. Enforces one-feature-at-a-time, progress.txt with done/in-progress/next sections, and session-start re-read of progress.txt."
triggers:
  - "multi-session"
  - "long project"
  - "progress.txt"
  - "where did we leave off"
metadata: { "openclaw": { "emoji": "📋", "events": ["agent:bootstrap"] } }
---

# multi-session-discipline Skill

Replaces the "Multi-Session Projects" prose previously living in AGENTS.md.

## Rules

1. **One feature at a time.** Don't fan out across multiple in-flight features in the same project.
2. **Create `progress.txt`** with three sections: `done`, `in-progress`, `next`.
3. **Start every session by reading `progress.txt`** for the active project. This is the handoff between sessions.
4. **End every session by updating `progress.txt`** — move what shipped to `done`, leave a one-line pointer for `next`.
5. **On context switches:** write a TASK HANDOFF NOTE (see `vault/06_system/cost-aware-operator.md`) before pivoting.
