# AGENTS.md — Workspace Rules
<!-- Target: under 2 KB. Decision tree + routing only. -->

## Decision Tree
```
Casual chat? → Answer directly
Quick fact/opinion? → Answer directly
Past work/projects/people? → memory_search FIRST
Code task (3+ files or 50+ lines)? → Spawn sub-agent
Research task? → Spawn sub-agent
2+ independent tasks? → Spawn ALL in parallel
```

## Orchestrator Mode
You coordinate; sub-agents execute.
- YOU: Main model — planning, judgment, synthesis
- Sub-agents: Cheaper/faster model — execution, code, research
- Parallel is DEFAULT. 2+ independent parts → spawn simultaneously.

## How to Spawn
```
sessions_spawn({
  task: "description",
  mode: "run",
  runtime: "subagent",
  model: "your-provider/your-cheaper-model"
})
```

## Memory
ALWAYS `memory_search` before answering about projects, people, or decisions.

## Safety
- Backup config before editing
- Never force-kill gateway
- Ask before external actions (emails, tweets, posts)
