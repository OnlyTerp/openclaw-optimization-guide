# Part 26: Migration Guide

> Updated in the June 2026 refresh. Opinionated, battle-tested upgrade paths from older OpenClaw versions to current. If something in this guide does not apply to your version yet, start here.

> **Read this if** you're on anything older than 2026.6.4, or planning an upgrade.
> **Skip if** you're already on current-beta and don't maintain older instances.

## TL;DR By Version

| You're on | Do this first | Then | Finally |
|-----------|--------------|------|---------|
| **v3.x** | Full v4.0 upgrade (not a drop-in) | Reach 2026.4.27 through Paths 1–6 | 2026.6.4 |
| **v4.0.x** | v2026.3.31-beta.1 (Task Brain) | Reach 2026.4.27 through Paths 2–6 | 2026.6.4 |
| **v2026.3.x** | Apply Task Brain approval policy | Reach 2026.4.27 through Paths 3–6 | 2026.6.4 |
| **v2026.4.x pre-4.15** | Skip straight to 2026.4.15 | Reach 2026.4.27 through Paths 5–6 | 2026.6.4 |
| **v2026.4.15** | Remove subscription-era model assumptions | Apply provider-catalog changes | 2026.6.4 |
| **v2026.4.27** | Apply memory/messaging beta changes | Upgrade to 2026.6.4 | Optional 2026.6.11-beta.1 |
| **v2026.4.29-beta.1** | Migrate Codex/queue assumptions | Upgrade to 2026.6.4 | Optional 2026.6.11-beta.1 |
| **v2026.5.22 / 2026.5.24-beta.1** | Apply June budget/policy/health changes | Upgrade to 2026.6.4 via Path 12 | Optional 2026.6.11-beta.1 |

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
2. Run `openclaw tasks list`. If it works: Task Brain is live. If your older binary only exposes `openclaw flows list`, treat it as the same ledger and plan to update runbooks after upgrading.
3. Write a semantic approval policy (see [Part 24](./part24-task-brain-control-plane.md)). Don't leave it on defaults for more than a day — you want the policy to match your actual usage or you'll drown in approval prompts.
4. Review `openclaw tasks list` / `openclaw tasks flow list` and the Control UI task/flow panels at least once in the first week. You'll spot jobs you forgot existed (old cron, orphaned sub-agent spawns, stuck ACP calls).

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

## Path 4: Anything v2026.4.x → v2026.4.15

Small jump. This is the version the guide is currently tested on.

**What changes (the ones you should act on immediately):**
- Compaction reserve-token floor is now capped at the model context window (fixes infinite loops on small local compaction workers).
- Gateway supports hot-reload of auth secrets without a full restart (reuses the `models.authStatus` refresh path from 2026.4.15). The CLI verb for manual reload has moved between betas — check `openclaw --help` on your installed version for the exact spelling.
- Approval prompts redact secrets before showing them to approvers. Previously every approval was a credential leak.
- `memory_get` restricted to MEMORY.md + DREAMS.md only (path-traversal hardening against the qmd backend).
- Memory-lancedb can persist to S3-compatible cloud storage.
- GitHub Copilot embedding provider.
- `agents.defaults.experimental.localModelLean: true` drops heavyweight default tools for weak local models; 2026.5.20 also supports per-agent `agents.list[].experimental.localModelLean`.
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

## Path 6: v2026.4.15 → v2026.4.27 stable

This is the first late-April stability jump. It is worth doing before moving to May because it introduces the provider/catalog/browser changes the later releases assume.

**What changes (the ones you should act on immediately):**

- Claude subscription-backed guidance is stale after Anthropic's April 4 cutoff. Move to explicit provider/API routes and budget caps.
- Kimi K2.6 becomes the bundled Moonshot default; K2.5 remains available for compatibility.
- Session-store pruning runs by default, reducing cron/executor backlog OOM risk.
- `/models add` is deprecated after the provider-catalog work. Use `/models` and `openclaw models list` for inspection; do durable config changes deliberately.
- DeepSeek V4 Flash/Pro enter the bundled catalog, with V4 Flash as an onboarding default.
- Browser automation gets coordinate clicks, 60s default action budgets, and per-profile headless overrides.
- DeepInfra joins the bundled provider set.
- Codex Computer Use gets `status` / `install` commands and fail-closed MCP checks.
- Plugin/model catalogs move toward manifest-first metadata.
- Docker sandbox GPU passthrough and outbound proxy routing are available as explicit opt-ins.

**Steps:**

1. Upgrade to 2026.4.27. Restart gateway. Run `openclaw doctor`.
2. Remove Claude Pro/Max membership assumptions from your runbooks. Add budget caps to paid providers.
3. Replace Kimi K2.5 default references with Kimi K2.6 where your provider catalog exposes it.
4. Delete any `/models add` automation. Inspect with `/models`, then edit config/catalogs deliberately.
5. If you use browser automation, update flaky selector-based skills to prefer coordinate clicks only where selectors are unreliable.
6. If you use Codex desktop control, run `openclaw codex computer-use status` and install/fix missing MCP pieces before a real task.
7. Audit plugin manifests before runtime code when installing/updating providers.

## Path 7: v2026.4.27 stable → v2026.4.29-beta.1

Former beta jump. If you're upgrading today, treat this as the conceptual migration step for memory/messaging behavior, then continue through Path 8, Path 10, and Path 12 to the current 2026.6.4 stable baseline.

**What changes (the ones you should act on immediately):**

- Active Memory can be scoped with per-conversation `allowedChatIds` / `deniedChatIds`.
- Partial recall summaries are returned when the hidden memory sub-agent times out.
- People wiki metadata adds aliases, person cards, relationship graphs, provenance reports, evidence drilldowns, and raw-claim search modes.
- `messages.visibleReplies` can force visible channel output through the message tool.
- Active-run queueing defaults toward steering at the next model boundary.
- Sub-agent event payloads include `spawnedBy` routing metadata.
- NVIDIA provider and Bedrock Opus 4.7 thinking parity arrive.
- OpenGrep scanning and sharper GHSA triage policy land.

**Steps:**

1. Test on a copy of your profile. Back up memory and config first.
2. Enable Active Memory only for specific chat IDs. Deny broad/public channels by default.
3. Turn on visible-reply enforcement for group/channel surfaces.
4. Ask the agent for provenance when it makes claims about people.
5. Use `doctor.memory.remHarness` to preview REM output before trusting a new memory policy.
6. Roll back to 2026.4.27 if memory recall or channel routing behaves unexpectedly.

## Path 8: v2026.4.29-beta.1 → v2026.5.12 stable

This is the former May stable baseline. Do this as the compatibility checkpoint, then continue through Path 10 and Path 12 to the current 2026.6.4 stable baseline (test 2026.5.24-beta.1 only if you need a specific feature before it lands stable).

**What changes (the ones you should act on immediately):**

- Provider/channel dependency cones are leaner. WhatsApp, Slack, Amazon Bedrock, Anthropic Vertex, OpenShell sandbox, and related runtime dependencies may need explicit plugin/provider installs instead of assuming core bundled them.
- Telegram is much more resilient: isolated polling, durable local spooling, safer group-media handling, and preserved HTML/Markdown formatting.
- Codex/OpenAI paths are smoother: auth-profile-backed media tools, MCP server projection, context-engine thread rotation, and app-server/runtime fallback fixes.
- Plugin installs/updates are harder to wedge: pnpm 11 support, peer-dependency preservation, safer runtime scans, and source/git install fixes.
- Gateway, browser, Slack, node pairing, sandbox, and transcript paths got security/provenance hardening.
- ACP can use `acp.fallbacks` to try backup runtime backends.

**Steps:**

1. Upgrade to 2026.5.12. Restart gateway. Run `openclaw doctor`.
2. List enabled provider/channel plugins and reinstall any externalized dependency you actually use.
3. If you use Codex, run `openclaw codex computer-use status`, then one small Codex app-server task before a real batch.
4. Replace any durable `openai-codex/*` or `codex-cli/*` model references with canonical `openai/gpt-*` routes, such as `openai/gpt-5.5`, that your installed Codex provider exposes.
5. If you use ACP, add `acp.fallbacks` for the runtime backends you trust rather than letting one backend outage kill the workflow.
6. Re-test Telegram/Slack/WebChat delivery on a disposable session, especially if your workflows depend on media or rich formatting.

## Path 9: v2026.5.12 stable → v2026.5.14-beta.1

Former beta jump. Today, treat this as the queue/Codex/per-sender migration checkpoint, then continue through Path 10 and Path 12 for the current stable baseline.

**What changes (the ones you should act on immediately):**

- `messages.queue.mode` defaults to `steer`, so active-run follow-ups are injected at the next model boundary.
- `/queue steer`, `/queue followup`, `/queue collect`, and `/queue interrupt` are the operator-visible queue modes.
- `agents.defaults.runRetries` and `agents.list[].runRetries` bound embedded Pi runner retry loops.
- Telnyx realtime media-streaming calls land for conversational voice workflows.
- Bundled `codex-cli` backend is removed; legacy `codex-cli/*` refs repair toward the native Codex app-server route on `openai/gpt-*`.
- WhatsApp status reactions can show coarse progress categories.
- `tools.toolsBySender` restricts tool access by channel/user identity.
- Sub-agent sessions appear nested under parent sessions in Control UI.

**Steps:**

1. Set `messages.queue.mode` deliberately. Keep `steer` for live correction; choose `followup` or `collect` where order matters more than mid-turn steering.
2. Add `tools.toolsBySender` deny rules for guest/public-channel senders before exposing write/runtime tools to channel users.
3. Add `agents.defaults.runRetries` for embedded/remote Pi runners that can fail transiently.
4. If you had `codex-cli/*` refs, replace them with canonical `openai/gpt-*` model refs and verify with a tiny Codex task.
5. If you try Telnyx voice, do it on a test number first and keep transcript/media retention explicit.
6. Roll back to 2026.5.12 if steering semantics or channel progress reactions surprise users, then continue through Path 10 when ready.


## Path 10: v2026.5.14-beta.1 / v2026.5.12 → v2026.5.22 stable

Former stable baseline. It rolls up the 2026.5.16, 2026.5.18, 2026.5.20, and 2026.5.22 trains. After this, continue to Path 12 for the current 2026.6.4 baseline.

**What changes (the ones you should act on immediately):**

- Minimum Node.js 22 line is now **22.19**. Upgrade Node before blaming OpenClaw startup.
- The old skill exec allowlist compatibility path is gone. Skill files must be loaded with the read tool; only the real executable is auto-allowed.
- Sub-agent default bootstrap narrows to `AGENTS.md` and `TOOLS.md`; persona, identity, user, memory, heartbeat, and setup files are not delegated by default.
- The bundled Policy plugin adds `openclaw policy check`, channel conformance attestations, doctor lint findings, and opt-in repair.
- `agents.list[].experimental.localModelLean` lets one small/local worker run lean without forcing every agent into lean mode.
- `OPENCLAW_IMAGE_APT_PACKAGES` replaces `OPENCLAW_DOCKER_APT_PACKAGES` as the runtime-neutral Docker/Podman image build arg.
- Meeting Notes is a source-only external plugin with Discord voice as the first live source and `openclaw meeting-notes` CLI access.
- xAI device-code OAuth works on remote/headless hosts; OpenRouter honors provider-level `params.provider` routing.
- Gateway/plugin/model/channel metadata hot paths are cached aggressively. Startup is faster, but unused plugins are still attack surface.
- Generic `contracts.embeddingProviders` and `api.registerEmbeddingProvider(...)` make embeddings a plugin capability.

**Steps:**

1. Upgrade Node to 22.19+ and then install OpenClaw 2026.5.22.
2. Run `openclaw doctor`, `openclaw policy check`, and `openclaw tasks maintenance --json` before inviting channel users back.
3. Audit every skill that relied on shelling through `cat SKILL.md && printf ...`; convert it to read the skill file explicitly.
4. Review sub-agent prompts. If a worker needed SOUL/USER/MEMORY context, pass the needed summary explicitly instead of assuming inherited bootstrap.
5. Move Docker/Podman custom package builds to `OPENCLAW_IMAGE_APT_PACKAGES`; keep the old var only for pinned legacy images.
6. Add per-agent `experimental.localModelLean` only to small local workers; leave frontier orchestrators full-context.
7. If you enable Meeting Notes, define meeting retention/redaction first and start with a single Discord voice source.
8. If you use OpenRouter/xAI, re-check auth/routing with a tiny run before production traffic.

## Path 11: v2026.5.22 stable → v2026.5.24-beta.1

Beta jump. Use a copied profile unless you specifically need iMessage approval reactions, realtime voice run steering, adaptive image compression, or named Codex OAuth profiles.

**What changes:**

- `agents.defaults.imageQuality` controls adaptive image compression: `token-efficient`, `balanced`, or `high-detail`.
- WebUI and Discord voice callers can ask status, cancel, steer, or queue follow-up work during active consults.
- Discord voice adds wake-name gating with agent-name defaults.
- iMessage thumbs mirror WhatsApp-style approvals: thumbs-up for `allow-once`, thumbs-down for deny.
- Named Codex OAuth profile storage makes multi-auth OpenAI/Codex hosts less brittle.

**Steps:**

1. Set `agents.defaults.imageQuality` deliberately; use `balanced` until you know a worker needs high-detail images.
2. Test a voice consult's status/cancel/steer path before exposing it to normal users.
3. Confirm iMessage/WhatsApp approval reactions are limited to trusted approvers, not every group participant.
4. If you use multiple OpenAI/Codex auth lanes, migrate to named profiles and run one tiny Codex task per profile.
5. Roll back to 2026.5.22 if voice steering or approval reactions surprise users.

## Path 12: v2026.5.22 / v2026.5.24-beta.1 → v2026.6.4 stable

This is the current stable baseline for this guide. It promotes the 5.24 beta line (in 2026.5.26) and adds the June cost/safety levers.

**What changes (act on these immediately):**

- Per-agent budgets are first-class: `agents.list[].budget` with `dailyUsd`/`monthlyUsd` and `onExceed: warn|degrade|stop`.
- `openclaw policy check --export attestation.json` produces diffable attestations; drift against the last accepted attestation is now a reviewable change.
- `models.providers.<id>.health` adds interval probes with bounded automatic lane demotion (`failureThreshold`, `demoteForMs`).
- Meeting Notes gains Google Meet live capture plus `meetingNotes.retentionDays` and redaction rules.
- `memory promote --dry-run` lets you preview what dreaming would promote into `MEMORY.md` before it mutates anything. (`memory.recall.maxParallel` and additional dreaming schedule controls are 2026.6.11-beta.1, not 2026.6.4 stable — see step 7.)
- `openclaw doctor` adds secret-rotation reminders (`secrets.rotation.maxAgeDays`) and flags unscoped `mcp.servers.<id>.codex.agents`.

**Steps:**

1. Install OpenClaw 2026.6.4 and run `openclaw doctor` + `openclaw policy check`.
2. Add a `budget` cap to your orchestrator with `onExceed: degrade`; confirm you have at least two fallback lanes for it to degrade onto.
3. Add `health` checks to your primary provider and verify a forced failure demotes the lane instead of failing turns.
4. Schedule `openclaw policy check --export` (cron or CI) and store the first attestation as your baseline. Keep `--fix` manual.
5. If you use Meeting Notes, set `retentionDays` and redaction rules before enabling the Google Meet source.
6. Resolve any new doctor findings for plaintext/stale secrets and unscoped Codex MCP servers.
7. Optionally test 2026.6.11-beta.1 on a copied profile for `/context map --diff`, `memory.recall.maxParallel`, dreaming schedule controls, sandbox egress allowlists, and per-channel image-quality overrides.

## Rollback Plan (Every Path)

If something goes sideways:

```bash
# Stop the gateway
openclaw gateway stop

# Install previous version (example: pin via your package manager)
npm install -g openclaw@2026.6.4  # adjust for your install method / previous pin

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
- `openclaw tasks list` / `openclaw tasks flow list` (and the Control UI task/flow panels) — confirm Task Brain is recording.
- Memory smoke test: search for something you know is in memory. Confirm it comes back fast (<100ms local).
- Run one sub-agent spawn end-to-end. Confirm the approval categories behave the way your policy says they should.
- Check Canvas UI \u2192 Model Auth card. Tokens healthy, no rate-limit warnings.

If all five pass, you're done. If any fail, roll back and file a reproducer — don't fight a broken upgrade live on production agents.
