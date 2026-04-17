# Part 28: Glossary & Terminology

> **Read this if** you're tripping over an unfamiliar term anywhere in the guide, or you want a single-page map of every OpenClaw concept the rest of the parts assume you know.
> **Skip if** you already know the difference between memory-core, memory-lancedb, LightRAG, Task Brain, and ClawHub — and have opinions about each.

This is a single-page reference. Terms are alphabetical. Each entry includes the shortest-possible definition, the part where it's introduced or covered in depth, and (when relevant) the release it was added in.

---

## ACP — Agent Communication Protocol

A protocol for **one agent calling another as a tool** (and persisting the conversation across the call). Introduced in **v4.2 (March 28, 2026)** alongside thread-bound persistent sessions, sub-agent spawning, and the `session_status` tool. In 2026.3.31-beta.1+, ACP calls show up as flows in the Task Brain ledger.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself), [Part 25 — Architecture Overview](./part25-architecture-overview.md).

## Approval categories (semantic)

The 2026.3.31-beta.1+ replacement for name-based tool allowlisting. Tools register under a **category tree** — `read-only.*`, `execution.*`, `write.*`, `control-plane.*` — and your approval policy decides per-category whether to `allow`, `ask`, or `deny`. Collapses "name every tool" policy bloat and survives tools being renamed.

- **Covered in:** [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## AGENTS.md

The per-workspace file that holds **operational rules** for the agent: decision tree, tool routing, when to spawn sub-agents, memory-write rules, config-protection rules. Injected on every message. Target size: 2–10 KB.

- **Covered in:** [Part 2 — Context Bloat](./README.md#part-2-context-bloat-the-silent-performance-killer), [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself).

## Auto-capture hook

A custom session-end hook that reads the conversation transcript and extracts **claim-named knowledge notes** into `vault/00_inbox/` via a cheap extraction model. Not the same as OpenClaw's built-in `session-memory` hook, which dumps raw transcripts.

- **Covered in:** [Part 11 — Auto-Capture Hook](./part11-auto-capture-hook.md).

## autoDream *(retired)*

The reverse-engineered Claude Code / memory-core memory-consolidation pattern that used to live in **Part 16** of this guide (now removed). It worked on pre-2026.4 installs via a hand-rolled AGENTS.md protocol and a `memory/.dream-state.json` file. **Replaced by built-in Dreaming** (see [Part 22](./README.md#part-22-built-in-dreaming)).

- **Retired in:** this release.
- **Replacement:** memory-core's built-in Dreaming (OpenClaw 2026.4+).

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

- **Covered in:** [Part 2 — Context Bloat](./README.md#part-2-context-bloat-the-silent-performance-killer), [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md).

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

## Embedding provider

The model that converts text into vectors for vector search. Options: local Ollama (Qwen3, bge-m3, nomic-embed-text), cloud (OpenAI `text-embedding-3-large`, Voyage), or **GitHub Copilot** (new in 2026.4.15). Picking the right one is usually more impactful than tuning the LLM.

- **Covered in:** [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything), [Part 10 — State-of-the-Art Embeddings](./part10-state-of-the-art-embeddings.md).

## Gateway daemon

The **single long-running process** every OpenClaw surface talks to. Holds the Task Brain ledger, auth tokens, approval policy, and the live model of everything that's running. Before v4.0 each surface had its own process; v4.0+ is one gateway, everything else is a client.

- **Covered in:** [Part 25 — Architecture Overview](./part25-architecture-overview.md), [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md).

## Hooks

Lifecycle callbacks OpenClaw fires at well-defined points (session-start, session-end, file-change, etc.). Most-useful for this guide: the auto-capture hook ([Part 11](./part11-auto-capture-hook.md)) and the file watcher ([Part 21](./part21-realtime-knowledge-sync.md)).

## LightRAG

Graph-RAG layer that turns your vault into a **knowledge graph of entities + relationships**. Dramatically better retrieval than plain vector search once you pass ~500 files. Has a Web UI + REST API + LangFuse tracing.

- **Covered in:** [Part 18 — LightRAG](./part18-lightrag-graph-rag.md), [Part 21 — Real-Time Knowledge Sync](./part21-realtime-knowledge-sync.md).

## localModelLean

Flag at `agents.defaults.experimental.localModelLean: true` (added in **2026.4.15**) that drops heavyweight default tools (browser, cron, message) from weaker local models. Lets small quantized models actually function instead of burning tokens parsing tool definitions they'll never use.

- **Covered in:** [Part 1 — Speed](./README.md#part-1-speed-stop-being-slow), [Part 6 — Models](./README.md#part-6-models-what-to-actually-use).

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

## Ralph loop

An orchestration pattern: **implement → test → loop until tests pass**, with a PreCompletionChecklist that runs verification *before* the agent claims success. Named after the ghuntley.com/loop essay; also implemented in Letta Code's `/ralph` mode and LangChain's PreCompletionChecklistMiddleware.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself).

## Repowise

Codebase-intelligence service that pre-builds a structural index of a repo so coding agents don't burn tokens re-reading the same files every spawn. ~60% fewer tokens, ~4x faster coding workflows in our measurements.

- **Covered in:** [Part 19 — Repowise](./part19-repowise-codebase-intelligence.md).

## Session memory files

Per-session raw transcripts and agent notes written under `memory/`. They pile up fast (200+ in a month) and are supposed to be consolidated into MEMORY.md by built-in Dreaming, then pruned by temporal decay.

- **Covered in:** [Part 3 — Cron Session Bloat](./README.md#part-3-cron-session-bloat-the-hidden-killer), [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming).

## `sessions_spawn`

The OpenClaw tool that creates a sub-agent. In Task Brain it produces a child flow with a parent-record link back to the originating conversation, plus its own approval-category scope.

- **Covered in:** [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself), [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md).

## Skill

A packaged capability (tools + prompt + optional hooks) installable from ClawHub or locally. In 2026.3.31-beta.1+, skill installs are **fail-closed** if the built-in security scan flags dangerous code; overriding requires the deliberately awkward `--dangerously-force-unsafe-install` flag.

- **Covered in:** [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md).

## SOUL.md

The per-workspace personality / tone / core-rules file. Injected on every message. Target size: **< 1 KB** — every byte costs latency.

- **Covered in:** [Part 2 — Context Bloat](./README.md#part-2-context-bloat-the-silent-performance-killer), [Part 4 — Memory](./README.md#part-4-memory-stop-forgetting-everything).

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
