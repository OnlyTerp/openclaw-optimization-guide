# Part 16: autoDream — Automatic Memory Consolidation

*Your agent's memory grows forever. Session files pile up. MEMORY.md gets stale. Knowledge gets buried. autoDream fixes this by teaching your agent to consolidate its own memory — automatically, on every session start.*

---

## The Problem

Every OpenClaw session generates knowledge. Decisions get made, lessons get learned, infrastructure changes happen. The `session-memory` hook dutifully saves all of this to `memory/*.md` files.

But nobody cleans it up.

After a month you've got 200+ session files, a MEMORY.md that's either a stale stub or an unmanageable wall of text, and your agent spends half its context window loading irrelevant session transcripts from 3 weeks ago.

Claude Code solved this with a system called **autoDream** — a background memory consolidation engine. We reverse-engineered the pattern from their [leaked source code](https://github.com/instructkr/claude-code) and adapted it for OpenClaw.

The key insight: **you don't need a new script or cron job. Your agent IS the consolidation engine — you just need to give it instructions.**

---

## How It Works

### The 3-Gate Trigger (Cheapest-First)

autoDream doesn't run every session — that would waste time on casual chats. It uses gates checked in **cheapest-first order** (stop at first failure):

| Gate | Condition | Cost | Why |
|------|-----------|------|-----|
| **TIME** | ≥24 hours since last dream | 1 read | Don't consolidate too often |
| **SCAN THROTTLE** | ≥10 minutes since last gate check | 1 read | Prevent thrashing when time passes but sessions haven't accumulated |
| **SESSION** | ≥5 sessions since last dream (excluding current) | 1 read | Ensure enough new material |
| **USER** | User's first message isn't urgent | Judgment | Don't delay someone who needs help NOW |

The scan throttle is key — without it, every single message re-checks the session count once the time gate passes. Claude Code's actual implementation uses `SESSION_SCAN_INTERVAL_MS = 10 * 60 * 1000` (10 minutes) for this.

State is tracked in `memory/.dream-state.json`:
```json
{
  "lastDreamAt": "2026-03-31T15:47:00Z",
  "sessionsSinceDream": 0,
  "lastScanAt": null,
  "totalDreams": 1,
  "lastDreamResult": "success",
  "lastProcessedFiles": ["2026-03-31-session.md"]
}
```

**Failure recovery:** If a dream crashes mid-execution, reset `lastDreamAt` to its previous value so the time gate passes again on the next attempt. This is Claude Code's "lock rollback" pattern — don't let a failed dream block all future dreams.

### The 4-Phase Execution

When gates pass, the agent runs a consolidation pass (2-3 minutes max) before responding:

**Phase 1 — Orient** (30s)
- Read MEMORY.md and dream-state.json
- List memory files modified since last dream

**Phase 2 — Gather** (60s)
- Do NOT exhaustively read every session file — grep narrowly for things that matter
- Scan memory files modified since last dream for durable knowledge: decisions, lessons, project changes, infrastructure updates
- Skip ephemeral stuff (casual chat, temporary debugging)
- Session transcripts (`.jsonl` files) are **last resort** — only grep for narrow terms if you suspect something specific. Claude Code's actual prompt says: *"Don't exhaustively read transcripts. Look only for things you already suspect matter."*

**Phase 3 — Consolidate** (60s)
- Write durable knowledge to organized files (or vault if you have one)
- **Treat written entries as immutable** (from [Letta/MemGPT](https://docs.letta.com/) architecture): if a fact changes, write a NEW entry that supersedes the old one and link to it — don't silently edit old files. This preserves the decision trail so you can see WHY something changed, not just what.
- Convert relative dates ("yesterday") to absolute dates ("2026-03-31")

**Phase 4 — Prune & Index** (30s)
- Rebuild MEMORY.md as a **pure index** — NOT a content dump
- Each entry: `- [Title](file.md) — one-line hook` (under ~150 chars per line)
- Never write memory content directly into MEMORY.md — detail belongs in topic files
- Keep MEMORY.md under **200 lines AND ~25KB** (Claude Code hard-enforces both caps with truncation warnings)
- Fix contradictions at the source — edit the old file, don't just note the conflict
- Update dream-state.json
- Tell the user: "🌙 Memory consolidated — processed N files"

> From the actual Claude Code source (`memdir.ts`):
> ```typescript
> export const MAX_ENTRYPOINT_LINES = 200
> export const MAX_ENTRYPOINT_BYTES = 25_000
> ```
> If MEMORY.md exceeds either limit, it gets truncated with a warning: *"Only part of it was loaded. Keep index entries to one line under ~200 chars; move detail into topic files."*

---

## Setup: Standard OpenClaw (No Custom Embeddings)

This works with **any** OpenClaw install — no special embedding server, no vault system, no extra infrastructure. Just workspace files.

### Step 1: Create the dream state file

```bash
# Linux/Mac
mkdir -p ~/.openclaw/workspace/memory
cat > ~/.openclaw/workspace/memory/.dream-state.json << 'EOF'
{
  "lastDreamAt": null,
  "sessionsSinceDream": 0,
  "lastDreamDurationMs": null,
  "lastDreamResult": null,
  "totalDreams": 0,
  "lastProcessedFiles": []
}
EOF
```

```powershell
# Windows
New-Item -ItemType Directory -Path "$env:USERPROFILE\.openclaw\workspace\memory" -Force
@'
{
  "lastDreamAt": null,
  "sessionsSinceDream": 0,
  "lastDreamDurationMs": null,
  "lastDreamResult": null,
  "totalDreams": 0,
  "lastProcessedFiles": []
}
'@ | Set-Content "$env:USERPROFILE\.openclaw\workspace\memory\.dream-state.json" -Encoding UTF8
```

### Step 2: Create a `topics/` directory for consolidated knowledge

```bash
mkdir -p ~/.openclaw/workspace/memory/topics
```

This is where the dream will write organized topic files. Instead of 200 session files, you'll have:
```
memory/
├── .dream-state.json          # Trigger tracking
├── topics/
│   ├── infrastructure.md      # Server configs, ports, services
│   ├── projects.md            # Active project status
│   ├── decisions.md           # Key decisions and why
│   ├── lessons.md             # What broke and how we fixed it
│   └── people.md              # Contacts, accounts, identities
├── 2026-03-31-session1.md     # Recent (not yet consolidated)
├── 2026-03-31-session2.md     # Recent (not yet consolidated)
└── archive/                   # Old sessions (after consolidation)
```

### Step 3: Add autoDream instructions to AGENTS.md

This is the entire implementation — no scripts, no hooks, no cron jobs. Just instructions your agent follows:

```markdown
## autoDream — Memory Consolidation

### On Every New Session
1. Read `memory/.dream-state.json`
2. Increment `sessionsSinceDream` by 1, write back
3. Check gates:
   - TIME: ≥24 hours since lastDreamAt (or null)
   - SESSION: sessionsSinceDream ≥ 5
   - USER: First message isn't urgent
4. If ALL pass → run dream before responding
5. If not → respond normally

### Dream Execution (max 3 minutes)
**Phase 1 — Orient**: Read MEMORY.md, list memory files since last dream
**Phase 2 — Gather**: Grep narrowly for durable knowledge. Don't read every file. Transcripts = last resort.
**Phase 3 — Consolidate**: Write to topics/ files, update contradictions at the source, fix relative dates to absolute
**Phase 4 — Prune**: Rebuild MEMORY.md as pure link index (<200 lines, <25KB). Each line: `- [Title](file.md) — hook`. Update dream-state. On failure, rollback lastDreamAt so it retries.

### Rules
- Don't modify source code or config during dreams
- Don't delete session files — just write topic files and rebuild MEMORY.md  
- If dream takes >3 minutes, stop and note what's left
- After dreaming, briefly tell the user: "🌙 Memory consolidated — processed N files"
```

### Step 4: Seed MEMORY.md with the auto-generation marker

Replace your current MEMORY.md with:

```markdown
# MEMORY.MD — Agent Index
_Auto-generated by autoDream | Last dream: never_

## Quick Reference
(This section will be auto-populated after the first dream)

## Active Projects
(Will be filled from session memory files)

## Recent Decisions
(Will be filled from session memory files)

## Key Rules
- Search memory before saying "I don't remember"
- Backup config before editing
```

That's it. On the 6th session after 24 hours, your agent will automatically consolidate everything.

---

## Setup: Advanced (With Custom Embeddings / Vault System)

If you followed Part 9 (Vault) and Part 10 (Custom Embeddings), autoDream can feed directly into your structured vault instead of flat topic files.

### The difference

| Feature | Standard | Advanced |
|---------|----------|----------|
| Consolidated output | `memory/topics/*.md` (flat files) | `vault/decisions/`, `vault/lessons/`, `vault/projects/` |
| MEMORY.md | Auto-generated from topic files | Auto-generated from vault structure |
| Search | OpenClaw built-in memory search | Custom embeddings (Qwen3, etc.) + hybrid search |
| Cross-agent sharing | Single workspace | Multiple workspaces via `extraPaths` |

### Advanced Phase 3 — Consolidate into Vault

Instead of writing to `topics/`, write to your vault categories:

```markdown
### Phase 3 — Consolidate (Advanced)
- New decisions → `vault/decisions/{slug}.md`
- Lessons learned → `vault/lessons/{slug}.md`
- Project milestones → `vault/projects/{slug}.md`
- Infrastructure changes → update existing vault entries
- Research findings → `vault/research/{slug}.md`
- Use the same format as existing vault entries (title, date, sections)
```

### Advanced Phase 4 — Rebuild MEMORY.md from Vault

```markdown
### Phase 4 — Prune (Advanced)
- Rebuild MEMORY.md with sections for each vault category
- List recent entries from each category (last 30 days)
- Include infrastructure summary, active projects, key contacts
- Keep under 200 lines / 25KB
- Move processed session files older than 30 days to memory/archive/
```

### Multi-Agent Dream Coordination

If you have multiple agents sharing a vault via `extraPaths`, only ONE agent should dream. Otherwise you'll get race conditions writing to the same vault files.

Add to the dreaming agent's AGENTS.md:
```markdown
### Dream Ownership
This agent (ops/main) is the ONLY agent that runs autoDream.
Other agents benefit from consolidated vault entries via extraPaths.
```

---

## Tuning the Gates

The default gates (24h + 5 sessions) work well for daily active use. Adjust for your pattern:

| Usage Pattern | Recommended Gates | Why |
|---------------|-------------------|-----|
| Heavy daily use (10+ sessions/day) | 12h + 8 sessions | More frequent consolidation |
| Light use (1-2 sessions/day) | 48h + 3 sessions | Don't wait too long |
| Overnight autonomous (cron/autoresearch) | 6h + 10 sessions | Autonomous runs generate lots of data |
| Development/testing | 1h + 2 sessions | Rapid iteration |

Edit the gate checks in AGENTS.md:
```markdown
- TIME: ≥12 hours since lastDreamAt  (was 24)
- SESSION: sessionsSinceDream ≥ 8     (was 5)
```

---

## What It Looks Like In Practice

### Before autoDream
```
memory/
├── MEMORY.md                    # 48 lines, stale, hand-maintained
├── 2026-02-16-session.md        # 6 weeks old, never read again
├── 2026-02-17-session1.md
├── 2026-02-17-session2.md
├── ... (250 more files)
├── 2026-03-30-session.md
└── 2026-03-31-session.md
Total: 67MB of unorganized session dumps
```

### After autoDream (a few weeks in)
```
memory/
├── MEMORY.md                    # 80 lines, auto-generated, current
├── .dream-state.json            # totalDreams: 12
├── topics/
│   ├── infrastructure.md        # Consolidated from 40+ sessions
│   ├── projects.md              # Current status of all projects
│   ├── decisions.md             # 25 key decisions with rationale
│   ├── lessons.md               # 30 hard-won lessons
│   └── contacts.md              # Accounts, services, people
├── 2026-03-29-session.md        # Recent (not yet consolidated)
├── 2026-03-30-session.md
├── 2026-03-31-session.md
└── archive/                     # 220 old sessions (consolidated)
Total: 67MB unchanged, but organized and searchable
```

The agent boots up, reads a tight 80-line MEMORY.md, and knows exactly where to find deep knowledge. No more loading 250 session files hoping for a vector match.

---

## Inspiration & Source

This pattern is adapted from Claude Code's `autoDream` system, discovered in the [March 31, 2026 source code leak](https://cybersecuritynews.com/claude-code-source-code-leaked/). We read the **actual source files** (`autoDream.ts`, `consolidationPrompt.ts`, `memdir.ts`) before the repos were taken down. Key details from the real implementation:

**From `autoDream.ts`:**
- Forked subagent process (separate from main agent)
- Gate order is cheapest-first: time (1 stat) → scan throttle (10min cooldown) → sessions (dir listing) → lock
- Current session excluded from session count
- `SESSION_SCAN_INTERVAL_MS = 10 * 60 * 1000` prevents re-scanning every turn
- Lock rollback on failure so dreams retry automatically
- `skipTranscript: true` — dream conversations don't save as sessions

**From `consolidationPrompt.ts`:**
- *"You are performing a dream — a reflective pass over your memory files"*
- *"Don't exhaustively read transcripts. Look only for things you already suspect matter."*
- *"Deleting contradicted facts — if today's investigation disproves an old memory, fix it at the source"*
- Read-only bash, write via file tools only to memory directory

**From `memdir.ts`:**
- `MAX_ENTRYPOINT_LINES = 200`, `MAX_ENTRYPOINT_BYTES = 25_000` — hard enforced with truncation
- MEMORY.md is a **link index**: `- [Title](file.md) — one-line hook` (never content)
- Memory files use YAML frontmatter with `name`, `description`, `type` fields
- Four memory types: user, feedback, project, reference

Our adaptation replaces the forked subagent with **agent instructions** — simpler, zero maintenance, and works with any OpenClaw model (you don't need Opus). The consolidation quality depends on your model choice, but even a fast model like Cerebras or Flash can handle the gather→consolidate→prune workflow.

---

## Quick Start Checklist

- [ ] Create `memory/.dream-state.json` with null state
- [ ] Create `memory/topics/` directory (or use vault if Part 9 is set up)
- [ ] Add autoDream instructions to AGENTS.md
- [ ] Replace MEMORY.md with auto-generation template
- [ ] Wait 5+ sessions and 24+ hours
- [ ] Verify: does MEMORY.md have "Auto-generated by autoDream"?
- [ ] Verify: do `topics/` files contain consolidated knowledge?
- [ ] Verify: does dream-state.json show `totalDreams > 0`?

---

*Next: [Part 17 →](./part17-coordinator-protocol.md) — Multi-agent coordinator workflow (Research → Synthesis → Implementation → Verification)*
