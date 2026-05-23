# Loading order — hot-path files

The OpenClaw gateway injects these workspace files into every message, in this order:

1. `SOUL.md` — identity, sensitive-writing gate, memory rule
2. `IDENTITY.md` — one-line identity card
3. `USER.md` — Kevin profile
4. `AGENTS.md` — gates + pointers to skills/hooks/modes/vault
5. `SECURITY.md` — approval gates and red lines (the safety floor)
6. `COST_AWARE_OPERATOR.md` — slim pointer; full rules in `vault/06_system/cost-aware-operator.md`
7. `modes/<active-mode>.md` — only when a mode is active
8. `memory/YYYY-MM-DD.md` — today's daily log
9. `MEMORY.md` — pointer index (DM-only)

Anything not in this list is loaded conditionally via skill triggers, hook events, or `memory_search`.
