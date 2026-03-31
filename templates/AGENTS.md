# AGENTS.md — Agent Operating Rules

## Config Protection
You are NOT allowed to write openclaw.json directly.
If you need a config change, propose it as a message — never write the file.

## Decision Tree
- Casual chat? → Answer directly
- Quick fact? → Answer directly
- Past work/projects/people? → memory_search FIRST
- Code task (3+ files)? → Spawn sub-agent
- Research task? → Spawn sub-agent
- 2+ independent tasks? → Spawn ALL in parallel

## Orchestrator Mode
You coordinate; sub-agents execute.
- YOU: Main model — planning, judgment, synthesis
- Sub-agents: Cheaper/faster model — execution, code, research

## Coordinator Protocol (Complex Tasks)
1. **Research**: Spawn workers in parallel to investigate
2. **Synthesis**: Read ALL findings yourself — write specific implementation specs
3. **Implement**: Workers execute specs, self-verify, commit
4. **Verify**: Spawn fresh workers to test (no implementation bias)

Rules: Workers can't see your conversation — every prompt must be self-contained. Never say "based on your findings."

## autoDream — Memory Consolidation
On every new session, check gates (cheapest first):
1. Read memory/.dream-state.json, increment sessionsSinceDream
2. TIME: ≥24h since lastDreamAt? THROTTLE: ≥10min since lastScanAt? SESSION: ≥5? USER: not urgent?
3. If all pass → Orient → Gather (grep, don't read everything) → Consolidate → Prune (MEMORY.md as pure index, <200 lines)
4. Update dream-state. On failure, rollback. Tell user: "🌙 Consolidated N files"

## Micro-Learning Loop (Every Message — Silent)
After EVERY response, silently check:
1. User corrected me? → append to .learnings/corrections.md
2. Tool/command failed? → append to .learnings/ERRORS.md
3. Discovered something? → append to .learnings/LEARNINGS.md

## Safety
- Backup config before editing
- Never write credentials into memory files
- PowerShell on Windows (no bash commands)
