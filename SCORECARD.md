# The OpenClaw Production Readiness Scorecard

**Score your OpenClaw setup against the patterns in the [OpenClaw Optimization Guide](./README.md). 50 items across 5 pillars. 2 points each. 100 possible. Tested on OpenClaw 2026.4.15 stable.**

> Share your score: *"My OpenClaw Production Readiness Scorecard: XX / 100 — [github.com/OnlyTerp/openclaw-optimization-guide](https://github.com/OnlyTerp/openclaw-optimization-guide)"*

## How to use this

1. Fork / clone this repo or copy this file into your own setup.
2. Walk the 50 items. Check the ones you've genuinely done.
3. Add up your score: each checked box = 2 points, max 100.
4. Post the total. Tag us. Argue about which items matter most.

Every item links to the part of the guide that covers it. If you're about to check something and can't explain why it matters, go read the linked part.

---

## Pillar 1 — Speed (20 points)

Do your agents respond in seconds, not minutes? If every turn feels sluggish, context bloat is almost always the reason.

- [ ] `SOUL.md` is under 1 KB. *→ [Part 2](./README.md#part-2-context-engineering--the-discipline)*
- [ ] `AGENTS.md` is under 2 KB. *→ [Part 2](./README.md#part-2-context-engineering--the-discipline)*
- [ ] `MEMORY.md` is under 3 KB and is a pure index, not a content store. *→ [Part 4](./README.md#part-4-memory-stop-forgetting-everything)*
- [ ] `TOOLS.md` uses one-liners per tool, not full JSON schemas. *→ [Part 2](./README.md#part-2-context-engineering--the-discipline)*
- [ ] Total injected context per message is under 8 KB (verified by logging a turn). *→ [Part 1](./README.md#part-1-speed-stop-being-slow)*
- [ ] `contextPruning.mode: "cache-ttl"` with a 5-minute TTL. *→ [Part 2](./README.md#part-2-context-engineering--the-discipline)*
- [ ] Reasoning mode is OFF on the default model, ON only for orchestration. *→ [Part 6](./README.md#part-6-models-what-to-actually-use)*
- [ ] Compaction runs on a cheap non-reasoning model (e.g. Cerebras Qwen), not on Gemini Flash or an Opus/GPT key. *→ [Part 15](./part15-infrastructure-hardening.md)*
- [ ] Cron output is isolated (`memory/cron/` or suppressed) so bulk scheduled runs don't flood session memory. *→ [Part 3](./README.md#part-3-cron-session-bloat-the-hidden-killer)*
- [ ] For small local models (≤14B), `agents.defaults.experimental.localModelLean: true` is set. *→ [Part 6](./README.md#part-6-models-what-to-actually-use)*

## Pillar 2 — Memory (20 points)

Can your agent remember what it did yesterday, what you decided last week, and where the relevant code lives?

- [ ] Vault structure is claim-named (`what-a-b-testing-tells-you-about-activation.md`), not date-named (`2026-04-16-notes.md`). *→ [Part 9](./part9-vault-memory.md)*
- [ ] At least one MOC (Map of Contents) exists under `vault/01_thinking/`. *→ [Part 9](./part9-vault-memory.md)*
- [ ] `memory_search` is used (by rule, enforced in `AGENTS.md`) before the agent claims it doesn't remember. *→ [Part 4](./README.md#part-4-memory-stop-forgetting-everything)*
- [ ] Embeddings run locally on Ollama (e.g. `qwen3-embedding:0.6b`), not on a cloud provider. *→ [Part 10](./part10-state-of-the-art-embeddings.md)*
- [ ] Search latency on your live vault is under ~150ms on a warm cache. *→ [Part 4](./README.md#part-4-memory-stop-forgetting-everything), [Part 10](./part10-state-of-the-art-embeddings.md)*
- [ ] Memory-core built-in dreaming is enabled with a nightly schedule. *→ [Part 22](./README.md#part-22-built-in-dreaming)*
- [ ] Dream phase blocks live under `memory/dreaming/{phase}/` (`dreaming.storage.mode: "separate"`, the 2026.4.15 stable default). *→ [Part 22](./README.md#part-22-built-in-dreaming)*
- [ ] `DREAMS.md` has at least one real sweep entry from the last 7 days. *→ [Part 22](./README.md#part-22-built-in-dreaming)*
- [ ] Auto-capture hook is wired to extract claim-named notes from session transcripts. *→ [Part 11](./part11-auto-capture-hook.md)*
- [ ] LightRAG is enabled if your vault has ≥500 files. (Otherwise, credit this item.) *→ [Part 18](./part18-lightrag-graph-rag.md)*

## Pillar 3 — Orchestration (20 points)

Does the frontier model plan while cheap workers execute, or is your orchestrator doing everything itself?

- [ ] Orchestrator uses a frontier model (Opus / GPT-5 / Gemini Pro). *→ [Part 6](./README.md#part-6-models-what-to-actually-use)*
- [ ] Workers use cheaper/faster models (Sonnet / GPT-5-mini / Flash / Cerebras). *→ [Part 6](./README.md#part-6-models-what-to-actually-use)*
- [ ] `AGENTS.md` has an explicit "spawn sub-agent if …" rule. *→ [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)*
- [ ] Independent tasks are spawned in parallel, not serially. *→ [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)*
- [ ] You've used the **Coordinator Protocol** (Research → Synthesis → Implement → Verify) at least once on a real task. *→ [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)*
- [ ] Each worker's prompt is self-contained (no "based on the above / your findings / the plan"). *→ [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)*
- [ ] At least 2 fallback models are configured; you've verified failover works. *→ [Part 6](./README.md#part-6-models-what-to-actually-use)*
- [ ] Ralph-style implement→test→loop pattern is wired somewhere (or you've consciously decided it's overkill). *→ [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)*
- [ ] If you ship code: Repowise (or an equivalent structural index) feeds workers *instead of* re-reading files every spawn. *→ [Part 19](./part19-repowise-codebase-intelligence.md)*
- [ ] Memory Bridge (or equivalent) injects your vault into external coding agents (Codex / Claude Code / Cursor) before they start. *→ [Part 13](./part13-memory-bridge.md)*

## Pillar 4 — Security & Control Plane (20 points)

If a compromised skill ships tomorrow, how much of your system does it reach?

- [ ] Task Brain is live (`openclaw flows list` returns output). *→ [Part 24](./part24-task-brain-control-plane.md)*
- [ ] Approval policy uses **semantic categories** (`read-only.*`, `execution.*`, `write.*`, `control-plane.*`), not raw tool names. *→ [Part 24](./part24-task-brain-control-plane.md)*
- [ ] `control-plane.*` is set to `deny` for every non-admin agent. *→ [Part 24](./part24-task-brain-control-plane.md)*
- [ ] `write.fs.outside-workspace` is `deny` by default. *→ [Part 24](./part24-task-brain-control-plane.md)*
- [ ] `skills.autoUpdate` is **OFF**. *→ [Part 23](./part23-clawhub-skills-marketplace.md)*
- [ ] Every installed ClawHub skill is pinned to a commit or tag, not a branch. *→ [Part 23](./part23-clawhub-skills-marketplace.md)*
- [ ] You've read the source of every ClawHub skill you have installed. *→ [Part 23](./part23-clawhub-skills-marketplace.md)*
- [ ] Credentials live in environment variables or OS keychain, not in `openclaw.json`, `AGENTS.md`, or `memory/`. *→ [Part 15](./part15-infrastructure-hardening.md)*
- [ ] Approval UI shows redacted secrets (`sk-***`) — you upgraded to 2026.4.15+. *→ [Part 15](./part15-infrastructure-hardening.md)*
- [ ] Canvas **Model Auth status card** shows all providers green; you've tested auth hot-reload. *→ [Part 15](./part15-infrastructure-hardening.md)*

## Pillar 5 — Observability & Reliability (20 points)

When something breaks at 3am, can you answer "what ran, with what permissions, and why did it fail" in under 5 minutes?

- [ ] Every ACP call, cron job, and sub-agent spawn shows up in `openclaw flows list` (i.e. nothing runs outside Task Brain). *→ [Part 24](./part24-task-brain-control-plane.md)*
- [ ] Gateway startup script has stale-process cleanup so a zombie doesn't block port 18789. *→ [Part 15](./part15-infrastructure-hardening.md)*
- [ ] Compaction `reserveTokens` is capped to the model's context window (auto in 2026.4.15+; verify anyway). *→ [Part 15](./part15-infrastructure-hardening.md)*
- [ ] You run `openclaw doctor` after every upgrade and commit the output. *→ [Part 26](./part26-migration-guide.md)*
- [ ] LangFuse / OpenTelemetry / equivalent LLM tracing is enabled for at least one agent. *→ [Part 20](./part20-observability-and-services.md)*
- [ ] Auto-capture hook is running; you've confirmed it produces inbox notes. *→ [Part 11](./part11-auto-capture-hook.md)*
- [ ] Self-improving system is on: `.learnings/corrections.md`, `.learnings/ERRORS.md`, `.learnings/LEARNINGS.md` are being written to. *→ [Part 12](./part12-self-improving-system.md)*
- [ ] Real-time knowledge sync (file watcher → vector index) is running. *→ [Part 21](./part21-realtime-knowledge-sync.md)*
- [ ] You have a one-command rollback plan from your current version to the previous one. *→ [Part 26](./part26-migration-guide.md)*
- [ ] You've tested the rollback at least once on a disposable workspace. *→ [Part 26](./part26-migration-guide.md)*

---

## Scoring

Count your checked boxes and multiply by 2:

| Score | Band | What it means |
|---|---|---|
| **90–100** | **Production-grade** | You are running OpenClaw the way it wants to be run. Talk at a conference. |
| **70–89** | **Solid** | Real production deployment, one or two pillars still soft. Use the unchecked boxes as a backlog. |
| **50–69** | **Working but leaky** | Works day-to-day; one bad skill or one upgrade gone wrong is a bad weekend. |
| **30–49** | **Stock-plus** | You've done some of the basics; most of the wins in this guide are still on the table. |
| **0–29** | **Stock** | Fine for tinkering. Do **not** point it at anything production until you close the Security pillar. |

## Rules for honest scoring

- Don't check an item because you mean to do it — only because it's live right now.
- "Almost" is a zero. If your MEMORY.md is 3.4 KB, that pillar item is zero, not half.
- If an item doesn't apply (e.g. you don't ship code, so Repowise is irrelevant), grant yourself the 2 points — but **only once you've genuinely confirmed it doesn't apply**, not because it sounded complicated.
- Retake the scorecard after every OpenClaw upgrade. The items don't move, but the defaults do.

## Why these 50

This is not a vendor checklist. Every item is here because skipping it burned us at least once on a real deployment. The ranking — Speed, Memory, Orchestration, Security, Observability — roughly matches the order in which things start to hurt as you move from toy to production:

- **Speed** is the first thing users notice.
- **Memory** is the first thing *you* notice (the agent "forgets" a decision and you re-explain).
- **Orchestration** is where costs explode.
- **Security** is where you stop sleeping well.
- **Observability** is what lets you recover when one of the other four fails.

See [Part 25 — Architecture Overview](./part25-architecture-overview.md) for the 15-minute primer on why the pieces fit this way.

---

*Contributions and corrections welcome. Open an issue at [github.com/OnlyTerp/openclaw-optimization-guide](https://github.com/OnlyTerp/openclaw-optimization-guide) or see [CONTRIBUTING.md](./CONTRIBUTING.md).*
