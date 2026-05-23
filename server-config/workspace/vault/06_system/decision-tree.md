# Decision tree

Fronted by the `clawrouter` skill; this doc holds the canonical reference.

- Casual chat → answer directly
- Quick fact → answer directly
- Past work / projects / people → `memory_search` first (memory rule, hot-path)
- Code task (3+ files or 50+ lines) → spawn sub-agent
- Research task → spawn sub-agent
- 2+ independent tasks → spawn ALL in parallel (Coordinator Protocol skill)
- Long-running project (multi-session) → `multi-session-discipline` skill (progress.txt)
- Touching `vault/` → `vault-orientation` skill fires
- Touching `inbox/` → `auto-capture` hook routes; never file directly into a lane on first capture
- Sensitive writing (co-parenting, public publishing, MEMORY.md edits) → approval gate (SECURITY.md item 1, 2, 3, 11)
- Cost-sensitive choice → COST_AWARE_OPERATOR.md summary (Sonnet default, not Opus)
