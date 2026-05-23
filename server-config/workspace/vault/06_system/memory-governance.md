# Memory governance — what does/doesn't go in MEMORY.md

## What goes in MEMORY.md (hot path, DM-only)

- Pointers into vault for active brands, hard rules, decisions, profile.
- Hard-rule reminders that gate behavior every turn (co-parenting, brand isolation, children, credentials).
- Anything required for the agent to make safe choices without a `memory_search`.

## What does NOT go in MEMORY.md

- Specific co-parenting content or names of the other parent.
- Children's specific personal info (school, schedule, medical).
- Credentials, API keys, tokens.
- Raw daily logs — those go in `memory/YYYY-MM-DD.md`.
- Long-form prose that can be retrieved via `memory_search`. Move it to a `vault/06_system/` claim-named file and add a pointer in MEMORY.md.

## Promotion flow

1. New observation lands in `memory/YYYY-MM-DD.md` (raw daily log).
2. If it's durable, add a candidate to `memory-candidates/` and ask Kevin.
3. On Kevin's OK, write it to the appropriate `vault/06_system/` file and add a pointer to MEMORY.md if it gates behavior.
4. Never edit MEMORY.md silently. Approval-gated.

## Maintenance cadence

Review every few days. Promote durable lessons. Remove obsolete pointers. Keep MEMORY.md under 3 KB.
