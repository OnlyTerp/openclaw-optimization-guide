# Part 12: Self-Improving System (Stop Making the Same Mistakes)

Your agent makes a mistake Monday. You correct it. Tuesday, same mistake. Wednesday, same mistake. Every session starts fresh — corrections evaporate.

**The fix: a micro-learning loop that costs <100 tokens/message and compounds forever.**

## The Architecture

```
Every message:
  Did the user correct me?     → append to .learnings/corrections.md
  Did a command fail?          → append to .learnings/ERRORS.md
  Did I learn something new?   → append to .learnings/LEARNINGS.md

Every session start:
  Read .learnings/HOT.md       → follow active rules

Daily (cron, $0):
  Scan for 3+ repeated patterns → promote to HOT.md

Weekly (cron, $0):
  HOT entries used 30+ days    → promote to AGENTS.md/SOUL.md (permanent)
  HOT entries unused 30 days   → demote to archive
```

### Why This Works

- **Week 1**: 5 corrections logged. Agent still makes mistakes but they're recorded.
- **Week 2**: Repeated patterns promoted to HOT.md. Agent reads HOT.md every session — stops making those specific mistakes.
- **Week 4**: Best learnings promoted to AGENTS.md. They're now permanent rules, loaded every message. The agent is measurably smarter than week 1.
- **Week 8**: 30+ corrections avoided automatically. System compounds.

### Why Existing Approaches Fail

Most "self-improving" agent setups just dump full session summaries into a vector database. This naive approach fails because:

- **Problem 1: No filtering** — every message, typo, and false start gets embedded, drowning real insights in noise. Signal-to-noise ratio collapses.
- **Problem 2: No promotion** — a critical architecture fix from yesterday sits next to "lunch was good" in the same flat vector space. High-impact learnings never rise to prominence.
- **Problem 3: No decay** — a correction from 3 months ago ("always run on r6g.2xlarge") persists even after infrastructure changes, actively poisoning decisions.

The micro-learning loop fixes this with:

- **Selective capture**: Only log 4 events: user corrections, tool failures, discovered insights, stated preferences.
- **Tiered promotion**: Entries flow from raw logs → HOT.md → AGENTS.md/SOUL.md → vault based on usage and impact.
- **Active decay**: Unused entries automatically demote and eventually archive, keeping the active memory lean and current.


### Setup

**Step 1: Create the learnings directory**

```
workspace/
  .learnings/
    HOT.md              # Active rules, loaded every session
    corrections.md      # User corrections log
    ERRORS.md           # Command/tool failure log
    LEARNINGS.md        # General insights
    FEATURE_REQUESTS.md # Ideas for improvement
    projects/           # Project-specific learnings
    domains/            # Domain-specific learnings
    archive/            # Demoted cold entries
```

**Step 2: Add the micro-learning loop to AGENTS.md**

```markdown
### Micro-Learning Loop (EVERY MESSAGE — silent, <100 tokens)
After EVERY response, silently check:
  1. Did user correct me?        → append 1-line to .learnings/corrections.md
  2. Did a command/tool fail?    → append 1-line to .learnings/ERRORS.md
  3. Did I discover something?   → append 1-line to .learnings/LEARNINGS.md
  4. Did user state a preference? → append 1-line to .learnings/corrections.md

Format: "- [YYYY-MM-DD] <what happened> → <what to do instead>"
If nothing to log, do nothing. Zero overhead on normal messages.
```

**Step 3: Add session start check to AGENTS.md**

```markdown
### Session Start (ONCE per session)
  1. Read .learnings/HOT.md — these are active rules, follow them
  2. Check for 3+ repeated patterns → promote to HOT.md
  3. Check for stale HOT entries (30+ days unused) → archive
```

**Step 4: Set up the daily promotion cron ($0)**

Use OpenClaw's cron system with a free model:

```javascript
// Daily at 5 AM — scan for repeated patterns, promote to HOT.md
cron.add({
  name: "Daily Learnings Promotion",
  schedule: { kind: "cron", expr: "0 5 * * *", tz: "America/New_York" },
  sessionTarget: "isolated",
  payload: {
    kind: "agentTurn",
    model: "cerebras/qwen-3-235b-a22b-instruct-2507", // $0
    message: "Read .learnings/corrections.md and ERRORS.md. Find any pattern that appears 3+ times. If found, add to HOT.md. If nothing, exit.",
    timeoutSeconds: 120
  },
  delivery: { mode: "none" }
});
```

### The Full Skill

For a production-ready implementation with HOT/WARM/COLD memory tiers, promotion scripts, and vault integration, see [self-improving on ClawhHub](https://clawhub.ai/pskoett/self-improving-agent) or build a custom version merging:

- **pskoett/self-improving-agent** — structured logging, corrections capture
- **ivangdavila/self-improving** — HOT/WARM/COLD tiered memory with promotion rules

### Cost

| Component | Frequency | Token Cost |
|-----------|-----------|------------|
| Micro-learning checks | Every message | 0 (if nothing to log) / ~20 tokens (if logging) |
| HOT.md read | Session start | ~50-100 tokens |
| Daily cron | Once/day | ~500 tokens on Cerebras ($0) |
| Weekly promotion | Once/week | ~1000 tokens on Cerebras ($0) |

**Total: effectively $0/day.** The improvement compounds. The cost doesn't.
