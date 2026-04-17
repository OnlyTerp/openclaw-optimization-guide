# Awesome OpenClaw

**A curated list of resources for getting the most out of OpenClaw.** Skills, guides, talks, templates, tools, research. Contributions welcome — see [CONTRIBUTING.md](./CONTRIBUTING.md).

> This list is opinionated. Inclusion here means we've actually used it on a production OpenClaw deployment or seen it solve a real problem. Broken or abandoned links are removed aggressively. Last curated: **April 2026, tracking OpenClaw 2026.4.15 stable**.

## Contents

- [Official / First-party](#official--first-party)
- [Guides & tutorials](#guides--tutorials)
- [Reference configs & starter kits](#reference-configs--starter-kits)
- [Skills worth installing](#skills-worth-installing)
- [Memory & retrieval](#memory--retrieval)
- [Orchestration patterns](#orchestration-patterns)
- [Observability & evaluation](#observability--evaluation)
- [Security & hardening](#security--hardening)
- [Control plane & governance](#control-plane--governance)
- [UI surfaces & clients](#ui-surfaces--clients)
- [Research papers](#research-papers)
- [Talks, blog posts, podcasts](#talks-blog-posts-podcasts)
- [Benchmarks & leaderboards](#benchmarks--leaderboards)
- [Communities](#communities)
- [Adjacent ecosystems](#adjacent-ecosystems)

---

## Official / First-party

- **[openclaw/openclaw](https://github.com/openclaw/openclaw)** — the core framework. Releases + changelog live here.
- **[clawdocs.org](https://clawdocs.org)** — official documentation. Reference config schema, plugin API, gateway methods.
- **[openclawai.io/changelog](https://openclawai.io/changelog)** — release notes, beta announcements.
- **[ClawHub](https://clawhub.dev)** — skills marketplace. 13K+ skills after the March 2026 wave. See [Part 23](./part23-clawhub-skills-marketplace.md) before you install anything.
- **[Task Brain blog post](https://openclawai.io/blog/openclaw-task-brain-v2026-3-31-control-plane-security)** — the canonical "why a control plane" read.

## Guides & tutorials

- **[OpenClaw Optimization Guide](./README.md)** — this repo. 28 parts, production-tested on 2026.4.15 stable.
- **[Official "Getting Started" path](https://clawdocs.org/start)** — the minimum-viable setup. Read this first if you're brand new.
- **[The OpenClaw CVE flood, Feb–Mar 2026](https://www.tryopenclaw.ai/blog/openclaw-cve-flood-march-2026/)** — the definitive writeup on the **ClawHavoc** supply-chain campaign.
- **[Migration Guide — v3 → v4 → v2026.4.15 stable](./part26-migration-guide.md)** — opinionated upgrade paths.

## Reference configs & starter kits

- **[templates/](./templates/)** — this repo's starter kit. `openclaw.example.json`, SOUL.md, AGENTS.md, MEMORY.md, TOOLS.md. Clone and edit.
- **[examples/vault/](./examples/vault/)** — populated mini-vault showing what 2 weeks of usage looks like.
- **[SCORECARD.md](./SCORECARD.md)** — 50-item Production Readiness Scorecard. Grade your setup against the guide.

## Skills worth installing

(Opinion: the best **skill** is no skill — most of what ClawHub skills do should live in your own `AGENTS.md`. Install only when the alternative is genuinely harder.)

- **`openclaw-team/*` PR reviewer** — official code-review skill. Wired into Task Brain's `execution.sandbox.*` bucket.
- **`openclaw-team/*` git-safeguard** — blocks `--force`, `reset --hard`, dangerous `rebase -i` flags behind explicit approval. Ships as part of the "don't lose your branch" defaults.
- **Anything under `openclaw-team/*`** — first-party publisher, lowest risk after reading the diff.

Never install:

- Skills with <4 weeks of history, no public source, and aggressive update cadence. That was the ClawHavoc pattern.
- Skills that demand `write.fs.outside-workspace` or `control-plane.*` for what sounds like a surface-level task.
- "Productivity bundle" skills that install 20 tools at once. Pick the 2 you actually need.

See [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md) for the full vetting checklist.

## Memory & retrieval

- **[memory-core](https://github.com/openclaw/memory-core)** — the built-in memory plugin with native dreaming (3 phases). Replaced the custom-autoDream patterns in v4.
- **[memory-lancedb](https://github.com/openclaw/memory-lancedb)** — LanceDB vector store. 2026.4.15-beta.1 added cloud storage mode.
- **[Ollama](https://ollama.com/)** — local embedding runtime. `qwen3-embedding:0.6b` is the right default for most setups.
- **[LightRAG](https://github.com/HKUDS/LightRAG)** — graph + vector hybrid RAG. The right upgrade once your vault crosses ~500 files. See [Part 18](./part18-lightrag-graph-rag.md).
- **[Repowise](https://github.com/repowise/repowise)** — structural index for codebases. Feeds workers a map instead of re-reading files. See [Part 19](./part19-repowise-codebase-intelligence.md).

## Orchestration patterns

- **Coordinator Protocol** (Research → Synthesis → Implement → Verify) — this repo, [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself).
- **Ralph loop** (implement → test → loop until green) — this repo, [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself).
- **Memory Bridge** — push your vault into Codex / Claude Code / Cursor before they start. [Part 13](./part13-memory-bridge.md).
- **[ACP spec](https://openclawai.io/acp)** — Agent Communication Protocol, v4.2. The inter-agent message format.

## Observability & evaluation

- **[LangFuse](https://langfuse.com/)** — the lightest-weight LLM tracing that actually works end-to-end with OpenClaw surfaces.
- **[OpenTelemetry LLM instrumentation](https://opentelemetry.io/docs/specs/semconv/gen-ai/)** — the standards track. Pair with LangFuse or Grafana Tempo.
- **Canvas Model Auth status card** — built into 2026.4.15-beta.1+. The one dashboard you actually read every day.
- **[benchmarks/](./benchmarks/)** — this repo's measurement harness. Copy, run against your own setup, submit a PR with your numbers.

## Security & hardening

- **[Koi Security — ClawHavoc writeup](https://koi.security/)** — the ecosystem-wide supply-chain campaign named in March 2026.
- **Antiy CERT — 1,184 malicious skills report** (Feb 2026) — scale of the skills-ecosystem incident.
- **Trend Micro — Atomic Stealer via OpenClaw skills** (Mar 2026) — 39 skills distributing macOS infostealer.
- **Kaspersky OpenClaw audit** — 512 vulns, 8 critical including `CVE-2026-25253` (1-click RCE) and WebSocket shared-auth scope escalation at CVSS 9.9.
- **This repo, [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md)** — operational hardening checklist.

## Control plane & governance

- **[Task Brain](./part24-task-brain-control-plane.md)** — OpenClaw's control plane. Semantic approval categories, agent-initiated denies, unified task flow registry.
- **Approval policy reference** — [templates/openclaw.example.json](./templates/openclaw.example.json) ships with a starting-point policy block.

## UI surfaces & clients

- **[Canvas](https://clawdocs.org/canvas)** — the first-party control UI. Model Auth card, approvals, memory browser.
- **Webchat** — the browser surface. 2026.4.15 stable tightened localRoots containment on audio.
- **Matrix bridge** — chat-in-Matrix surface. Pairing-auth tightened in 2026.4.15 stable; DM pairing-store entries can no longer authorize room control.

## Research papers

- **[Lost in the Middle: How Language Models Use Long Contexts](https://arxiv.org/abs/2307.03172)** — the foundational "why context bloat is lethal" paper. The entire Speed pillar is downstream of this.
- **[MMEB: Massive Multimodal Embedding Benchmark](https://arxiv.org/abs/2410.05160)** — where Qwen3-VL-Embedding-8B earned its #1 rank. Relevant to [Part 10](./part10-state-of-the-art-embeddings.md).
- **[LightRAG: Simple and Fast Retrieval-Augmented Generation](https://arxiv.org/abs/2410.05779)** — the paper behind [Part 18](./part18-lightrag-graph-rag.md).

## Talks, blog posts, podcasts

- **Terp — *Running OpenClaw In Production* (2026)** — the talk this guide is derived from. Slide deck: *(link when public)*.
- **OpenClaw team — *"Why We Built Task Brain"* (Mar 2026)** — the official framing for the control-plane shift.

## Benchmarks & leaderboards

- **[SWE-bench](https://www.swebench.com/)** — coding-agent leaderboard. Relevant to model selection in [Part 6](./README.md#part-6-models-what-to-actually-use).
- **[MMEB leaderboard](https://embedding-benchmark.github.io/)** — multimodal embedding rankings. Qwen3-VL-Embedding-8B currently #1.
- **[benchmarks/](./benchmarks/)** — this repo's numbers. Submit yours via PR.

## Communities

- **[OpenClaw Discord](https://discord.gg/openclaw)** — official community. `#self-hosting` and `#skills-security` are the useful channels.
- **[r/OpenClaw](https://reddit.com/r/OpenClaw)** — mixed-quality, but good for spotting release-day issues before official channels catch up.
- **[OpenClaw Matrix room](https://matrix.to/#/#openclaw:matrix.org)** — smaller, more technical.

## Adjacent ecosystems

These are *not* OpenClaw, but they solve overlapping problems and the concepts transfer:

- **[Letta](https://github.com/letta-ai/letta)** (MemGPT) — one of the earliest "give the agent a real memory" projects. Influenced memory-core.
- **[CrewAI](https://github.com/crewAIInc/crewAI)** — multi-agent orchestration. Compare against the Coordinator Protocol in [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself).
- **[LangGraph](https://github.com/langchain-ai/langgraph)** — graph-shaped agent orchestration. Useful mental model even if you don't ship on it.
- **[Claude Code](https://www.anthropic.com/claude-code)** — Anthropic's first-party coding agent. The Memory Bridge ([Part 13](./part13-memory-bridge.md)) exists partly to feed it your vault.
- **[Aider](https://github.com/Aider-AI/aider)** — another strong coding agent, pair-well with OpenClaw for architecture.

---

## How to contribute

1. New link or resource? Open a PR that edits this file. Include a one-sentence justification for why you'd link it to a newcomer.
2. Link is broken or abandoned? Open an issue with the ["Correction" template](./.github/ISSUE_TEMPLATE/correction.md).
3. Keep it to the same opinionated bar: has this solved a real problem on a real OpenClaw deployment?

Also see the larger [CONTRIBUTING.md](./CONTRIBUTING.md).
