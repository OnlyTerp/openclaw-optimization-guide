# Part 28: Glossary & Terminology

> **Read this if** you're tripping over an unfamiliar term anywhere in the guide, or you want a single-page map of every OpenClaw concept the rest of the parts assume you know.
> **Skip if** you already know the difference between memory-core, memory-lancedb, LightRAG, Task Brain, and ClawHub — and have opinions about each.

This is a single-page reference. Terms are alphabetical. Each entry includes the shortest-possible definition, the part where it's introduced or covered in depth, and (when relevant) the release it was added in.

---

## Anthropic's 5 multi-agent coordination patterns

Published by Anthropic on [April 10, 2026](https://claude.com/blog/multi-agent-coordination-patterns) as the official taxonomy for multi-agent systems: **generator-verifier**, **orchestrator-subagent**, **agent teams**, **hierarchical**, **network**. This guide's Part 5 is organized around these names now that they're the canonical terms. When the user says "sub-agents" they almost always mean orchestrator-subagent.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself).

## ACP — Agent Communication Protocol

A protocol for **one agent calling another as a tool** (and persisting the conversation across the call). Introduced in **v4.2 (March 28, 2026)** alongside thread-bound persistent sessions, sub-agent spawning, and the `session_status` tool. In 2026.3.31-beta.1+, ACP calls show up as flows in the Task Brain ledger.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself), [Part 25 — Architecture Overview](./part25-architecture-overview.md).

## Approval categories (semantic)

The 2026.3.31-beta.1+ replacement for name-based tool allowlisting. Tools register under a **category tree** — `read-only.*`, `execution.*`, `write.*`, `control-plane.*` — and your approval policy decides per-category whether to `allow`, `ask`, or `deny`. Collapses "name every tool" policy bloat and survives tools being renamed.

- **Covered in:** [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## AGENTS.md

The per-workspace file that holds **operational rules** for the agent: decision tree, tool routing, when to spawn sub-agents, memory-write rules, config-protection rules. Injected on every message. Target size: 2–10 KB.

- **Covered in:** [Part 2 — Context Engineering](./README.md#part-2-context-engineering--the-discipline), [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself).

## Auto-capture hook

A custom session-end hook that reads the conversation transcript and extracts **claim-named knowledge notes** into `vault/00_inbox/` via a cheap extraction model. Not the same as OpenClaw's built-in `session-memory` hook, which dumps raw transcripts.

- **Covered in:** [Part 11 — Auto-Capture Hook](./part11-auto-capture-hook.md).

## autoDream *(retired)*

The reverse-engineered Claude Code / memory-core memory-consolidation pattern that used to live in **Part 16** of this guide (now removed). It worked on pre-2026.4 installs via a hand-rolled AGENTS.md protocol and a `memory/.dream-state.json` file. **Replaced by built-in Dreaming** (see [Part 22](./README.md#part-22-built-in-dreaming)).

- **Retired in:** this release.
- **Replacement:** memory-core's built-in Dreaming (OpenClaw 2026.4+).

## Cloud sandbox delegation (Twill / Amika)

The architectural alternative to running OpenClaw on your own box: **delegate the whole agent session to a vendor's ephemeral cloud VM**. [Twill.ai](https://news.ycombinator.com/item?id=47720418) (YC S25, HN Apr 11, 2026) and [Amika](https://www.youtube.com/watch?v=OZzdBNBXxSU) (Apr 13, 2026) are the two that launched this week. Wins on zero-setup isolation; loses on data residency, customizability, and audit. OpenClaw's on-prem answer: Task Brain approvals + hooks + worktrees.

- **Covered in:** [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## Context Engineering

The discipline — named by Karpathy and picked up by Gartner in the week of April 10-17, 2026 — of **treating every token in the context window as a budgeted resource**. Includes pruning, progressive disclosure (keep big things out of the default prompt until activated), cache-friendly ordering, and explicit file-hierarchy tiers (SOUL/AGENTS/MEMORY/skills). Part 2 is this guide's practical treatment of the discipline.

- **Covered in:** [Part 2 — Context Engineering](./README.md#part-2-context-engineering--the-discipline), [Part 31 — The LLM Wiki Pattern](./part31-the-llm-wiki-pattern-in-openclaw.md).

## Canvas UI

The browser-based chat/task UI introduced in **v4.0**. Talks to the gateway daemon over WebSocket. In 2026.4.15 it gained the **Model Auth status card** (OAuth/token health plus rate-limit pressure, backed by the `models.authStatus` gateway method).

- **Covered in:** [Part 25 — Architecture Overview](./part25-architecture-overview.md), [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md).

## Claude Opus 4.7

Anthropic's new top-tier reasoning model. In **OpenClaw 2026.4.15 stable (Apr 16, 2026)** it became the default Anthropic selection: `opus` aliases, Claude CLI defaults, and bundled image understanding all resolve to Opus 4.7. Opus 4.6 is still supported; the difference is rounding-error for orchestration.

- **Covered in:** [Part 6 — Models](./README.md#part-6-models-what-to-actually-use).

## ClawHavoc

Koi Security's name for the **supply-chain attack against ClawHub** that ran through Feb–Mar 2026. Antiy CERT confirmed **at least 1,184 active malicious skills** (TrojanOpenClaw PolySkill family) on ClawHub on February 1, 2026; Trend Micro flagged 39 additional skills distributing Atomic Stealer to macOS users. Hardened against in Task Brain (fail-closed plugin installs, `--dangerously-force-unsafe-install` for overrides).

- **Covered in:** [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md).

## ClawHub

Official OpenClaw skills marketplace, launched with **v4.1 (March 15, 2026)**. 13K+ skills published in the first week. Also the primary attack surface for the ClawHavoc supply-chain incident.

- **Covered in:** [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md).

## Compaction

The process of summarizing older chat history when context gets close to the model's limit. Runs a secondary model (the **compaction model**). Pre-2026.4.15 it could infinite-loop on 16K-context local models; now the `reserveTokens` floor is capped to the model's context window.

- **Covered in:** [Part 2 — Context Engineering](./README.md#part-2-context-engineering--the-discipline), [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md).

## Coordinator protocol

The 4-phase pattern for complex multi-step work: **Research → Synthesis → Implement → Verify**. Research and verification are spawned as parallel sub-agents; synthesis is done by the main agent. Originally reverse-engineered from the Claude Code leak; now idiomatic for OpenClaw sub-agent orchestration.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself).

## CVE wave (Feb–Mar 2026)

The cluster of high-severity CVEs disclosed against OpenClaw in early 2026, including:

- `CVE-2026-25253` — one-click RCE
- `CVE-2026-25157` — command injection
- `CVE-2026-25158` — path traversal
- WebSocket shared-auth scope escalation — CVSS **9.9**

Nine CVEs in four days across mid-March. Task Brain and the 2026.3.31-beta.1 hardening wave were the structural response.

- **Covered in:** [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## `dreaming.storage.mode`

Memory-core config key that controls **where dreaming phase blocks get written**. `"inline"` appends `## Light Sleep` / `## REM Sleep` blocks into the daily memory file at `memory/YYYY-MM-DD.md`. `"separate"` writes them to `memory/dreaming/{phase}/YYYY-MM-DD.md` instead. The **default flipped from `inline` to `separate` in 2026.4.15 stable** so daily memory files stay readable and the ingestion scanner stops competing with hundreds of phase-block lines.

- **Covered in:** [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming), [Part 26 — Migration Guide](./part26-migration-guide.md).

## DREAMS.md

A canonical memory file (alongside MEMORY.md) that holds **Dream Diary** entries produced by built-in Dreaming: human-readable narratives of what the agent consolidated in each sweep.

- **Covered in:** [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming).

## Dreaming (built-in)

Memory-core's **native 3-phase memory consolidation** (Light → Deep → REM) introduced in OpenClaw 2026.4. Runs on a cron schedule, scores short-term entries with six weighted signals (frequency, relevance, query diversity, recency, consolidation, conceptual richness), and promotes durable entries to MEMORY.md. The supported replacement for the retired custom autoDream pattern.

- **Covered in:** [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming).

## Exit codes (hooks)

Hooks communicate with the OpenClaw runtime via POSIX exit codes. **`0` = allow / continue**, **`1` = error but continue** (logged, not blocking), **`2` = block** (the runtime surfaces this as a `StopFailure` and aborts the action). Mixing `1` and `2` up is the single most common hook bug — see Amit Kothari's writeup linked from [Part 29](./part29-hook-catalog.md).

- **Covered in:** [Part 29 — The Hook Catalog](./part29-hook-catalog.md).

## Embedding provider

The model that converts text into vectors for vector search. Options: local Ollama (Qwen3, bge-m3, nomic-embed-text), cloud (OpenAI `text-embedding-3-large`, Voyage), or **GitHub Copilot** (new in 2026.4.15). Picking the right one is usually more impactful than tuning the LLM.

- **Covered in:** [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything), [Part 10 — State-of-the-Art Embeddings](./part10-state-of-the-art-embeddings.md).

## Gateway daemon

The **single long-running process** every OpenClaw surface talks to. Holds the Task Brain ledger, auth tokens, approval policy, and the live model of everything that's running. Before v4.0 each surface had its own process; v4.0+ is one gateway, everything else is a client.

- **Covered in:** [Part 25 — Architecture Overview](./part25-architecture-overview.md), [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md).

## Git worktrees (for parallel agents)

`git worktree` lets a single repo have multiple checked-out working directories simultaneously, each on its own branch, sharing the `.git` object database. The Apr 2026 consensus pattern for running N OpenClaw agents in parallel without merge conflicts: **one worktree per agent, one OpenClaw process per worktree**, merge the winning branches back afterwards.

- **Covered in:** [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md).

## Harness Thesis

"**95% of agent capability comes from the harness, 5% from the model.**" Nine independent writers — Princeton NLP, Atlan, Trensee, heyuan110, The AI Corner, Towards AI, ivanmagda.dev, a Korean YouTube explainer (14.9K views), and a viral Medium essay — converged on this in the week of April 10-17, 2026. The harness is instructions + context engineering + tools/approvals + guardrails + memory + orchestration. Same weights, different harness, different benchmarks. OpenClaw *is* a harness; this guide is the operator's manual for one.

- **Covered in:** [README intro](./README.md), [Part 25 — Architecture Overview](./part25-architecture-overview.md).

## Hooks

Lifecycle callbacks OpenClaw fires at well-defined points — session-start, session-end, pre-tool-use, post-tool-use, pre-edit, post-edit, compact, stop, user-prompt-submit, and others (18 documented events across 4 types as of April 2026). Hooks are the **deterministic enforcement layer** — the only way to guarantee behavior an agent cannot talk its way out of. The 8 copy-paste hooks in [Part 29](./part29-hook-catalog.md) cover the common safety, cost, secret, and audit patterns.

- **Covered in:** [Part 11 — Auto-Capture Hook](./part11-auto-capture-hook.md), [Part 21 — Realtime Knowledge Sync](./part21-realtime-knowledge-sync.md), [Part 29 — The Hook Catalog](./part29-hook-catalog.md).

## LightMem

A three-tier **STM / MTM / LTM memory** system published in [arXiv:2604.07798](https://arxiv.org/abs/2604.07798) in April 2026. Design win: memory operations (consolidation, retrieval) run on a **small, fast model** while the main agent keeps running a frontier model. Reports 83ms retrieval, +2.5 F1 over baselines on LoCoMo. Cite it whenever someone runs memory ops on Opus — they're setting money on fire.

- **Covered in:** [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming).

## LightRAG

Graph-RAG layer that turns your vault into a **knowledge graph of entities + relationships**. Dramatically better retrieval than plain vector search once you pass ~500 files. Has a Web UI + REST API + LangFuse tracing.

- **Covered in:** [Part 18 — LightRAG](./part18-lightrag-graph-rag.md), [Part 21 — Real-Time Knowledge Sync](./part21-realtime-knowledge-sync.md).

## localModelLean

Flag at `agents.defaults.experimental.localModelLean: true` (added in **2026.4.15**) that drops heavyweight default tools (browser, cron, message) from weaker local models. Lets small quantized models actually function instead of burning tokens parsing tool definitions they'll never use.

- **Covered in:** [Part 1 — Speed](./README.md#part-1-speed-stop-being-slow), [Part 6 — Models](./README.md#part-6-models-what-to-actually-use).

## LLM Wiki pattern

Karpathy's Apr 10, 2026 [YouTube talk (4.3K views)](https://www.youtube.com/watch?v=K47qWvM8os0) crystallized a three-tier file hierarchy for production agents: **raw sources (immutable)** → **curated summaries (model-maintained, size-capped)** → **generated artifacts (one-shot)**. OpenClaw's SOUL/AGENTS/MEMORY/DREAMS/skills hierarchy maps 1:1 onto Karpathy's tiers.

- **Covered in:** [Part 31 — The LLM Wiki Pattern In OpenClaw](./part31-the-llm-wiki-pattern-in-openclaw.md).

## Mem²Evolve

[arXiv preprint (Apr 14, 2026)](https://arxiv.org/html/2604.10923v1) that co-evolves an agent's **memory *and* skill populations** together, reporting +18.53% over a skill-only evolution baseline on a mixed agent-task benchmark. Research direction rather than shipping code; [SkillClaw](https://github.com/AMAP-ML/SkillClaw)'s roadmap cites it as the next integration target.

- **Covered in:** [Part 32 — Self-Evolving Skills With SkillClaw](./part32-self-evolving-skills-with-skillclaw.md).

## Memory Bridge

A pair of scripts (`preflight-context.js`, `memory-query.js`) that inject your vault into external coding agents (Codex, Claude Code) before they start, so they don't code blind. Lives at [onlyterp/memory-bridge](https://github.com/OnlyTerp/memory-bridge).

- **Covered in:** [Part 13 — Memory Bridge](./part13-memory-bridge.md).

## memory-core

The first-party plugin that owns MEMORY.md and DREAMS.md, runs built-in Dreaming, and exposes `memory_get` / `memory_search` tools. As of **2026.4.15**, `memory_get` is restricted to canonical memory files only (path-traversal hardening from the `memory-qmd` fix).

- **Covered in:** [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything), [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming).

## memory-lancedb

The vector-search plugin backing `memory_search`. **2026.4.15** added **cloud storage** (S3-compatible), so durable memory indexes can live on remote object storage instead of only on local disk.

- **Covered in:** [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything), [Part 10 — State-of-the-Art Embeddings](./part10-state-of-the-art-embeddings.md).

## Model Auth status card

New Canvas UI component in **2026.4.15** that shows OAuth/token health and rate-limit pressure for each configured model provider. Backed by the `models.authStatus` gateway method. Refreshing it is the gateway auth hot-reload path.

- **Covered in:** [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md), [Part 25 — Architecture Overview](./part25-architecture-overview.md).

## MOC — Map of Contents

A vault file (usually per-domain) that links out to claim-named notes, acting as a curated index. Prevents vector search from drowning in similar-looking files.

- **Covered in:** [Part 9 — Vault Memory System](./part9-vault-memory.md).

## `memory_get` excerpt cap (default)

As of **2026.4.15 stable**, `memory_get` no longer returns whole files by default. Excerpts are capped and the tool response includes **explicit continuation metadata** (a cursor the agent uses to fetch the next chunk deterministically). Combined with trimmed startup/skills prompt budgets, this keeps long sessions from silently ballooning. Skills that assumed full-file reads need a small cursor loop after the upgrade.

- **Covered in:** [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything), [Part 26 — Migration Guide](./part26-migration-guide.md#path-5-v20264-15-beta-1-v20264-15-stable), [Part 27 — Gotchas & FAQ](./part27-gotchas-and-faq.md).

## Orchestrator / sub-agent / worker

Pattern where the **main agent** (orchestrator) spawns **sub-agents** (workers) via `sessions_spawn` for narrow, cheaper, parallelizable tasks. In Task Brain, every spawn is a flow with its own approval scope.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself), [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## PRD.json

The **persistent spec** a Ralph Loop reads and writes every iteration. Contains tasks, their statuses, acceptance criteria, budget (max iterations / max USD / max wall hours), learnings, and last-iteration trace. The agent's reasoning anchor across fresh sessions. See also [Spec-Driven Development](./part26-migration-guide.md#pair-openclaw-with-a-machine-readable-spec-spec-driven-development).

- **Covered in:** [Part 30 — The Ralph Loop In OpenClaw](./part30-ralph-loop-in-openclaw.md).

## Progressive disclosure

The context-engineering principle of **keeping big context out of the default prompt until a condition activates it** (a skill fires, a file is opened, a sub-agent spawns). Opposing anti-pattern: stuffing everything into CLAUDE.md / AGENTS.md and blowing the budget on every message. Five independent April 2026 writeups ([MindStudio Apr 15](https://www.mindstudio.ai/blog/progressive-disclosure-ai-agents-context-management/), among others) named this as the single biggest lever for long-session cost.

- **Covered in:** [Part 2 — Context Engineering](./README.md#part-2-context-engineering--the-discipline), [Part 31 — The LLM Wiki Pattern](./part31-the-llm-wiki-pattern-in-openclaw.md).

## Prompt cache TTL (5-minute trap)

Anthropic's prompt-cache default TTL silently dropped from **1 hour to 5 minutes** in March 2026. Most operators missed the release note; bills quietly went up 2-4× for cache-heavy workloads because cache hits stopped materializing. Fix: pass an explicit `ttl` when writing cache checkpoints, or accept the new default and rebuild cache affinity.

- **Covered in:** [Part 2 — Context Engineering](./README.md#part-2-context-engineering--the-discipline).

## Ralph loop

An autonomous orchestration pattern: a `while` loop that reads a **persistent spec (PRD.json)**, invokes the agent with a fresh session each iteration, appends learnings, and exits on budget / iteration / stall conditions. Reference implementation: [frankbria/ralph-claude-code (8.7K stars)](https://github.com/frankbria/ralph-claude-code). OpenClaw-specific port: [DEV Apr 13, 2026](https://dev.to/satoru_906c2ffeaf64bd2ac1/stop-babysitting-your-ai-agent-use-ralph-loops-openclaw-fdi). Named after the [ghuntley.com/loop](https://ghuntley.com/loop) essay.

- **Covered in:** [Part 30 — The Ralph Loop In OpenClaw](./part30-ralph-loop-in-openclaw.md).

## Repowise

Codebase-intelligence service that pre-builds a structural index of a repo so coding agents don't burn tokens re-reading the same files every spawn. ~60% fewer tokens, ~4x faster coding workflows in our measurements.

- **Covered in:** [Part 19 — Repowise](./part19-repowise-codebase-intelligence.md).

## SDD — Spec-Driven Development

Framing popularized by a *[Time Apr 14, 2026](https://time.news/spec-driven-development-the-key-to-scaling-autonomous-ai-agents/)* piece: **a machine-readable spec (`SPEC.md` or `PRD.json`) is the agent's single source of truth**. Agent reads it, picks the next task, does the work, updates the spec, commits. AWS Kiro case study: 18 months → 76 days. Natural partner to the Ralph Loop.

- **Covered in:** [Part 26 — Migration Guide](./part26-migration-guide.md#pair-openclaw-with-a-machine-readable-spec-spec-driven-development), [Part 30 — The Ralph Loop In OpenClaw](./part30-ralph-loop-in-openclaw.md).

## Session memory files

Per-session raw transcripts and agent notes written under `memory/`. They pile up fast (200+ in a month) and are supposed to be consolidated into MEMORY.md by built-in Dreaming, then pruned by temporal decay.

- **Covered in:** [Part 3 — Cron Session Bloat](./README.md#part-3-cron-session-bloat-the-hidden-killer), [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming).

## `sessions_spawn`

The OpenClaw tool that creates a sub-agent. In Task Brain it produces a child flow with a parent-record link back to the originating conversation, plus its own approval-category scope.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself), [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## Skill

A packaged capability (tools + prompt + optional hooks) installable from ClawHub or locally. In 2026.3.31-beta.1+, skill installs are **fail-closed** if the built-in security scan flags dangerous code; overriding requires the deliberately awkward `--dangerously-force-unsafe-install` flag.

- **Covered in:** [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md).

## SkillClaw

[AMAP-ML/SkillClaw (created April 10, 2026)](https://github.com/AMAP-ML/SkillClaw) — population-level skill evolution framework. Scores skills on outcome, efficiency, and recency; mutates prompts / parameters / order-of-checks; retires weak skills; promotes strong ones. **Lists OpenClaw as a first-class harness.** 687 stars in week one. See also Mem²Evolve for the co-evolution direction.

- **Covered in:** [Part 32 — Self-Evolving Skills With SkillClaw](./part32-self-evolving-skills-with-skillclaw.md).

## StopFailure

The runtime error OpenClaw raises when a hook exits with code `2`. Unlike a normal tool error, a StopFailure is **non-recoverable from the agent's side** — it aborts the in-progress action and surfaces the hook's stdout/stderr to the user. The deliberate design: hooks are the layer the agent cannot talk its way out of. The common footgun (Amit Kothari's writeup): using exit code 1 when you meant 2, so the hook "fails" but the unsafe action still runs.

- **Covered in:** [Part 29 — The Hook Catalog](./part29-hook-catalog.md).

## Sub-agents as context garbage collection

2026 reframing: the primary value of sub-agents is **disposable context**, not parallelism. A sub-agent runs, produces a small structured result, and its entire conversation — tool calls, intermediate thoughts, long file reads — is thrown away. The main agent never paid for any of it. The Apr 2026 decision table: spawn a sub-agent when **(a) the scope is wide**, **(b) ≥10 edit targets**, or **(c) independent verification is wanted**.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself).

## SOUL.md

The per-workspace personality / tone / core-rules file. Injected on every message. Target size: **< 1 KB** — every byte costs latency.

- **Covered in:** [Part 2 — Context Engineering](./README.md#part-2-context-engineering--the-discipline), [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything).

## Task Brain

OpenClaw's **control plane**, introduced in **v2026.3.31-beta.1**. Unifies ACP calls, cron jobs, sub-agent spawns, and background CLI jobs into a **SQLite-backed task flow registry** with one lifecycle, heartbeat monitoring + automatic recovery, parent-task tracking, blocked-state persistence, and semantic approval categories. Exposed via `openclaw flows list | show | cancel` and the Canvas Flows panel.

- **Covered in:** [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## Task flow registry

Official name (from the 2026.3.31-beta.1 release notes) for the Task Brain ledger. Older internal design docs called this the "task ledger" or "tasks"; the published CLI verb is `openclaw flows`.

- **Covered in:** [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## Tool-name normalize-collision rejection

Gateway-level defense added in **2026.4.15 stable**: a client tool definition whose name normalizes to match a **built-in** (e.g. `Browser`, `Exec`, or `exec` with trailing whitespace) — or that collides with another client tool in the same request — is rejected with `400 invalid_request_error` on both JSON and SSE paths. Closes a local-media (`MEDIA:`) trust-inheritance vector where a malicious or compromised skill could register a tool that inherited a built-in's trust by name alone.

- **Covered in:** [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md), [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md).

## Vault

A structured `vault/` directory layout — folders for `00_inbox/`, topic MOCs, claim-named notes, wiki-links — that makes vector search and LightRAG actually useful. Not a separate storage backend; it's the filesystem structure everything else indexes over.

- **Covered in:** [Part 9 — Vault Memory System](./part9-vault-memory.md).

---

## See Also

- [Part 25 — Architecture Overview](./part25-architecture-overview.md) — how the moving parts fit together.
- [Part 26 — Migration Guide](./part26-migration-guide.md) — when each of these terms became the right answer.
- [Part 27 — Gotchas & FAQ](./part27-gotchas-and-faq.md) — what each of these breaks like when misconfigured.
