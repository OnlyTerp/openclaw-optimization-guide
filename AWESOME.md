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

- **[OpenClaw Optimization Guide](./README.md)** — this repo. 32 parts, production-tested on 2026.4.15 stable.
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
- **[vbfs/agent-memory-store](https://github.com/iflow-mcp/vbfs-agent-memory-store)** (Apr 15, 2026) — **92.1% Recall@5 with zero LLM calls.** Pure vector store + reranker; memory ops that don't burn Opus tokens. Covered in [Part 22](./README.md#part-22-built-in-dreaming).
- **[LightMem (arXiv 2604.07798)](https://arxiv.org/abs/2604.07798)** (Apr 12, 2026) — STM/MTM/LTM consolidation on a **small** model, 83 ms retrieval, +2.5 F1 on LoCoMo. The paper behind "run memory ops on an SLM."
- **[Mem²Evolve (arXiv 2604.10923)](https://arxiv.org/html/2604.10923v1)** (Apr 14, 2026) — co-evolves skill + memory populations; +18.53% over skill-only baselines. Research direction for [Part 32](./part32-self-evolving-skills-with-skillclaw.md).
- **[AMFS (Apache 2.0 MCP server)](https://dev.to/bruno_andrade_357863927e2/your-claude-code-and-cursor-agents-have-amnesia-heres-the-fix-2l3a)** (Apr 13, 2026) — drop-in MCP memory server, any model.

## Orchestration patterns

- **Anthropic's 5 coordination patterns (official taxonomy, Apr 10, 2026)** — [claude.com/blog/multi-agent-coordination-patterns](https://claude.com/blog/multi-agent-coordination-patterns). Generator-verifier, orchestrator-subagent, agent teams, hierarchical, network. Covered in [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself).
- **Coordinator Protocol** (Research → Synthesis → Implement → Verify) — this repo, [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself).
- **[frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code)** (8.7K stars) — the reference Ralph Loop implementation. OpenClaw-specific port: [Ralph Loops + OpenClaw (DEV, Apr 13, 2026)](https://dev.to/satoru_906c2ffeaf64bd2ac1/stop-babysitting-your-ai-agent-use-ralph-loops-openclaw-fdi). Covered in [Part 30](./part30-ralph-loop-in-openclaw.md).
- **[Sub-agents are context garbage collection (heyuan110, Apr 13, 2026)](https://www.heyuan110.com/posts/ai/2026-04-13-harness-subagent-architecture/)** — the reframe that anchors [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself).
- **[Builder.io — Claude Code sub-agents (Apr 16, 2026)](https://www.builder.io/blog/claude-code-subagents)** — the production-grade take on sub-agent patterns.
- **Memory Bridge** — push your vault into Codex / Claude Code / Cursor before they start. [Part 13](./part13-memory-bridge.md).
- **[ACP spec](https://openclawai.io/acp)** — Agent Communication Protocol, v4.2. The inter-agent message format.
- **[Git worktrees for parallel AI agents (Upsun, Apr 14, 2026)](https://developer.upsun.com/posts/2026/git-worktrees-for-parallel-ai-coding-agents)** — the worktree-per-agent pattern. See also [Part 15](./part15-infrastructure-hardening.md).

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
- **[Karpathy — *The LLM Wiki* (YouTube, Apr 10, 2026, 4.3K views)](https://www.youtube.com/watch?v=K47qWvM8os0)** — the three-tier file-hierarchy pattern that anchors [Part 31](./part31-the-llm-wiki-pattern-in-openclaw.md).
- **[Aaron Fulkerson — Karpathy's LLM Wiki in production (Exo, Apr 12, 2026)](https://aaronfulkerson.com/2026/04/12/karpathys-pattern-for-an-llm-wiki-in-production/)** — a concrete implementation of the same pattern.
- **[AaronRoeF/claude-code-patterns](https://github.com/AaronRoeF/claude-code-patterns)** — 153 catalogued patterns. Useful negative-example lookup when wondering "has someone tried X?"
- **[The Harness Is Everything (Medium, Apr 13, 2026)](https://medium.com/@reliabledataengineering/the-harness-is-everything-a4114e8a54d1)** — the widely-shared distillation of the Princeton NLP thesis. Opens the [README](./README.md#the-harness-thesis).
- **[Trensee — The Harness Is Everything (Apr 12, 2026)](https://trensee.ai/blog/the-harness-is-everything)** — independent convergence on the same thesis.
- **[Atlan — The Agent Harness 2026](https://atlan.com/blog/agent-harness-2026)** — the third independent convergence.
- **[Ido Green — Agentic engineering essays (Apr 2026)](https://idogreen.com/)** — practitioner-voice writing on day-to-day harness ergonomics.
- **[Spec-Driven Development: The Key To Scaling Autonomous AI Agents (Time, Apr 14, 2026)](https://time.news/spec-driven-development-the-key-to-scaling-autonomous-ai-agents/)** — the AWS Kiro case study (18 months → 76 days). Anchors [Part 26 § SDD](./part26-migration-guide.md#pair-openclaw-with-a-machine-readable-spec-spec-driven-development).
- **[Progressive Disclosure for AI Agents (MindStudio, Apr 15, 2026)](https://www.mindstudio.ai/blog/progressive-disclosure-ai-agents-context-management/)** — why CLAUDE.md-as-dumping-ground is the wrong default.
- **[Stop Stuffing Your Custom Instructions (Medium, Apr 12, 2026)](https://medium.com/@kdineshkvkl/stop-stuffing-your-custom-instructions-the-definitive-guide-to-claude-skills-mcp-0edda444fcda)** — companion argument.
- **[Claude Code Hooks Automation (Claude Lab, Apr 10, 2026)](https://claudelab.net/en/articles/claude-code/claude-code-hooks-automation-master-guide)** — the deepest dive on the 18 hook events + exit codes. Covered in [Part 29](./part29-hook-catalog.md).
- **[Claude Code Hooks: Automate Your Coding Workflow In 2026 (DEV, Apr 12, 2026)](https://dev.to/kfuras/claude-code-hooks-automate-your-coding-workflow-in-2026-3dkg)** — practical hook recipes.
- **[Amit Kothari — What Is A Hook, exit codes, and StopFailure](https://amitkoth.com/what-is-a-hook-claude-code/)** — the exit-code debugging war story. Referenced in [Part 29](./part29-hook-catalog.md).
- **[Amit Ray — CLAUDE.md vs AGENTS.md vs MEMORY.md vs SKILLS.md vs CONTEXT.md (Apr 14, 2026)](https://amitray.com/claude-md-vs-agents-md-memory-md-skills-md-context-md-guide-2026/)** — the file-hierarchy cheat sheet the ecosystem needed.
- **[Claude API Prompt Caching: 80% off (DEV, Apr 14, 2026)](https://dev.to/whoffagents/claude-api-prompt-caching-cut-costs-80-on-every-repeated-request-1ap6)** — the 5-minute TTL trap surfaced. Referenced in [Part 2](./README.md#appendix--the-5-minute-prompt-cache-ttl-trap-march-2026).

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
- **[AMAP-ML/SkillClaw](https://github.com/AMAP-ML/SkillClaw)** (Apr 10, 2026, 687 stars week-one) — population-level skill evolution. Explicitly supports OpenClaw as a first-class harness. Covered in [Part 32](./part32-self-evolving-skills-with-skillclaw.md).
- **[Twill.ai (YC S25, HN Apr 11, 2026)](https://news.ycombinator.com/item?id=47720418)** — cloud-sandbox agent delegation. The architectural alternative to self-hosted harnesses; compared in [Part 24](./part24-task-brain-control-plane.md#openclaw-vs-cloud-sandbox-delegation-twill--amika).
- **[Amika (YouTube demo, Apr 13, 2026)](https://www.youtube.com/watch?v=OZzdBNBXxSU)** — similar cloud-sandbox positioning to Twill.
- **[Andon Labs — Agent-infrastructure blog](https://andonlabs.com/)** — production-ops essays on running agents at scale. Good cross-pollination for operators.
- **[Aider](https://github.com/Aider-AI/aider)** — another strong coding agent, pair-well with OpenClaw for architecture.

---

## How to contribute

1. New link or resource? Open a PR that edits this file. Include a one-sentence justification for why you'd link it to a newcomer.
2. Link is broken or abandoned? Open an issue with the ["Correction" template](./.github/ISSUE_TEMPLATE/correction.md).
3. Keep it to the same opinionated bar: has this solved a real problem on a real OpenClaw deployment?

Also see the larger [CONTRIBUTING.md](./CONTRIBUTING.md).
