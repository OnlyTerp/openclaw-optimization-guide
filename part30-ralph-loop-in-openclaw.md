# Part 30: The Ralph Loop In OpenClaw

> New in the April 2026 refresh. The Ralph loop is the autonomous-agent pattern everyone rediscovered this month — a cheap bash `while true` wrapper that keeps re-invoking the agent against a persistent plan until the plan is done. This part ports it cleanly to OpenClaw, using Task Brain flows for state and memory-core for continuity.

> **Read this if** you want to run overnight/unattended work (refactor, migration, backlog triage, bug-fix sweep) and you already know how sub-agents work.
> **Skip if** you're in an interactive human-in-the-loop workflow — Ralph is wrong for that.

## Why "Ralph"

Named for Ralph Wiggum's "me fail English? that's unpossible" — because the loop's defining feature is that the agent is *not allowed to give up*. It keeps running until the exit condition is met by reality (tests green, PRD items all ticked, budget exhausted), not by the agent's opinion about whether the work is done.

The canonical implementation is [`frankbria/ralph-claude-code`](https://github.com/frankbria/ralph-claude-code) (8.7K stars as of mid-April 2026). It's ~250 lines of Node.js wrapping a `while true` around the Claude Code CLI. The pattern is model-agnostic and harness-agnostic — it runs equally well on Claude Code, Cursor CLI, or OpenClaw.

Terp community member `satoru` published *[Stop Babysitting Your AI Agent — Use Ralph Loops + OpenClaw](https://dev.to/satoru_906c2ffeaf64bd2ac1/stop-babysitting-your-ai-agent-use-ralph-loops-openclaw-fdi)* on April 13, 2026 — the explicit "port it to OpenClaw" writeup that inspired this part.

## The Mental Model

```text
      ┌────────────────────────────────────────────────┐
      │                                                │
      ▼                                                │
 [read PRD.json]                                       │
      │                                                │
      ▼                                                │
 [invoke openclaw run --prompt loop-prompt.md]         │
      │                                                │
      ▼                                                │
 [agent updates PRD.json,                              │
  commits progress,                                    │
  runs tests]                                          │
      │                                                │
      ▼                                                │
 [exit if PRD.done or budget.exhausted or loops >= N] ─┘
```

Each iteration:

1. The wrapper reads a **persistent PRD** from disk (the only state that survives between iterations).
2. The wrapper invokes OpenClaw with a **short loop prompt** that tells the agent: read the PRD, pick one unfinished item, make progress, update the PRD, commit, exit.
3. The wrapper checks an exit condition.
4. Repeat.

The key insight: **no context bleeds between iterations**. Every call is a fresh OpenClaw session. Continuity lives in three places:

- **`PRD.json`** — the machine-readable spec.
- **Git history** — commits are the durable trail of what changed.
- **memory-core (MEMORY.md + DREAMS.md)** — what the agent learned, scored and promoted by the Deep-phase sweep (see [Part 22](./README.md#part-22-built-in-dreaming)).

Because context is wiped between iterations, the loop is immune to context bloat. It also composes cleanly with Task Brain — every iteration produces a parent flow; every sub-agent spawn produces a child flow; you can `openclaw flows list` and see the entire run.

## PRD Schema

Minimum viable PRD. Stored at `./PRD.json` in the project root:

```json
{
  "title": "Migrate auth from sessions to JWTs",
  "status": "in_progress",
  "budget": {
    "max_iterations": 40,
    "max_usd": 20.00,
    "max_wall_hours": 4
  },
  "exit_when": [
    "all tasks done",
    "tests green on main",
    "no merge conflicts on PR branch"
  ],
  "tasks": [
    { "id": "T-1", "title": "Add JWT signing/verification util",          "status": "done",        "notes": "utils/jwt.py, 100% cov" },
    { "id": "T-2", "title": "Replace session middleware with JWT",         "status": "in_progress", "notes": "middleware done, route updates pending" },
    { "id": "T-3", "title": "Update login endpoint to issue JWT",          "status": "pending" },
    { "id": "T-4", "title": "Migrate /me endpoint to read JWT",            "status": "pending" },
    { "id": "T-5", "title": "Remove old session store",                    "status": "pending" },
    { "id": "T-6", "title": "Add JWT rotation and revocation",             "status": "pending" }
  ],
  "learnings": [
    "Don't touch frontend until T-5 is complete — cookie cutover matters.",
    "T-2 blocked briefly on circular import; moved jwt util to utils/.",
    "Use RS256, not HS256 — team preference, see memory/2026-04-15.md."
  ],
  "last_iteration": {
    "n": 12,
    "iso": "2026-04-17T02:11:38Z",
    "commit": "a1b2c3d",
    "tokens": 14523,
    "usd": 0.31
  }
}
```

Use JSON, not Markdown, for the state file. JSON survives reformatting; the agent is less likely to accidentally rewrite the schema. Keep `learnings[]` short — under ~15 entries — and promote anything durable to MEMORY.md.

## The Loop Prompt

A single `loop-prompt.md` in the project root. Short on purpose — long prompts defeat the point:

```markdown
# Ralph Loop Prompt

You are one iteration of a Ralph loop. Read the whole prompt first.

## Your state

- Project: $(pwd)
- Persistent plan: ./PRD.json  (read it FIRST — it tells you what's already done)
- Learnings so far: PRD.json `.learnings[]`
- Past memory: MEMORY.md, DREAMS.md  (injected on session start)

## Your job this iteration

1. Read PRD.json.
2. If `status == "done"`, exit immediately with no changes.
3. Pick ONE task with `status != "done"`. Prefer `in_progress` over `pending`.
4. Do the smallest unit of work that moves it forward.
5. Run tests. Real tests, not "I think it works."
6. If tests pass:
   - Update PRD.json (task status, `last_iteration`, append to `learnings[]` if you learned something durable).
   - `git add -A && git commit -m "ralph: <task id> — <short what>"`.
7. If tests fail:
   - Update the task `notes` with what's broken.
   - Do NOT commit. Do NOT declare done.
8. Exit. Say nothing except a 3-line summary.

## Hard rules

- Never mark a task "done" unless tests prove it works.
- Never revert another iteration's work — if you disagree with it, add a learning and pick a different task.
- Never delete PRD.json. Never push to `main`/`master`.
- If you hit the same failure 3 times in a row, mark the task `blocked`, write a learning, and stop.
- Use sub-agents for broad searches and parallel verification (see AGENTS.md).

Begin.
```

The prompt is deliberately boring. Ralph iterations should feel like a factory line — nothing fancy, just the next unit of work.

## The Wrapper

A minimal bash wrapper that runs on macOS/Linux. PowerShell port is mechanical.

```bash
#!/usr/bin/env bash
# scripts/ralph.sh — run the Ralph loop until PRD is done or budget is exhausted
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
cd "$PROJECT_ROOT"

[ ! -f PRD.json ]        && { echo "PRD.json missing"; exit 1; }
[ ! -f loop-prompt.md ]  && { echo "loop-prompt.md missing"; exit 1; }

max_iter=$(jq -r '.budget.max_iterations // 40'  PRD.json)
max_usd=$(jq  -r '.budget.max_usd // 20'         PRD.json)
max_hours=$(jq -r '.budget.max_wall_hours // 4'  PRD.json)

start=$(date +%s)
total_usd=0.00
i=0

while : ; do
  i=$((i+1))
  status=$(jq -r '.status' PRD.json)
  [ "$status" = "done" ] && { echo "[ralph] PRD.done — exiting at iter $i"; break; }

  elapsed=$(( ($(date +%s) - start) / 3600 ))
  [ "$elapsed" -ge "$max_hours" ] && { echo "[ralph] wall-clock budget exhausted"; break; }
  [ "$i" -gt "$max_iter" ]         && { echo "[ralph] iteration budget exhausted"; break; }

  echo "[ralph] === iter $i (elapsed ${elapsed}h, spent \$$total_usd) ==="

  # Fresh OpenClaw session per iteration. --ephemeral keeps it out of your main history.
  out_json=$(openclaw run \
      --prompt-file loop-prompt.md \
      --ephemeral \
      --output json)

  iter_usd=$(echo "$out_json" | jq -r '.usage.cost_usd // 0')
  total_usd=$(echo "$total_usd $iter_usd" | awk '{print $1 + $2}')

  (( $(echo "$total_usd >= $max_usd" | bc -l) )) && { echo "[ralph] USD budget exhausted"; break; }

  # Let the dreaming scheduler consolidate anything learned before the next iteration.
  sleep 2
done

# Final summary.
echo
echo "[ralph] final status=$(jq -r '.status' PRD.json) iterations=$i spent=\$${total_usd}"
jq '.tasks[] | {id, status}' PRD.json
```

Four things the wrapper is deliberately **not** doing:

- **No sandbox.** Run Ralph in a worktree or container (see [Part 15](./part15-infrastructure-hardening.md) on parallel OpenClaw with worktrees). The wrapper trusts its cwd.
- **No automatic PR push.** Commits land on the current branch; a separate step opens the PR. Don't let Ralph push to remote autonomously; the blast radius isn't worth it.
- **No retry on tool-call failure.** If OpenClaw crashes, the wrapper should die loudly. Resuming from a half-applied commit is worse than restarting cleanly.
- **No interactive prompts.** Ralph runs overnight. Any hook that wants approval must block at `exit 2` or fall back to a default — see [Part 29 — Hook Catalog](./part29-hook-catalog.md).

## Exit-Condition Detection

The `exit_when` list in the PRD is the agent-visible summary. The wrapper should also enforce at least:

- `budget.max_iterations` hit — hard stop.
- `budget.max_usd` hit — hard stop.
- `budget.max_wall_hours` hit — hard stop.
- 3 consecutive iterations with `last_iteration.commit` unchanged — stall detection, hard stop.
- Any task with `status: "blocked"` and `blocked_reason` longer than 200 chars — probably a real external blocker, hard stop for human review.

Run this every iteration:

```bash
last_commit=$(jq -r '.last_iteration.commit' PRD.json)
if [ "$last_commit" = "${PREV_LAST_COMMIT:-}" ]; then
  stalled=$((stalled + 1))
else
  stalled=0
fi
PREV_LAST_COMMIT=$last_commit
[ "$stalled" -ge 3 ] && { echo "[ralph] stalled — 3 iters without progress"; break; }
```

## What This Composes With

- **Sub-agents ([Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)).** The Ralph agent is the main orchestrator each iteration. It should still spawn workers for anything parallel.
- **Hook catalog ([Part 29](./part29-hook-catalog.md)).** Cost tripwire + skill-install-deny + auto-formatter make the loop safe to leave unattended.
- **Built-in dreaming ([Part 22](./README.md#part-22-built-in-dreaming)).** The durable memory layer for the loop. `PRD.learnings[]` are short-term; MEMORY.md is long-term.
- **Git worktrees ([Part 15](./part15-infrastructure-hardening.md)).** Run multiple Ralph loops on different tasks in parallel without conflicting workspaces.
- **SDD ([Part 26](./part26-migration-guide.md)).** The PRD *is* the spec. Spec-Driven Development and Ralph are the same idea viewed from two sides.

## Further Reading

- *[frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code)* — canonical reference implementation, 8.7K stars.
- *[Stop Babysitting Your AI Agent — Use Ralph Loops + OpenClaw](https://dev.to/satoru_906c2ffeaf64bd2ac1/stop-babysitting-your-ai-agent-use-ralph-loops-openclaw-fdi)* — Apr 13, 2026. OpenClaw-specific port.
- *[PyShine — Ralph loop for autonomous agents](https://pyshine.com/)* — Apr 13, 2026. Python-first take on the same pattern.
- *[ghuntley.com/loop](https://ghuntley.com/loop/)* — the original "Ralph Wiggum loop" post that defined the name.
- *[Tekai — Ralph loops in production](https://tekai.dev/)* — Apr 11, 2026. Real-world results from a week of autonomous runs.

## See Also

- [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself) — the manual-driver version of the same pattern.
- [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md) — worktrees for running Ralph in parallel.
- [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming) — the durable memory layer.
- [Part 29 — Hook Catalog](./part29-hook-catalog.md) — the safety rails every Ralph loop should run behind.
