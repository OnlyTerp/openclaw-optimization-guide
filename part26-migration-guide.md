# Part 26: Migration Guide

> New in the 2026.4.15 refresh. Opinionated, battle-tested upgrade paths from older OpenClaw versions to current. If something in this guide doesn't apply to your version yet, start here.

> **Read this if** you're on anything older than 2026.4.15, or planning an upgrade.
> **Skip if** you're already on current-beta and don't maintain older instances.

## TL;DR By Version

| You're on | Do this first | Then | Finally |
|-----------|--------------|------|---------|
| **v3.x** | Full v4.0 upgrade (not a drop-in) | v4.1 ClawHub | 2026.4.15 |
| **v4.0.x** | v2026.3.31-beta.1 (Task Brain) | 2026.4.x (built-in dreaming) | 2026.4.15 |
| **v2026.3.x** | Apply Task Brain approval policy | Upgrade to 2026.4.x | 2026.4.15 |
| **v2026.4.x pre-4.15** | Skip straight to 2026.4.15 | Apply the 4.15 flags | Done |
| **v2026.4.15-beta.1** | Promote to 2026.4.15 stable | Opt in to Opus 4.7 defaults + `dreaming.storage.mode: separate` | Done |

Each step is described below. Don't skip steps — the CVE wave fixes and Task Brain model changes are not optional for anyone running more than a personal-dev setup.

## Before You Upgrade (Every Upgrade, Every Time)

```bash
# 1. Back up your config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-upgrade.$(date +%Y%m%d)

# 2. Back up auth profiles
cp ~/.openclaw/auth-profiles.json ~/.openclaw/auth-profiles.json.pre-upgrade.$(date +%Y%m%d)

# 3. Snapshot your memory + vault
tar -czf ~/openclaw-memory-$(date +%Y%m%d).tgz \
  ~/.openclaw/memory \
  ~/.openclaw/agents/*/sessions \
  ./vault   # if your vault is project-local

# 4. Check current version so you know what to roll back to
openclaw --version
```

**Do not skip the snapshot.** Task Brain changes how tasks are recorded; memory-core changes how dreams are written. If you hit something weird post-upgrade, rolling back to a snapshot beats debugging a half-migrated state.

## Path 1: v3.x \u2192 v4.0

This is the hardest single jump and the one most likely to break configs. v4.0 was a ground-up rewrite.

**Breaking changes:**
- Gateway daemon replaces the old multi-process model. Your existing `openclaw start` scripts probably won't work.
- Cron moves from a plugin to native. Old cron plugin configs need migration.
- Canvas UI replaces the old web UI. Bookmarks break.
- Tool schema changed — custom tools need their manifests updated.
- Session file format changed. Old sessions are read-only after upgrade.

**Steps:**

1. Read the v4.0 release notes in full. No shortcut here.
2. Install v4.0 in parallel — don't replace v3 until you've done a dry run.
3. Export your v3 cron schedules, memory contents, and custom tools. Save as JSON/markdown, not as v3 binary state.
4. Install v4.0 clean, reimport the exports. Expect to hand-fix 10-30% of configs.
5. Point any ACP callers / IDE integrations at the new gateway endpoint.
6. Keep v3 around read-only for a week before uninstalling.

**What breaks if you rush it:**
- Custom tools silently disabled because their manifest is v3-format.
- Cron jobs stop firing because they were registered against the old plugin.
- Memory appears empty in v4.0 because session files live in a different directory.

If you're on v3.x and you want "a few more months of life out of it": stay on v3. If you want any of the rest of this guide: you have to do the v4.0 upgrade. There is no in-between.

## Path 2: v4.0.x \u2192 v2026.3.31-beta.1 (Task Brain)

Significantly easier than v3\u2192v4.0. No data migration, but a policy migration.

**What changes:**
- The old name-based approvals (`allow: ["bash", "exec"]`) still parse but are converted internally to semantic categories.
- All spawns, cron jobs, and ACP calls now flow through the Task Brain ledger.
- Plugin defaults are fail-closed. Unconfigured plugins get `ask` approvals, not free access.

**Steps:**

1. Upgrade the package. Restart the gateway.
2. Run `openclaw flows list`. If it works: Task Brain is live. If you get "command not found": upgrade didn't take, re-check. (Older beta notes called this `openclaw tasks` — the published CLI verb as of 2026.4.15 is `flows`.)
3. Write a semantic approval policy (see [Part 24](./part24-task-brain-control-plane.md)). Don't leave it on defaults for more than a day — you want the policy to match your actual usage or you'll drown in approval prompts.
4. Review `openclaw flows list` and the Canvas **Flows** panel at least once in the first week. You'll spot jobs you forgot existed (old cron, orphaned sub-agent spawns, stuck ACP calls).

**What to watch for post-upgrade:**
- Sub-agent spawns suddenly requiring approval that didn't before — means your per-agent approval policy is too loose at the orchestrator level or too tight at the worker level. Adjust per [Part 24](./part24-task-brain-control-plane.md).
- Skills failing silently — check they're not being denied by fail-closed defaults. Either explicitly allow them in the approval policy, or remove them.
- Cron jobs missing runs the first day — known behavior during ledger initialization; resolves automatically after one cycle.

## Path 3: v2026.3.x \u2192 v2026.4.x

This is mostly smooth.

**What changes:**
- memory-core ships built-in dreaming ([Part 22](./README.md#part-22-built-in-dreaming)) — the native replacement for the custom autoDream pattern that used to live in Part 16 of this guide (now retired and removed from the repo).
- DREAMS.md joins MEMORY.md as a canonical memory file.
- Bundled skill updates across ClawHub.

**Steps:**

1. Upgrade and restart gateway.
2. If you were running the retired custom autoDream pattern (the old Part 16 — `.dream-state.json` + AGENTS.md consolidation protocol): keep it running for 48 hours with the built-in one *also* enabled. Compare `DREAMS.md` entries from both to make sure the built-in is catching what you expect. Then delete `memory/.dream-state.json` and remove the `autoDream` section from your AGENTS.md.
3. If you weren't running any dreaming: enable memory-core's built-in and walk away. Check in after a week.

**Gotchas:**
- If you had custom `memory_get` calls reading arbitrary paths, they'll still work in 4.x but will break at 4.15 — fix them now, don't wait.

## Path 4: Anything v2026.4.x \u2192 v2026.4.15

Small jump. This is the version the guide is currently tested on.

**What changes (the ones you should act on immediately):**
- Compaction reserve-token floor is now capped at the model context window (fixes infinite loops on small local compaction workers).
- Gateway supports hot-reload of auth secrets without a full restart (reuses the `models.authStatus` refresh path from 2026.4.15). The CLI verb for manual reload has moved between betas — check `openclaw --help` on your installed version for the exact spelling.
- Approval prompts redact secrets before showing them to approvers. Previously every approval was a credential leak.
- `memory_get` restricted to MEMORY.md + DREAMS.md only (path-traversal hardening against the qmd backend).
- Memory-lancedb can persist to S3-compatible cloud storage.
- GitHub Copilot embedding provider.
- `agents.defaults.experimental.localModelLean: true` drops heavyweight default tools for weak local models.
- New Model Auth card in Canvas UI shows OAuth token health + rate-limit pressure.

**Steps:**

1. Upgrade. Restart gateway. Run `openclaw doctor`.
2. Open Canvas UI \u2192 Model Auth card. If anything is yellow/red, fix it before doing real work.
3. If you have any skill or hook calling `memory_get("some/path")` with non-canonical paths — fix them now. They fail at 4.15.
4. If you run a small local compaction model: check your `compaction.reserveTokens` is under the model's context window (Part 15). The cap now enforces this, but explicit is better.
5. If you run multi-user approvals: verify the approval UI now shows `sk-***` redacted, not raw keys.
6. Optional: enable `localModelLean` if you have a 14B-or-smaller local agent.
7. Optional: switch to Copilot embeddings *only* if your org already pays for Copilot Business/Enterprise. Local Ollama is still the right default.

## Path 5: v2026.4.15-beta.1 → v2026.4.15 (stable)

Tiny jump. The stable release is a superset of the beta plus a few user-visible defaults changes. Still worth reading because one of them (dreaming storage) changes where your phase blocks land on disk.

**What changes (the ones you should act on immediately):**

- **Anthropic defaults → Claude Opus 4.7.** `opus` aliases, Claude CLI defaults, and bundled image understanding all point at Opus 4.7 now. If you had pinned `"model": "claude-opus-4-6"` explicitly, you keep it; if you used the alias, you silently upgrade.
- **Dreaming storage mode default flipped: `inline` → `separate`.** Phase blocks (`## Light Sleep`, `## REM Sleep`) now land in `memory/dreaming/{phase}/YYYY-MM-DD.md` instead of being appended to the daily memory file at `memory/YYYY-MM-DD.md`. If you had scripts parsing `memory/YYYY-MM-DD.md` for phase markers, update them to read the new path (or opt back in with `plugins.entries.memory-core.config.dreaming.storage.mode: "inline"`).
- **`memory_get` default excerpt cap + continuation metadata.** Long files come back in bounded chunks with a continuation cursor. If you had custom skills that assumed `memory_get` returns a full file, update them to read the cursor — otherwise you get silently truncated reads.
- **Default startup/skills prompt budgets trimmed.** Long sessions pull less context by default. Usually invisible; if a skill suddenly "loses context it used to have," this is why — spell it out explicitly in the skill's system prompt.
- **Gateway tool-name normalize-collision rejection.** If you had an in-house skill or client that registered a tool named the same as a built-in (e.g. `Browser`, `Exec`), it now returns `400 invalid_request_error`. Rename the tool. See [Part 15](./part15-infrastructure-hardening.md).
- **Webchat localRoots containment** on audio embeddings — no action needed, but nice to have.
- **Matrix pairing-auth tightened** — DM pairing-store entries can't authorize room control. No action needed unless you wrote custom Matrix pairing flows.
- **Gemini TTS** in the bundled `google` plugin, plus the false-positive Model Auth alert fix for aliased providers and env-backed OAuth.

**Steps:**

1. Upgrade. Restart gateway. Run `openclaw doctor`.
2. Open Canvas → Model Auth card. Confirm no false-positive alerts for aliased providers.
3. Check your dreaming output: `ls memory/dreaming/{light-sleep,rem-sleep}/` should start showing phase files from tomorrow's run. If you want the old behavior, flip `dreaming.storage.mode` back to `"inline"` in memory-core config.
4. If you have custom skills, grep them for `memory_get(` and audit their handling of truncated excerpts. Add cursor-following logic where needed.
5. If you run in-house tools that shadow built-in names, rename them. They'll hard-fail at the gateway until you do.
6. No rollback plan needed beyond package-pin — this release is additive over 4.15-beta.1. Config that worked on beta.1 works on stable.

## Rollback Plan (Every Path)

If something goes sideways:

```bash
# Stop the gateway
openclaw gateway stop

# Install previous version (example: pin via your package manager)
npm install -g openclaw@2026.4.14  # adjust for your install method

# Restore config
cp ~/.openclaw/openclaw.json.pre-upgrade.YYYYMMDD ~/.openclaw/openclaw.json

# If memory got corrupted during upgrade (rare):
tar -xzf ~/openclaw-memory-YYYYMMDD.tgz -C /

# Restart
openclaw gateway start
openclaw doctor
```

Full rollback takes ~2 minutes if you have the snapshots. If you skipped the snapshots, rollback might not work — Task Brain + memory-core have made enough on-disk format changes that "just reinstalling the old binary" is not enough on the 2026.3.x \u2192 2026.4.x line.

## Pair OpenClaw With A Machine-Readable Spec (Spec-Driven Development)

**Section added in the April 2026 refresh.** The framing caught fire this week: *[Spec-Driven Development: The Key To Scaling Autonomous AI Agents](https://time.news/spec-driven-development-the-key-to-scaling-autonomous-ai-agents/)* (Apr 14, 2026) packaged what a lot of teams had figured out independently: **if the agent's reasoning anchor is a machine-readable spec, everything else gets easier.**

### The AWS Kiro Case Study

The widely-cited proof point: AWS Kiro. Rewrote a core billing subsystem with a spec-first agent workflow. Timeline:

- **Before (human-only):** estimated 18 months.
- **After (SDD with 6 engineers + agents):** 76 days.

Not a 2× speedup. ~7× — because the spec became the single source of truth the agent could both read (to figure out the next task) and write (to record what's now done). Conversation drift stopped consuming cycles.

### The Pattern

The spec is *not* a README. It's a structured, machine-parseable representation of:

1. **Invariants** — what's always true about the system.
2. **Contracts** — APIs, schemas, protocols. Usually OpenAPI / JSON Schema / protobuf.
3. **Task list** — the backlog. Open / in-progress / done.
4. **Acceptance criteria** — how you know each task is done. Testable, not aspirational.
5. **Learnings** — short-form, time-ordered, appended to.

In OpenClaw terms, the spec lives in one file the agent edits: `SPEC.md` or `PRD.json` at the project root. The spec **is** the task the agent works against. Every session:

1. Agent reads the spec first.
2. Agent picks the next unfinished item per the spec's ordering rules.
3. Agent does the work.
4. Agent updates the spec (tasks, learnings, contract changes).
5. Agent commits the spec alongside the code.

### Why This Composes With OpenClaw

Two things OpenClaw already does that make SDD cheap to adopt:

- **MEMORY.md + Dreaming ([Part 22](./README.md#part-22-built-in-dreaming)).** The spec is long-form explicit state; MEMORY.md is model-maintained durable facts. Dreaming's Deep phase promotes learnings from short-term into MEMORY.md; the spec is the hand-written half of the same idea.
- **The Ralph Loop ([Part 30](./part30-ralph-loop-in-openclaw.md)).** SDD + Ralph = PRD.json + 30 lines of bash. The Ralph loop is literally "spec-driven development automated." If you're running Ralph, you're already doing SDD.

### The Minimum Viable Spec

```json
{
  "project": "openclaw-optimization-guide",
  "invariants": [
    "All source citations published Apr 10-17, 2026.",
    "All `part*.md` files lint clean under markdownlint-cli2."
  ],
  "tasks": [
    { "id": "T-1", "status": "done",        "title": "Ship Part 29 Hook Catalog" },
    { "id": "T-2", "status": "in_progress", "title": "Ship Part 30 Ralph Loop" },
    { "id": "T-3", "status": "pending",     "title": "Glossary entries for new terms" }
  ],
  "acceptance": {
    "T-2": ["renders on GitHub", "3+ Apr 10-17 citations", "decision tree at top"]
  },
  "learnings": [
    "Mermaid fences with `<br/>` inside node labels need double-quote wrappers."
  ]
}
```

Anything more than this in the first pass is over-engineering. Grow the schema when it hurts, not before.

### When SDD Is The Wrong Tool

- **Exploratory work.** You don't yet know what the system is. Writing a spec first is ceremony.
- **Very small tasks.** `SPEC.md` for a one-file bugfix is worse than useless.
- **Human-only teams.** SDD's ROI is the agent-readable angle. Pre-agent, a normal PRD is fine.

**Start SDD when** your team adds an agent to a project with >20 tasks and realizes the agent spends half its tokens re-discovering context. That's the signal.

### Further Reading

- *[Spec-Driven Development: The Key To Scaling Autonomous AI Agents](https://time.news/spec-driven-development-the-key-to-scaling-autonomous-ai-agents/)* — Apr 14, 2026. The AWS Kiro case study.
- [Part 30 — The Ralph Loop In OpenClaw](./part30-ralph-loop-in-openclaw.md) — the autonomous-loop realization of SDD.
- [Part 31 — The LLM Wiki Pattern In OpenClaw](./part31-the-llm-wiki-pattern-in-openclaw.md) — the three-tier framing the spec plugs into.

---

## After Every Upgrade

- `openclaw doctor` — sanity check.
- `openclaw flows list` (and the Canvas Flows panel) — confirm Task Brain is recording.
- Memory smoke test: search for something you know is in memory. Confirm it comes back fast (<100ms local).
- Run one sub-agent spawn end-to-end. Confirm the approval categories behave the way your policy says they should.
- Check Canvas UI \u2192 Model Auth card. Tokens healthy, no rate-limit warnings.

If all five pass, you're done. If any fail, roll back and file a reproducer — don't fight a broken upgrade live on production agents.
