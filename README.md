# OpenClaw Optimization Guide

**Make your OpenClaw AI agent faster, smarter, cheaper, and actually safe to run in production.**

[![Tested on 2026.4.15](https://img.shields.io/badge/OpenClaw-2026.4.15-2ea44f)](./part26-migration-guide.md)
[![32 parts](https://img.shields.io/badge/parts-32-blue)](#full-table-of-contents)
[![Scorecard](https://img.shields.io/badge/scorecard-50_items-8957e5)](./SCORECARD.md)
[![Awesome](https://img.shields.io/badge/awesome-list-fc60a8)](./AWESOME.md)
[![Benchmarks](https://img.shields.io/badge/benchmarks-reproducible-0a7bbb)](./benchmarks/METHODOLOGY.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey)](./LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](./CONTRIBUTING.md)

> **Tested on OpenClaw 2026.4.15 — April 16, 2026.** 32 parts + scorecard + awesome list + reproducible benchmarks. Battle-tested on a 14+ agent production deployment. Covers speed, memory, orchestration, models, web search, vault architecture, embeddings, hooks, graph RAG, codebase intelligence, observability, infrastructure hardening, skills marketplace, control-plane security, Ralph-loop autonomy, the LLM Wiki pattern, and self-evolving skills.

*By Terp — [Terp AI Labs](https://x.com/OnlyTerp)*

---

## The Harness Thesis

> **95% of agent capability comes from the harness, 5% from the model.** Same weights, different harness, different benchmarks.

That line isn't ours. It's what nine independent writers — Princeton NLP, [Atlan](https://atlan.com/blog/agent-harness-2026), [Trensee](https://trensee.ai/blog/the-harness-is-everything) (Apr 12, 2026), a [Medium deep-dive](https://medium.com/@reliabledataengineering/the-harness-is-everything-a4114e8a54d1) (Apr 13, 2026), a [Korean YouTube explainer with 14.9K views](https://www.youtube.com/), [heyuan110](https://www.heyuan110.com/posts/ai/2026-04-13-harness-subagent-architecture/), [The AI Corner](https://medium.com/the-ai-corner), [Towards AI](https://pub.towardsai.net/), and [ivanmagda.dev](https://ivanmagda.dev) — all converged on in the week of April 10–17, 2026.

This guide is what operating that thesis looks like, end-to-end, on a real production OpenClaw deployment. It is the harness.

```mermaid
flowchart LR
    subgraph Model["The Model (5%)"]
        M[Claude Opus 4.7<br/>or your choice]
    end
    subgraph Harness["The Harness (95%) — this guide"]
        direction TB
        Inst[Instructions<br/>SOUL/AGENTS/MEMORY/skills]
        Ctx[Context engineering<br/>budgets + progressive disclosure]
        Tools[Tools + approvals<br/>semantic categories]
        Guard[Guardrails<br/>hooks, Task Brain, redaction]
        Mem[Memory layer<br/>memory-core + LightRAG + dreaming]
        Orch[Orchestration<br/>5 coordination patterns]
    end
    Model -.-> Harness
    Harness -.-> Results[Production results]
```

The 5% you can't change: the weights. The 95% you can: everything else. The rest of this guide is the 95%.

## Jump straight to the payoff

| Do this | For this outcome |
|---|---|
| **[Grade your setup →](./SCORECARD.md)** | 50-item Production Readiness Scorecard, score out of 100, shareable. |
| **[Copy the reference config →](./templates/)** | Working `openclaw.example.json` + SOUL / AGENTS / MEMORY / TOOLS templates for 2026.4.15 stable. |
| **[See the numbers →](./benchmarks/METHODOLOGY.md)** | Reproducible benchmark methodology + harness + run template. |
| **[Browse the ecosystem →](./AWESOME.md)** | Curated list of skills, tools, papers, talks, adjacent projects. |
| **[Hit a wall? →](./part27-gotchas-and-faq.md)** | Gotchas & FAQ, symptom-indexed. Most questions answered in one page. |

---

## File Hierarchy At A Glance

OpenClaw's file layout maps 1:1 to [Karpathy's three-tier LLM Wiki pattern](./part31-the-llm-wiki-pattern-in-openclaw.md) published April 10, 2026. If you only remember one diagram from this guide, make it this one:

```mermaid
flowchart TB
    subgraph Raw["Raw sources — immutable, agent read-only"]
        Vault["vault/*"]
        Daily["memory/YYYY-MM-DD.md"]
    end
    subgraph Curated["Curated summaries — injected on every message"]
        Soul["SOUL.md<br/>identity"]
        Agents["AGENTS.md<br/>operational rules"]
        Mem["MEMORY.md<br/>durable facts"]
        Dreams["DREAMS.md<br/>reflection diary"]
        Skills["skills/*<br/>on-demand playbooks"]
    end
    subgraph Artifacts["Generated artifacts — one-shot output"]
        PRs["PRs / commits"]
        Reports["Reports / transcripts"]
    end
    Raw -. memory_search .-> Agent((Agent))
    Curated --> Agent
    Agent --> Artifacts
    Agent -. Deep-phase promote .-> Mem
    Artifacts -. auto-capture .-> Daily
```

| File | Purpose | Size cap | Written by | Read when |
|------|---------|---------:|------------|-----------|
| **SOUL.md** | Identity, invariants, non-negotiables | < 1 KB | Human | Every message |
| **AGENTS.md** | Operational rules, decision trees, tool routing | < 2 KB | Human + agent (auditable) | Every message |
| **MEMORY.md** | Durable facts promoted from short-term (pointer index) | < 3 KB | Agent via `memory promote` | Every message |
| **DREAMS.md** | Human-readable reflection diary | latest N entries | Built-in Dreaming | Every message |
| **skills/** | Named playbooks | per-skill small | Human + SkillClaw | On activation |
| **vault/** | Raw source notes, transcripts, links | unbounded | Auto-capture + humans | On `memory_search` |
| **memory/YYYY-MM-DD.md** | Daily short-term rollup | rolling | Auto-capture | On `memory_search` |

Full reasoning and update rules in **[Part 31 — The LLM Wiki Pattern In OpenClaw](./part31-the-llm-wiki-pattern-in-openclaw.md)**.

---

## Who This Is For

- **Running any OpenClaw agent in production.** If your bot handles real work, the speed, memory, and security parts are non-optional.
- **Just hit "why is my agent slow?" for the first time.** [Part 1](#part-1-speed-stop-being-slow) and [Part 2](#part-2-context-engineering--the-discipline) are where to start.
- **Coming from v3.x or early v4.0.** Start with [Part 26 — Migration Guide](./part26-migration-guide.md), then [Part 25 — Architecture Overview](./part25-architecture-overview.md).
- **Building multi-agent systems.** [Part 5 — Orchestration](#part-5-orchestration-stop-doing-everything-yourself) and [Part 24 — Task Brain](./part24-task-brain-control-plane.md) are your backbone.
- **Already read half the guide and forget what's where.** Jump to [Part 27 — Gotchas & FAQ](./part27-gotchas-and-faq.md) or the themed map below.

---

## Start Here (In This Order)

1. **[Part 25 — Architecture Overview](./part25-architecture-overview.md)** — 15-minute primer on what OpenClaw actually is under the hood (gateway, Task Brain, memory layer, skills, surfaces).
2. **[Part 14 — Quick Checklist](#part-14-quick-checklist)** — 30-minute setup checklist covering the 80/20.
3. **[Part 17 — The One-Shot Prompt](#part-17-the-one-shot-prompt)** — copy-paste prompt that automates the whole setup.
4. **[Part 27 — Gotchas & FAQ](./part27-gotchas-and-faq.md)** — keep this open while you work. Half your questions are here.

---

## What You Get (Numbers From Our Production Deployment)

| Metric | Before | After | Source |
|--------|-------:|------:|--------|
| Context file size (SOUL + AGENTS + MEMORY) | ~15 KB | ~5 KB | [Part 1](#part-1-speed-stop-being-slow) |
| Memory search latency | 2–5s (cloud) | <100ms (local) | [Part 4](#part-4-memory-stop-forgetting-everything), [Part 10](./part10-state-of-the-art-embeddings.md) |
| Compaction crash rate | loops on 16K models | 0 (fixed in 4.15 stable) | [Part 15](./part15-infrastructure-hardening.md) |
| Coding-agent token usage | baseline | –60% | [Part 19 — Repowise](./part19-repowise-codebase-intelligence.md) |
| Sessions before audit trail | 0 surfaces | all surfaces | [Part 24 — Task Brain](./part24-task-brain-control-plane.md) |

Full numbers in **[benchmarks/](./benchmarks/)**.

---

## Companion resources shipped with the guide

Alongside the 32 parts themselves, this repo now includes the tooling that turns "I read the guide" into "I can audit and reproduce the results":

- **[SCORECARD.md](./SCORECARD.md)** — The OpenClaw Production Readiness Scorecard. 50 items across Speed / Memory / Orchestration / Security / Observability, 2 points each, max 100. Designed to be copy-pasted into your own repo and shared publicly.
- **[AWESOME.md](./AWESOME.md)** — A curated, opinionated list of OpenClaw resources: skills worth installing, memory and orchestration tools, observability stacks, research papers, talks, communities, adjacent ecosystems.
- **[templates/](./templates/)** — A working reference config starter kit: `openclaw.example.json`, tiny SOUL.md / AGENTS.md / MEMORY.md / TOOLS.md templates, and a `vault/` skeleton. All aligned to 2026.4.15 stable (Opus 4.7, semantic approvals, `dreaming.storage.mode: "separate"`).
- **[benchmarks/METHODOLOGY.md](./benchmarks/METHODOLOGY.md)** + **[benchmarks/harness/](./benchmarks/harness/)** + **[benchmarks/runs/TEMPLATE.md](./benchmarks/runs/TEMPLATE.md)** — A reproducible benchmark methodology (4 pillars, 3 reference environments) plus a contract for submitting your own numbers via PR.
- **[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)** · **[SECURITY.md](./SECURITY.md)** · **[SUPPORT.md](./SUPPORT.md)** — Community standards so you know how to file issues, report problems, and get help.
- **GitHub Pages site** — rendered from this repo via MkDocs-material: <https://onlyterp.github.io/openclaw-optimization-guide/>.

---

## What Changed In This Release (2026.4.15 Refresh)

- **Task Brain control plane** (new [Part 24](./part24-task-brain-control-plane.md)) — unified task ledger, semantic approval categories, agent-initiated denies, fail-closed plugin defaults. Shipped as the structural fix for the March CVE wave.
- **ClawHub skills marketplace** (new [Part 23](./part23-clawhub-skills-marketplace.md)) — 13K+ community skills, 1,184 removed for being malicious. Install policy, signing, scope-limiting, sleeper-update mitigation.
- **v4.0 Architecture Overview** (new [Part 25](./part25-architecture-overview.md)) — the primer that should have existed since the rewrite.
- **Migration Guide** (new [Part 26](./part26-migration-guide.md)) — opinionated v3 → v4 → v2026.3 → v2026.4 → v2026.4.15 upgrade paths with rollback plans.
- **Gotchas & FAQ** (new [Part 27](./part27-gotchas-and-faq.md)) — symptom-indexed troubleshooting, most questions answered in one page.
- **Glossary & Terminology** (new [Part 28](./part28-glossary-and-terminology.md)) — every term this guide uses (MOC, autoDream, Task Brain, ACP, Ralph loop, ClawHavoc, memory-lancedb, LightRAG, semantic approvals, `localModelLean`…) on one page, cross-linked to the part that introduces each.
- **Decision trees on every part** — each part (README-embedded and external) now opens with a "Read this if / Skip if" callout so you can route yourself through the guide instead of reading it linearly.
- **Part 16 (custom autoDream) retired** — the file has been removed. Memory-core's native dreaming ([Part 22](#part-22-built-in-dreaming)) is the official path since 2026.4+; see the short retirement note in Part 22 below if you're coming from the old pattern.
- Updates across existing parts for: memory-lancedb cloud storage, GitHub Copilot embedding provider, `localModelLean` flag, compaction reserve-token floor cap, gateway auth hot-reload, approvals secret redaction, `memory_get` canonical-only, Model Auth status card.
- **v2026.4.15 stable (April 16, 2026)** — **Claude Opus 4.7** is the new default Anthropic selection (`opus` aliases + Claude CLI defaults + bundled image understanding all point at it); **dreaming default flipped `inline` → `separate`** so phase blocks land in `memory/dreaming/{phase}/YYYY-MM-DD.md` instead of polluting daily memory files; **`memory_get` excerpts are now capped by default** with explicit continuation metadata + trimmed startup/skills prompt budgets; **gateway tool-name normalize-collision rejection** (client tools that collide with a built-in get `400 invalid_request_error`, closing a local-media trust-inheritance hole); plus Gemini TTS in the bundled `google` plugin, Control UI false-positive Model Auth fix, webchat localRoots containment, and Matrix pairing-auth tightening.

---

## How The Pieces Fit Together

```mermaid
flowchart LR
    You[You]
    subgraph Surfaces
        Canvas[Canvas UI]
        CLI[CLI / IDE]
        Cron[Cron / ACP]
    end
    subgraph Gateway["Gateway daemon (Task Brain)"]
        Ledger[Task ledger]
        Approvals[Semantic approvals]
        Auth[Auth / secrets]
    end
    subgraph Agents
        Main[Main agent]
        Workers[Sub-agents]
    end
    subgraph Memory["Memory layer"]
        MemCore[memory-core<br/>MEMORY.md + DREAMS.md]
        Lance[memory-lancedb<br/>vector search]
        Light[LightRAG<br/>graph RAG]
    end
    subgraph Capabilities
        Hub[ClawHub skills]
        Hooks[Hooks]
        Tools[Tools]
    end

    You --> Surfaces
    Surfaces --> Gateway
    Gateway --> Agents
    Agents --> Memory
    Agents --> Capabilities
    Capabilities -. register with .-> Gateway
    Memory -. feed .-> Agents
```

Full breakdown of each block in **[Part 25 — Architecture Overview](./part25-architecture-overview.md)**.

---

## Navigate By Goal

Not every part applies to every reader. Jump directly to the pillar that matches what you're trying to do:

| I want to… | Start with |
|-------------|-----------|
| **Make my agent faster** | [1 Speed](#part-1-speed-stop-being-slow) · [2 Context Engineering](#part-2-context-engineering--the-discipline) · [3 Cron Bloat](#part-3-cron-session-bloat-the-hidden-killer) · [6 Models](#part-6-models-what-to-actually-use) |
| **Stop it forgetting things** | [4 Memory](#part-4-memory-stop-forgetting-everything) · [9 Vault](#part-9-vault-memory-system-stop-losing-knowledge-between-sessions) · [10 Embeddings](./part10-state-of-the-art-embeddings.md) · [22 Built-In Dreaming](#part-22-built-in-dreaming) · [31 LLM Wiki Pattern](./part31-the-llm-wiki-pattern-in-openclaw.md) |
| **Reduce cost** | [5 Orchestration](#part-5-orchestration-stop-doing-everything-yourself) · [6 Models](#part-6-models-what-to-actually-use) · [8 One-Shotting](#part-8-one-shotting-big-tasks-stop-iterating-start-researching) · [22 Memory you can afford](#part-22-built-in-dreaming) |
| **Handle real codebases** | [18 LightRAG](./part18-lightrag-graph-rag.md) · [19 Repowise](./part19-repowise-codebase-intelligence.md) · [21 Real-time Sync](./part21-realtime-knowledge-sync.md) |
| **Harden for production** | [15 Infra Hardening](./part15-infrastructure-hardening.md) · [23 ClawHub](./part23-clawhub-skills-marketplace.md) · [24 Task Brain](./part24-task-brain-control-plane.md) · [29 Hook Catalog](./part29-hook-catalog.md) |
| **See what my agents are doing** | [20 Observability](./part20-observability-and-services.md) · [24 Task Brain audit](./part24-task-brain-control-plane.md) |
| **Automate self-improvement** | [11 Auto-Capture Hook](./part11-auto-capture-hook.md) · [12 Self-Improving System](./part12-self-improving-system.md) · [13 Memory Bridge](./part13-memory-bridge.md) · [32 Self-evolving skills (SkillClaw)](./part32-self-evolving-skills-with-skillclaw.md) |
| **Run autonomous / overnight work** | [5 Orchestration patterns](#part-5-orchestration-stop-doing-everything-yourself) · [30 Ralph Loop](./part30-ralph-loop-in-openclaw.md) · [15 Worktrees](./part15-infrastructure-hardening.md) · [26 Spec-Driven Development](./part26-migration-guide.md) |
| **Enforce safety the agent can't ignore** | [29 Hook Catalog](./part29-hook-catalog.md) · [24 Task Brain](./part24-task-brain-control-plane.md) · [15 Infra Hardening](./part15-infrastructure-hardening.md) |
| **Upgrade from an older version** | [26 Migration Guide](./part26-migration-guide.md) |
| **Look up a term you don't know** | [28 Glossary](./part28-glossary-and-terminology.md) |
| **Debug something weird** | [27 Gotchas & FAQ](./part27-gotchas-and-faq.md) |

---

## Full Table of Contents

**🎯 Primers & references**
- [25. Architecture Overview](./part25-architecture-overview.md) — the 15-min mental map of v4.0+
- [26. Migration Guide](./part26-migration-guide.md) — upgrade paths + rollback plans
- [27. Gotchas & FAQ](./part27-gotchas-and-faq.md) — symptom → fix table + frequently asked questions
- [28. Glossary & Terminology](./part28-glossary-and-terminology.md) — every term this guide assumes, on one page
- [14. Quick Checklist](#part-14-quick-checklist) — 30-minute setup
- [17. The One-Shot Prompt](#part-17-the-one-shot-prompt) — automation prompt (2026.4.15)

**⚡ Speed & context**
1. [Speed — Stop Being Slow](#part-1-speed-stop-being-slow) — trim context, add fallbacks, reasoning mode, `localModelLean`
2. [Context Engineering — The Discipline](#part-2-context-engineering--the-discipline) — quadratic scaling, pruning, compaction, 5-min cache TTL trap
3. [Cron Session Bloat — The Hidden Killer](#part-3-cron-session-bloat-the-hidden-killer) — session file accumulation, cleanup

**🧠 Memory**
4. [Memory — Stop Forgetting Everything](#part-4-memory-stop-forgetting-everything) — 3-tier memory, Ollama, lancedb cloud storage, Copilot embeddings
9. [Vault Memory System](#part-9-vault-memory-system-stop-losing-knowledge-between-sessions) — folders, MOCs, claim-named notes, wiki-links
10. [State-of-the-Art Embeddings](./part10-state-of-the-art-embeddings.md) — qwen3-embedding, GPU tier, Windows path, Copilot provider
11. [Auto-Capture Hook](./part11-auto-capture-hook.md) — automatic knowledge extraction after every session
12. [Self-Improving System](./part12-self-improving-system.md) — micro-learning loop, HOT/WARM/COLD tiers
13. [Memory Bridge](./part13-memory-bridge.md) — give Codex / Claude Code access to your vault
22. [Built-In Dreaming (memory-core)](#part-22-built-in-dreaming) — official 3-phase consolidation, DREAMS.md, memory-you-can-afford (LightMem + vbfs)
31. [The LLM Wiki Pattern In OpenClaw](./part31-the-llm-wiki-pattern-in-openclaw.md) — Karpathy's three-tier pattern mapped onto SOUL/AGENTS/MEMORY/skills

**🤝 Orchestration & models**
5. [Orchestration](#part-5-orchestration-stop-doing-everything-yourself) — sub-agents-as-GC, Anthropic's 5 coordination patterns, CEO/COO/Worker, verification
6. [Models — What To Actually Use](#part-6-models-what-to-actually-use) — provider comparison, pricing, local, `localModelLean`
7. [Web Search](#part-7-web-search-give-your-agent-eyes-on-the-internet) — Tavily, Brave, Serper, Gemini grounding
8. [One-Shotting Big Tasks](#part-8-one-shotting-big-tasks-stop-iterating-start-researching) — research-first methodology
30. [The Ralph Loop In OpenClaw](./part30-ralph-loop-in-openclaw.md) — autonomous `while true` wrappers, PRD.json, overnight runs
32. [Self-Evolving Skills With SkillClaw](./part32-self-evolving-skills-with-skillclaw.md) — skill population evolution, Mem²Evolve

**🧩 Knowledge graph & codebase**
18. [LightRAG — Graph RAG](./part18-lightrag-graph-rag.md) — entities + relationships, Web UI, REST, LangFuse tracing
19. [Repowise — Codebase Intelligence](./part19-repowise-codebase-intelligence.md) — 60% fewer tokens, 4x faster coding agents
21. [Real-Time Knowledge Sync](./part21-realtime-knowledge-sync.md) — event-driven file watcher, <6s vault → LightRAG sync

**🔒 Hardening & security**
15. [Infrastructure Hardening](./part15-infrastructure-hardening.md) — compaction crash loops, GPU contention, secrets, gateway crash-loop fix, reserve-token cap, auth hot-reload, approval redaction, **parallel OpenClaw with git worktrees**
23. [ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md) — marketplace, malware, install policy
24. [Task Brain Control Plane](./part24-task-brain-control-plane.md) — unified task ledger, semantic approvals, trust boundaries
29. [The Hook Catalog](./part29-hook-catalog.md) — 8 copy-paste hooks, exit-code semantics, deterministic enforcement

**🔭 Observability**
20. [Agent Observability](./part20-observability-and-services.md) — LangFuse, reranker, n8n, workflow automation

**📖 Reference**
25. [Architecture Overview (v4.0+)](./part25-architecture-overview.md) — gateway / agents / memory / skills / surfaces primer
26. [Migration Guide](./part26-migration-guide.md) — opinionated upgrade paths with rollback
27. [Common Gotchas & FAQ](./part27-gotchas-and-faq.md) — symptom-indexed troubleshooting
28. [Glossary & Terminology](./part28-glossary-and-terminology.md) — every term this guide assumes, on one page

---

**📊 [Benchmarks](./benchmarks/)** — real numbers from a production system (context savings, search latency, reindex results, SWE-bench rankings)

**📁 [Example Vault](./examples/)** — populated mini-vault showing MOCs, wiki-links, Agent Notes, and `.learnings/` after 2 weeks of use

**🤝 [Contributing](./CONTRIBUTING.md)** — how to propose corrections, new parts, and version-bump PRs

---

## The Problem

If you're running a stock OpenClaw setup, you're probably dealing with:

- **Freezing and hitting context limits.** Bloated workspace files exhaust the context window mid-response.
- **Slow responses.** 15-20KB+ of context injected every message = hundreds of milliseconds of latency per reply.
- **Forgetting everything.** New session = blank slate. No memory of yesterday's work or decisions.
- **Inconsistent behavior.** Without clear rules, personality drifts between sessions.
- **Doing everything the expensive way.** Main model writes code, does research, AND orchestrates - all at top-tier pricing.
- **Flying blind.** No web search means guessing at anything after training cutoff.
- **Wrong model choice.** Using whatever was default without considering the tradeoffs.

## What This Fixes

After this setup:

| Metric | Before | After |
|--------|--------|-------|
| Context per msg | 15-20 KB | 4-5 KB |
| Time to respond | 4-8 sec | 1-2 sec |
| Memory recall | Forgets daily | Remembers weeks |
| Token cost/msg | ~5,000 tokens | ~1,500 tokens |
| Long sessions | Degrades | Stable |
| Concurrent tasks | One at a time | Multiple parallel |

### How It Works

```
You ask a question
    ↓
Orchestrator (main model, lean context ~5KB)
    ↓
┌─────────────────────────────────────────┐
│  memory_search() - 45ms, local, $0     │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │MEMORY.md│→ │memory/*.md│→ │vault/* │ │
│  │(index)  │  │(quick)   │  │(deep)  │ │
│  └─────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────┘
    ↓
Only relevant context loaded (~200 tokens)
    ↓
Fast, accurate response + sub-agents for heavy work
```

**The key insight:** Workspace files become **lightweight routers, not storage.** All knowledge lives in a local vector database. The bot loads only what it needs - not everything it's ever learned.

### What The Optimized Files Look Like

Full versions in [`/templates`](./templates):

**SOUL.md** (772 bytes - injected every message):
```markdown
## Who You Are
- Direct, concise, no fluff. Say the useful thing, then stop.
- Have opinions. Disagree when warranted. No sycophancy.

## Memory Rule
Before answering about past work, projects, people, or decisions:
run memory_search FIRST. It costs 45ms. Not searching = wrong answers.

## Orchestrator Rule
You coordinate; sub-agents execute. Never write 50+ lines of code yourself.
```

**MEMORY.md** (581 bytes - slim pointer index):
```markdown
## Active Projects
- Project A → vault/projects/project-a.md
- Project B → vault/projects/project-b.md

## Key People
- Person A - role, relationship → vault/people/person-a.md
```

Details live in vault/. The bot finds them via vector search in 45ms.

This isn't a settings tweak - it's a **complete architecture change**: memory routing, context engineering, and orchestration working together. The one-shot prompt at the bottom does the entire setup automatically.

> **Note:** Tested on Claude Opus 4.7 (the new Anthropic default as of 2026.4.15). Opus 4.6 also works fine — the differences are rounding-error for orchestration. Other frontier models should work if they can follow multi-step instructions.

> **Templates included:** Check [`/templates`](./templates) for ready-to-use versions of SOUL.md, AGENTS.md, MEMORY.md, TOOLS.md, and a sample vault/ structure.

---

## Part 1: Speed (Stop Being Slow)

> **Read this if** your agent feels laggy, you're on a Gemini/GPT default, or you just want to know which levers matter most. **Start here if you only read one part.**
> **Skip if** you've already tuned context, fallbacks, reasoning mode, and model selection.

Every message you send, OpenClaw injects ALL your workspace files into the prompt. Bloated files = slower, more expensive replies. This is the #1 speed issue people don't realize they have.

### Why Trimming Works

**You don't need big files once you have vector search.**

Old approach: Stuff everything into MEMORY.md so the bot "sees" it every message → 15KB+ context, slow responses, wasted tokens on irrelevant info.

New approach: MEMORY.md is a slim index of pointers. Full details live in vault/. `memory_search()` finds them instantly via local Ollama embeddings ($0). Your workspace files stay tiny without losing any knowledge.

### Trim Your Context Files

| File | Target Size | What Goes In It | Why This Size |
|------|------------|-----------------|---------------|
| SOUL.md | < 1 KB | Personality, tone, core rules | Injected EVERY message - every byte costs latency |
| AGENTS.md | 2-10 KB | Decision tree, tool routing, operational protocols (dreaming, coordinator) | Operational protocols are worth the context cost — they replace manual prompting |
| MEMORY.md | < 3 KB | **Pointers only** - NOT full docs | Vector search replaces big files |
| TOOLS.md | < 1 KB | Tool names + one-liner usage | Just reminders, not documentation |
| **Total** | **8-15 KB** | Everything injected per message | With operational protocols (built-in dreaming, coordinator), 8-15KB is acceptable — these replace manual prompting that would cost more |

**Rule:** If it's longer than a tweet thread, it's too long for a workspace file. Move the details to vault/.

### Add a Fallback Model

```json
"fallbackModels": ["your-provider/faster-cheaper-model"]
```

OpenClaw automatically switches when your main model is rate-limited or slow.

### Reasoning Mode - Know the Tradeoff

Run `/status` to see your current reasoning mode.

- **Off** - fastest, no thinking phase
- **Low** - slight thinking, faster responses
- **High** - deep reasoning, adds 2-5 seconds but catches things low/off misses

I run **high** and keep it there. The context trimming from other steps more than compensates for the reasoning overhead.

### Disable Unused Plugins

Every enabled plugin adds overhead. If you're not using `memory-lancedb`, `memory-core`, etc., set `"enabled": false`.

### Lean Mode for Weak Local Models

New in 2026.4.15: if you're running a small local model (≤14B params, 16K-32K context) and the default tool set is eating your whole prompt, flip the lean flag:

```json
{
  "agents": {
    "defaults": {
      "experimental": { "localModelLean": true }
    }
  }
}
```

This drops the heavyweight default tools (browser, cron, message) from the system prompt. You keep `memory_search`, `exec`, `sessions_spawn`, and the essentials — which is everything most local setups actually use. On a 16K-context Qwen3-14B, freeing ~3KB of tool definitions is the difference between "usable" and "can't fit a single retrieval result."

### Ollama Housekeeping

```bash
ollama ps        # Check what's loaded
ollama stop modelname  # Unload idle big models
```

The default model for memory search should be `qwen3-embedding:0.6b` (500 MB, 1024 dims) — same Qwen3 family that holds #1 on MTEB, runs on anything, and blows away nomic on quality. Pull it: `ollama pull qwen3-embedding:0.6b`. If you have a GPU with 8GB+ VRAM, upgrade to Qwen3-Embedding-8B for dramatically better search quality — see [Part 10](./part10-state-of-the-art-embeddings.md). If you have 500+ vault files, also add [LightRAG (Part 18)](./part18-lightrag-graph-rag.md) for knowledge graph retrieval that blows away basic vector search.

> **New in 2026.4.15 — memory-lancedb cloud storage.** `memory-lancedb` can now persist its index to S3-compatible object storage instead of local disk (`storage.type: "s3"` + `bucket` + `prefix` + `endpoint`). Useful for multi-machine setups where you want every box to see the same index, or for backing up a single-machine index without rsync. The hot path is still in-memory — cloud is just durable storage. Don't confuse this with cloud *embeddings* (still a bad idea for the hot path).

> **New in 2026.4.15 — GitHub Copilot embedding provider.** If your team already pays for Copilot Business/Enterprise, `memorySearch.provider: "copilot"` reuses that seat for embeddings. It's still cloud (2-5s round trips, same caveats as OpenAI/Voyage) so local Ollama is still the right default for personal setups — but for a corporate deployment that's already standardized on Copilot, this removes another vendor from the procurement list.

---

## Part 2: Context Engineering — The Discipline

> **Renamed in the April 2026 refresh.** "Context Bloat" was the *problem*; context engineering is the *discipline*. [Karpathy coined it](https://karpathy.ai/) and [Gartner picked it up](https://www.gartner.com/) within a week. The Part 2 material is the practical version of that discipline for OpenClaw.

> **Read this if** you notice each message getting slower, you're hitting compaction often, or your SOUL.md / MEMORY.md / AGENTS.md are over a few KB combined.
> **Skip if** your total injected context is already under 15 KB and compaction rarely fires.

### The Quadratic Problem

LLM attention scales **quadratically** with context length:

- **2x the tokens = 4x the compute cost**
- **3x the tokens = 9x the compute cost**

When context goes from 50K to 100K tokens, the model does **four times** the work. That means slower responses and higher bills.

### What Happens at 50% of Your Context Window

Just because a model *advertises* 1M context doesn't mean it *performs well* at 1M:

- **11 of 12 models** tested dropped below 50% accuracy by 32K tokens
- **GPT-4.1** showed a **50x increase in response time** at ~133K tokens
- Models exhibit **"lost-in-the-middle" bias** - they track the beginning and end but lose the middle
- Effective context is usually a fraction of the max

### Where Bloat Comes From

| Source | Typical Size | Injected When |
|--------|-------------|---------------|
| System prompt | 2-5 KB | Every message |
| Workspace files | 5-20 KB | Every message |
| Conversation history | Grows per turn | Every message |
| Tool results | 1-50 KB each | After tool calls |
| Skill files | 1-5 KB each | When skill activates |

**Tool spam is the worst offender.** A single `exec` returning a large file = 20K+ tokens permanently in your session. Five tool calls = 100K tokens of context the model re-reads every message.

### The Numbers That Matter

Production agents consume **100 tokens of context for every 1 token generated.** Your context window IS your performance budget.

**Compression targets** (from Maxim AI production data):
- Historical context: **3:1 to 5:1** compression ratio
- Tool outputs: **10:1 to 20:1** compression ratio
- If your agent is at **>60% context utilization before the user speaks**, you're in trouble

**The 60% Rule:** If system prompt + workspace files + memory search results exceed 60% of your context window before the user even sends a message, apply these in order:
1. Summarize conversation history
2. Filter retrieval results (fewer, more relevant chunks)
3. Route tools dynamically (only load tool definitions the agent needs this turn)
4. Compress step results from previous tool calls

### The Cost Math

```
Lean (5K tokens/msg)   → Claude Opus: $0.025/msg
Bloated (50K tokens/msg) → Claude Opus: $0.25/msg   ← 10x more
Over 100 msgs/day: $2.25/day vs $22.50/day
```

### Built-In Defenses

**Session Pruning** - Trims old tool results from context:

```json
{
  "agents": {
    "defaults": {
      "contextPruning": { "mode": "cache-ttl", "ttl": "5m" }
    }
  }
}
```

**Auto-Compaction** - Summarizes older conversation when nearing context limits. Trigger manually with `/compact`.

> **2026.4.15 fix:** The compaction reserve-token floor is now capped at the model's actual context window. Before this, compaction on a 16K-token local model could request a larger reserve than the window itself, creating an infinite "try to free N tokens, fail, retry" loop. If you run small local models as compaction workers, upgrade — this is the fix you want. See [Part 15](./part15-infrastructure-hardening.md).

### Appendix — The 5-Minute Prompt Cache TTL Trap (March 2026)

Silent production killer that caught most teams in April 2026: **Anthropic's prompt-cache default TTL dropped from 1 hour to 5 minutes** sometime in early March 2026, without a release note most operators noticed. See the writeup *[Claude API Prompt Caching: Cut Costs 80% on Every Repeated Request](https://dev.to/whoffagents/claude-api-prompt-caching-cut-costs-80-on-every-repeated-request-1ap6)* (Apr 14, 2026).

If you built your SOUL/AGENTS/MEMORY context assuming a 1-hour cache, you're now paying **full token price on every sub-5-minute gap** between messages. For an orchestrator running one session at a time with users stopping to think between turns, the cache is essentially never hit. Bills silently tripled.

**Symptom:** Your Anthropic bill is up 2–4× month-over-month; token counts haven't changed.

**Fix (OpenClaw).** Set the cache TTL explicitly on any prompt segment that should live longer than 5 minutes:

```json
{
  "agents": {
    "defaults": {
      "prompts": {
        "cacheControl": {
          "soul":     { "type": "ephemeral", "ttl": "1h" },
          "agents":   { "type": "ephemeral", "ttl": "1h" },
          "memory":   { "type": "ephemeral", "ttl": "1h" },
          "skills":   { "type": "ephemeral", "ttl": "5m" }
        }
      }
    }
  }
}
```

The hot-path files (SOUL, AGENTS, MEMORY) are stable within a session, so pin their TTL to `1h`. Skills and dynamic context stay at 5m — they change too often to be worth extending.

> Anthropic considers 1h-cached blocks billable, just at ~1/10 the rate of uncached tokens. Worth the trade for anything that's reused more than twice an hour.

**Use both.** Pruning handles tool result bloat. Compaction handles conversation history bloat.

### Context Bloat Checklist

- [ ] Workspace files under 8 KB total
- [ ] Context pruning enabled (`mode: "cache-ttl"`)
- [ ] Use `/compact` proactively when sessions feel slow
- [ ] Use `/new` when switching topics entirely
- [ ] Delegate heavy tool work to sub-agents (their context is separate)
- [ ] Monitor with `/status` - stay under 10-15% of your model's context window

---

## Part 3: Cron Session Bloat (The Hidden Killer)

> **Read this if** you run cron jobs, the `sessions/` folder is huge, or you've ever wondered why a background agent gets slower week over week.
> **Skip if** you don't use cron / scheduled agents.

Every cron job creates a session transcript file (`.jsonl`). Over time:

- **30 cron jobs × 48 runs/day × 30 days = 43,200 session files**
- The `sessions.json` index balloons, slowing session management

### How to Spot It

```bash
# Linux/Mac
ls ~/.openclaw/agents/*/sessions/*.jsonl | wc -l

# Windows (PowerShell)
(Get-ChildItem ~\.openclaw\agents\*\sessions\*.jsonl).Count
```

Thousands of files = cron session bloat.

### The Fix

**1. Configure session rotation:**

```json
{ "session": { "maintenance": { "rotateBytes": "100mb" } } }
```

**2. Clean up old sessions:**

```bash
openclaw sessions cleanup
```

**3. Use isolated sessions for cron:**

```json
{ "sessionTarget": "isolated", "payload": { "kind": "agentTurn", "message": "Do the thing" } }
```

Isolated sessions don't pile up in your main agent's session history.

### Prevention > Cleanup

- Use `delivery: { "mode": "none" }` on crons where you don't need output announced
- Keep cron tasks focused - 1 tool call generates 15x less session data than 15

---

## Part 4: Memory (Stop Forgetting Everything)

> **Read this if** you want the 3-tier memory model (MEMORY.md + session files + vector search) from scratch. This is the foundation for Parts 9, 10, 11, 12, 13, 22.
> **Skip if** you're already running memory-core with a local embedding provider and a vault — skim for the 2026.4.15 `memory_get` / lancedb-cloud changes and move on.

Out of the box, OpenClaw forgets everything between sessions. The fix is a 3-tier memory system.

### The Architecture

```
MEMORY.md          ← Slim index (< 3 KB), pointers only
memory/            ← Auto-searched by memory_search()
  projects.md
  people.md
  decisions.md
vault/             ← Deep storage, searched via memory
  projects/
  people/
  decisions/
  lessons/
  reference/
  research/
```

### How It Works

1. **MEMORY.md** - table of contents with one-liner pointers. Never put full documents here.
2. **memory/*.md** - automatically searched when the bot calls `memory_search("query")`.
3. **vault/** - deep storage for detailed project docs, research notes, full profiles.

### Setting It Up

**Step 1: Install Ollama + embedding model**

```bash
# Windows: winget install Ollama.Ollama
# Mac/Linux: curl -fsSL https://ollama.com/install.sh | sh
ollama pull nomic-embed-text
```

OpenClaw detects Ollama on localhost:11434 automatically. No config needed.

> **GPU users:** For a major quality upgrade (768-dim → 4096-dim vectors), see [Part 10: State-of-the-Art Embeddings](./part10-state-of-the-art-embeddings.md).

**Step 2: Create the directory structure**

```
workspace/
  MEMORY.md
  memory/
  vault/
    projects/  people/  decisions/  lessons/  reference/  research/
```

**Step 3: Slim down MEMORY.md**

```markdown
# MEMORY.md - Core Index
_Pointers only. Search before answering._

## Active Projects
- Project A → vault/projects/project-a.md

## Key Tools
- Tool X: `command here`

## Key Rules
- Rule 1
```

**Step 4: Move everything else to vault/**

Every detailed document → vault/. Leave a one-liner pointer in MEMORY.md or memory/.

**Step 5: Set up memory consolidation**

Session memory files pile up fast — 200+ files in a month. OpenClaw 2026.4+ has built-in dreaming ([Part 22](#part-22-built-in-dreaming)) — enable it in memory-core config and it auto-consolidates on a daily schedule. (Pre-2026.4 installs used to need the custom "autoDream" AGENTS.md pattern described in the retired Part 16; that file is gone — upgrade to 2026.4+ and use built-in dreaming instead.)

> **Security note (2026.4.15):** `memory_get` is now restricted to canonical memory files — MEMORY.md and DREAMS.md. It no longer reads arbitrary files from the workspace by path. If you were doing `memory_get("vault/projects/x.md")` directly, switch to `memory_search` or a plain file read — the dedicated memory tool is strictly for the canonical agent indexes now. This closes a path-traversal vector that the `memory-qmd` backend allowed before.

> **Context budget change (2026.4.15 stable):** `memory_get` now caps excerpt length by default and returns explicit **continuation metadata** instead of dumping entire files into context. If an excerpt was truncated, the tool response includes a follow-up cursor the agent can use to fetch the next chunk deterministically. On top of that, default startup and skills prompt budgets were trimmed — long sessions pull less context by default without losing deterministic follow-up reads. Practical effect: your MEMORY.md and DREAMS.md can grow without silently blowing up every reply. If you had custom skills that assumed `memory_get` returns the whole file, update them to respect the continuation cursor (it's noisy but one-line).

### The Golden Rule

Add this to your SOUL.md:

```markdown
## Memory
Before answering about past work, projects, or decisions:
run memory_search FIRST. It costs 45ms. Not searching = wrong answers.
```

---

## Part 5: Orchestration (Stop Doing Everything Yourself)

> **Read this if** you do anything non-trivial — research, coding, long tasks — in a single interactive agent and haven't set up sub-agent workers, verification, or the Ralph loop yet.
> **Skip if** you're already running CEO/COO/Worker with PreCompletionChecklist verification.

### Sub-Agents Are Context Garbage Collection (Not A Speed Hack)

The mistake most teams make with sub-agents: treating them as a *performance* trick ("run two things in parallel = 2x speed"). That misses the point. The week of April 10–17, 2026 had five independent writeups ([heyuan110 Apr 13](https://www.heyuan110.com/posts/ai/2026-04-13-harness-subagent-architecture/), [Builder.io Apr 16](https://www.builder.io/blog/claude-code-subagents), and three more on DEV) all converging on the same reframe: **sub-agents are context garbage collection.**

The real unlock: a sub-agent is a disposable context window. You spawn one, it burns 40K tokens searching the codebase, it returns a 500-token summary, the sub-agent's context is thrown away. Your main agent's context stays lean. Without sub-agents, that 40K of search noise would permanently live in your main context, degrading every subsequent turn.

**The 3-trigger decision table — spawn a sub-agent if *any* of these are true:**

| Trigger | What it looks like | Why you spawn |
|---------|---------------------|----------------|
| **Wide search scope** | "find every usage of X", "how does auth work across the codebase", "read all related files" | The search is most of the tokens. Don't bring them home. |
| **10+ edit targets** | Renaming across many files, systematic refactors, bulk migrations | Each edit call is noise once it's done. Worker commits, reports hash, done. |
| **Independent verification** | "does the code actually compile", "do the tests pass", "is this PR complete" | You want a fresh pair of eyes with no bias from the implementation conversation. |

If none of those are true, **don't spawn**. Sub-agent invocation has real overhead — cold-start prompts, tool-registration roundtrips, summarization cost. Use them surgically, not reflexively.

Your main model should NEVER do heavy work directly. It should plan and delegate to cheaper, faster sub-agents — per the triggers above.

### Anthropic's Five Multi-Agent Coordination Patterns (Apr 10, 2026)

On April 10, 2026, Anthropic published *[Multi-Agent Coordination Patterns](https://claude.com/blog/multi-agent-coordination-patterns)* — the first canonical naming of the patterns the community had been reinventing. The taxonomy is now the lingua franca for how agents work together. Use it. Old internal names ("CEO/COO/Worker", "critic loop") still map to these.

| Pattern | When you pick it | OpenClaw realization |
|---------|------------------|----------------------|
| **Generator-Verifier** | Output correctness matters more than latency (code, plans, architecture decisions) | Spawn worker to produce, spawn fresh worker to verify. No shared context. |
| **Orchestrator-Subagent** | Main agent holds strategy, workers execute narrow tasks | The classic. What Part 5 started as. |
| **Agent Teams** | Bounded problem with clearly separate roles (researcher + writer + editor) | Each team member is its own persistent thread via ACP. |
| **Hierarchical** | Truly large task trees, multiple layers of delegation | Rare. When you need it, Task Brain's parent-child ledger is how you keep it sane. |
| **Network** | Peer agents passing tasks to each other without a central orchestrator | Spicy. Only use with strong approval gates. Most failures live here. |

```mermaid
flowchart LR
    Q{Task shape?}
    Q -->|"Output correctness critical"| GV[Generator-Verifier]
    Q -->|"Clear strategy + narrow execute"| OS[Orchestrator-Subagent]
    Q -->|"Distinct roles, bounded"| AT[Agent Teams]
    Q -->|"Deep task tree"| HI[Hierarchical]
    Q -->|"Peer-to-peer flow"| NET[Network — careful]
```

**Default picks for an OpenClaw operator:** Orchestrator-Subagent for 80% of work, Generator-Verifier for code and decisions, Agent Teams for long research loops, Hierarchical when Task Brain flows nest 3+ levels deep, Network almost never.

The [Ralph Loop (Part 30)](./part30-ralph-loop-in-openclaw.md) is a specific flavor of Orchestrator-Subagent where the orchestrator is an outer bash wrapper and every iteration is a fresh agent session.

Your main model should NEVER do heavy work directly. It should plan and delegate to cheaper, faster sub-agents.

### The Mental Model

- **You** = CEO (gives direction)
- **Your Bot (main model)** = COO (plans, coordinates, makes decisions)
- **Sub-agents (cheaper/faster model)** = Workers (execute tasks fast and cheap)

### Add This to AGENTS.md

```markdown
## Core Rule
You are the ORCHESTRATOR. You coordinate; sub-agents execute.
- Code task (3+ files)? → Spawn coding agent
- Research task? → Spawn research agent
- 2+ independent tasks? → Spawn ALL in parallel

## Model Strategy
- YOU (orchestrator): Best model - planning, judgment, synthesis
- Sub-agents (workers): Cheaper/faster model - execution, code, research
```

> **2026.3.31-beta.1+ — every spawn is a Task Brain flow.** Sub-agents, ACP runs, and cron jobs all flow through the same unified task flow registry now (`openclaw flows list`). Semantic approval categories (`execution.*`, `read-only.*`, `control-plane.*`) replace the old name-based allowlist. If you're seeing unexpected "approval required" prompts on sub-agent spawns, check [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md) for how to configure categories and trust boundaries.

Your expensive model decides WHAT to build. The cheap model builds it. Right model, right job.

### PreCompletion Verification (from LangChain's +13.7 point harness improvement)

LangChain's coding agent went from outside the Top 30 to **Top 5 on Terminal Bench 2.0** by only changing the harness — not the model. Their #1 improvement: **force verification before exit.**

Add this to your AGENTS.md:

```markdown
## PreCompletion Verification
Before finishing ANY task, STOP and verify:
1. Re-read the user's original request
2. Compare your output against what was actually asked
3. If there's a gap, fix it before responding
4. For code: run tests — don't just re-read your own code and say "looks good"
```

Why this works: Agents are biased toward their first plausible solution. They write code, re-read it, say "looks good", and stop. Forcing a verification pass against the *original request* (not their own output) catches the gap.

**Also add loop detection:**
```markdown
## Loop Detection
If you edit the same file 5+ times without progress, STOP.
Step back, reconsider your approach entirely.
Don't make small variations to the same broken approach — that's a doom loop.
```

LangChain uses a `LoopDetectionMiddleware` that tracks per-file edit counts and injects "consider reconsidering your approach" after N edits. Simple but effective.

### Long-Running Projects (Multi-Session Work)

From [Anthropic's own engineering blog](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents): for projects spanning multiple sessions, use the **initializer + progress file** pattern:

```markdown
## Multi-Session Protocol
- Work on ONE feature at a time — don't one-shot everything
- Create/update a `progress.txt` in the project dir:
  - What's DONE (with dates)
  - What's IN PROGRESS (with blockers)
  - What's NEXT (prioritized)
- Start each session: read progress.txt → git log → run basic test → THEN start work
- End each session: commit with descriptive message, update progress.txt
```

Use JSON for feature tracking when you need structured state (model is less likely to accidentally modify JSON vs markdown). Anthropic found this solved two critical failure modes: agents trying to one-shot everything, and agents declaring victory too early.

### The Ralph Wiggum Loop (Autonomous Tasks)

Named after the Simpsons character, this is one of the most powerful patterns for overnight/autonomous agent work. Core idea: when an agent tries to stop, force it to keep working until tests actually pass.

```bash
# The original 5-line Ralph loop
while true; do
  cat prompt.md | claude --print | tee output.txt
  if ./run_tests.sh; then break; fi
done
```

The insight: agents love to declare "done" before work is actually done. External verification (tests, linters, type checkers) **can't lie** — the agent can. The loop forces build→test→fix cycles until reality matches expectations.

Add to your AGENTS.md for autonomous tasks:

```markdown
## Ralph Loop (Autonomous Tasks)
For overnight/unattended work:
- Don't trust "looks good" — run REAL tests
- Loop: implement → test → if fail → fix → test again
- Only done when tests ACTUALLY PASS
- 10+ iterations without progress → stop and report failure
```

**Common traps:** Loop never ends (criteria too strict), loop ends too early (agent fakes the completion promise), quality degrades over iterations (random changes hoping something sticks). Fix: strengthen verification to run BEFORE accepting the promise.

*Source: [ghuntley.com/loop](https://ghuntley.com/loop/), [Letta Code /ralph command](https://docs.letta.com/letta-code/ralph-mode/), [LangChain PreCompletionChecklistMiddleware](https://blog.langchain.com/improving-deep-agents-with-harness-engineering/)*

### The 4-Phase Coordinator Protocol (Advanced)

For complex multi-step tasks, use the coordinator pattern — originally reverse-engineered from the Claude Code / autoDream leak, now absorbed into built-in dreaming and sub-agent spawning:

| Phase | Who | Purpose |
|-------|-----|---------|
| **Research** | Workers (parallel) | Investigate codebase, find files, understand problem |
| **Synthesis** | Coordinator (you) | Read ALL findings, craft specific implementation specs |
| **Implementation** | Workers (parallel) | Execute specs, commit changes |
| **Verification** | Workers (parallel) | Test changes, prove they work |

**Key rules:**
- "Parallelism is your superpower" — launch independent workers concurrently
- Never say "based on your findings" — read the actual findings and write specific specs
- Workers can't see your conversation — every prompt must be self-contained
- Include a purpose statement: "This research will inform a PR — focus on user-facing changes"
- **Exclusive file ownership** (from [Zerg](https://zerg-ai.com/)): each worker's spec lists which files it owns. No two workers edit the same file. Eliminates merge conflicts entirely.
- Workers self-verify before reporting done: "Run tests and typecheck, then commit and report the hash"

**Continue vs Spawn fresh?**
| Situation | Action |
|-----------|--------|
| Worker researched the exact files to edit | Continue (has context) |
| Research was broad, implementation narrow | Spawn fresh (avoid noise) |
| Correcting a failure | Continue (has error context) |
| Verifying another worker's code | Spawn fresh (no bias) |

### Give Coding Agents Your Brain

**Codebase Intelligence (NEW — [Part 19](./part19-repowise-codebase-intelligence.md)):** Before spawning coding agents, use [Repowise](https://github.com/repowise-dev/repowise) to give them full codebase context — dependency graphs, git ownership, architectural decisions, dead code detection. 60% fewer tokens, 4x faster task completion. `pip install repowise && repowise init --path /project --index-only`

**Memory Bridge:** Before spawning any coding sub-agent, run the Memory Bridge preflight to inject relevant vault knowledge into the project directory:

```bash
node scripts/memory-bridge/preflight-context.js --task "Build auth middleware" --workdir ./my-project
```

This writes a `CONTEXT.md` that the coding agent reads automatically — giving it access to your past decisions, error patterns, and architecture choices. See [Part 13](./part13-memory-bridge.md) for the full setup.

---

## Part 6: Models (What to Actually Use)

> **Read this if** you're picking providers/models, debating local vs. cloud, or you want an opinionated cost/latency matrix for 2026-era models.
> **Skip if** you have a provider mix you're happy with and your bills are sane.

### The Model Strategy

| Role | What It Does | Best Model(s) | Why |
|------|-------------|----------------|-----|
| **Orchestrator** | Plans, judges, coordinates | Claude Opus 4.7 | Best complex reasoning + tool use (new default in 2026.4.15) |
| **Sub-agents** | Execute delegated tasks | Kimi K2.5, MiMo V2 Pro, Gemini Flash | Fast, cheap, capable enough |
| **Infrastructure** | Compaction, fallbacks, bulk work | Cerebras gpt-oss-120b | $0.60/M, 3000 tok/s, reliable |
| **Knowledge Graph RAG** | Entity extraction, graph queries | Cerebras qwen-3-235b | 1400 tok/s, high accuracy for entity extraction |
| **Coding (hard)** | Architecture, complex bugs | Claude Opus 4.7 | Top SWE-bench — the new Anthropic default as of 2026.4.15 |
| **Coding (batch)** | Scaffolding, CRUD, refactors | GPT-5.4 Codex | Fast, $0 on subscription, good with Memory Bridge |
| **Research** | Web search, analysis | Kimi K2.5 + Tavily | Cheap, fast, good at research synthesis |
| **Local inference** | $0 forever, private, no rate limits | QwOpus (27B), TerpBot (Nemotron 30B), Nemotron Nano 4B | Ollama on any GPU |
| **Free tier** | Zero-cost operations | Gemini (all variants), Cerebras free tier, OpenRouter free models | $0 with generous limits |

### Model Deep Dive

**Claude Opus 4.7** - The Best Orchestrator (new default in 2026.4.15)
- Unmatched multi-step reasoning and complex tool use
- Follows long, nuanced system prompts better than any other model
- 1M context window with prompt caching (up to 90% savings on cached tokens)
- **Cost:** $5/M input, $25/M output, $0.50/M cached | **Max ($100/mo):** included - best value for heavy use

**Claude Sonnet 4** - Solid Workhorse
- 80% of Opus quality at 20% of the cost. Strong at coding.
- **Note:** Some power users (including the author) have dropped Sonnet entirely in favor of Opus for orchestration + Cerebras/Gemini for sub-agents. The quality gap matters when your agent makes architectural decisions.
- **Cost:** $3/M input, $15/M output | **Pro ($20/mo):** included

**Cerebras gpt-oss-120b** - Infrastructure Workhorse
- 3000 tok/s, $0.60/M input+output. Perfect for compaction, fallbacks, and bulk work where speed matters more than nuance.
- Free tier: 1M tokens/day (insufficient for heavy use, but good for testing).
- We use this as the fallback for every agent and as the compaction model.
- **⚠️ Don't use for knowledge graph entity extraction** — hallucination risk is too high for memory-critical tasks. Use Qwen3 235B instead (still 1400 tok/s on Cerebras, much more accurate).

**Cerebras qwen-3-235b** - Knowledge Graph & Quality Tasks
- 1400 tok/s, still faster than most providers serve 8B models.
- Use for: LightRAG entity extraction, complex analysis, anything where accuracy matters more than raw speed.
- The 235B beats 120B on structured extraction tasks where hallucinated relationships would poison your knowledge graph.

> **💡 Pro tip:** Don't pay API rates for Claude if you have a subscription. Pro ($20/mo) covers Sonnet, Max ($100/mo) covers Opus. For power users, Max is the best value in AI right now.

**Gemini 3.1 Pro / 3 Pro** - Free Powerhouse
- Competitive with Sonnet on most tasks - and it's free. 1M context, multimodal.
- Weaker than Claude on complex agentic tool-use chains.

**Gemini Flash (2.5 / 3)** - Speed Demon
- Fastest responses of any capable model. Perfect for sub-agents. Free.

**GPT-5.3 / 5.4 Pro** - OpenAI's Best
- Codex models are purpose-built for code - fast and cheap.
- **Cost:** GPT-5.3: $1.75/M input, $14/M output | GPT-5.4 Pro: $30/M input, $180/M output

**Grok 4 / 4.1 Fast** - The Dark Horse
- Grok 4.20 has a massive 2M context window. Grok 4.1 Fast is insanely cheap.
- **Cost:** Grok 4: $3/M in, $15/M out | Grok 4.1 Fast: $0.20/M in, $0.50/M out

**Kimi K2.5** - Budget Sub-Agent King
- 262K context, multimodal, $0.45/M input, $2.20/M output - excellent price-to-performance.

**MiMo V2 Pro (Xiaomi)** - The Sleeper
- 1T parameter model, 1M context. Great for agentic sub-agents on a budget. $1/M in, $3/M out.

### OpenRouter: The Model Marketplace

[OpenRouter](https://openrouter.ai) gives you dozens of models through one API key. Notable options:

- **`openrouter/free`** - auto-routes to the best free model for your request. Perfect for $0 sub-agents.
- **MiMo V2 Pro** - Currently free (launch promotion). Add: `openrouter/xiaomi/mimo-v2-pro`
- **Kimi K2.5** - Budget powerhouse. Add: `openrouter/moonshotai/kimi-k2.5`
- **Perplexity Sonar** - Built-in web search, no separate tool needed. Add: `openrouter/perplexity/sonar`

### Local Models: $0 Forever, No Rate Limits

If you have a GPU, local models via Ollama = unlimited inference at zero cost.

- **QwOpus (Qwen 3.5 27B + Opus reasoning distilled)** - Opus-style thinking locally. 63 tok/s on RTX 5090, 1M context with Q4 KV cache. `ollama pull qwopus`
- **TerpBot (Nemotron 30B fine-tuned)** - Custom fine-tune on clean 9.4K examples. 235 tok/s on 5090, 91.93% MMLU-Pro Math. Not public — but Nemotron 30B base is: `ollama pull nemotron-30b`
- **NVIDIA Nemotron Nano 4B** - Punches above its weight, 128K context, fits on any GPU. `ollama pull nemotron-nano`

> **2026.4.15 — if you drive a small local model, turn on `localModelLean`.** Set `agents.defaults.experimental.localModelLean: true` and the gateway stops injecting the heavyweight default tools (browser, cron, message) into the system prompt. You keep `memory_search`, `exec`, `sessions_spawn` — i.e. the tools a local model can actually *use*. Frees ~3KB of prompt, which on a 16K-context 14B model is the difference between "fits one retrieval result" and "crashes out of context." Leave this off for frontier models — you want them to have everything.

### Using Anthropic Membership (The Best Way)

Your Claude Pro/Max subscription includes API access. OpenClaw can use it directly:

```
1. Run `claude` in terminal → login via browser (OAuth)
2. Run `openclaw onboard` → detects your credentials → uses membership
3. Done. No separate API key needed.
```

### Recommended Setups

**Budget ($0/month):**
```
Main: Gemini 3.1 Pro (free tier) | Sub-agents: Gemini Flash (free tier) | Local: Qwen 3.5 Opus Distilled
```

**Balanced (~$20/month - Claude Pro):**
```
Main: Sonnet 4 (membership) | Fallback: Gemini 3.1 Pro | Sub-agents: MiMo V2 Pro / Kimi K2.5
```

**Power (~$100/month - Claude Max):**
```
Main: Opus 4.7 (membership) | Fallback: Gemini 3.1 Pro | Sub-agents: Kimi / MiMo / Flash
Code (hard): Opus directly | Code (batch): Codex + Memory Bridge
Self-improving: .learnings/ micro-loop ($0) | Memory: Qwen3-Embedding-8B on local GPU
Knowledge Graph: LightRAG + Cerebras qwen-3-235b (Part 18)
Codebase Intel: Repowise (Part 19) | Observability: LangFuse (Part 20)
```

### Pro Tips

- **Always set 2-3 fallbacks.** Auto-switch beats breaking.
- **Match model to task.** Don't use Opus for scripts. Don't use Flash for architecture.
- **Enable prompt caching** on Anthropic: `cacheRetention: "extended"` + cache-ttl pruning.
- **Membership > API keys.** If you're paying for Pro/Max, use it via OAuth. Don't pay twice.
- **Free models are real.** Gemini's free tier is legitimately good for daily driving.
- **Watch the Model Auth card (new 2026.4.15).** Control UI now shows per-provider OAuth token health and rate-limit pressure. Before a big run, eyeball it — catching an expiring Claude Max token or a rate-limited Gemini key there beats debugging mid-task.

---

## Part 7: Web Search (Give Your Agent Eyes on the Internet)

> **Read this if** your agent needs fresh web data and you haven't picked a search provider, or you're using Gemini grounding and it's failing silently.
> **Skip if** your agent doesn't need web search, or you already have Tavily/Brave/Serper wired in.

Without web search, your agent guesses at anything after its training cutoff.

### The Players

| Provider | Price per 1K queries | Free Tier | Best For | LLM-Optimized |
|----------|---------------------|-----------|----------|----------------|
| **Tavily** | ~$8 | 1,000/month | AI agents, RAG | ✅ Built for it |
| **Brave Search** | $5 | $5 credit/month | Privacy, scale | ✅ LLM Context mode |
| **Serper** | $1-3 | 2,500 credits | Budget, speed | Partial |
| **SerpAPI** | $25-75/month | 100/month | Multi-engine | Partial |
| **Gemini Grounding** | Free | Included | Google ecosystem | ✅ Native |
| **Perplexity Sonar** | $3/M in, $15/M out | Via OpenRouter | Research synthesis | ✅ Built for it |

### Why We Use Tavily

1. **Built for AI agents.** Returns clean, structured, pre-processed content - not a list of links. One API call → usable answer. No fetching/parsing extra steps.
2. **Search + Extract + Crawl in one API.** Fewer tools, fewer context-eating tool calls.
3. **Depth control.** Basic (1 credit, fast) vs Advanced (2 credits, comprehensive) - per query.
4. **Usable free tier.** 1,000 credits/month = enough for a personal assistant that searches a few times daily.
5. **Built-in safety.** Guards against prompt injection from search results and PII leakage.

### Setting Up Tavily

1. Get a free API key at [tavily.com](https://tavily.com) (30 seconds)
2. Add to TOOLS.md: `Tavily Search: For grounded web research. Basic for lookups, advanced for deep research.`
3. For research sub-agents, include Tavily in task instructions

### When to Use What

| Need | Use |
|------|-----|
| Real-time facts/news | Tavily (basic) or Gemini grounding |
| Deep research + full articles | Tavily (advanced + extract) |
| Privacy-first search | Brave Search API |
| Structured results, budget | Serper ($1/1K) |
| Search in model response | Perplexity Sonar |
| Free and good enough | Gemini grounding |

---

## Part 8: One-Shotting Big Tasks (Stop Iterating, Start Researching)

> **Read this if** your agent keeps iterating on big tasks (refactors, migrations, research) and producing half-baked results.
> **Skip if** your tasks are small and iterative-by-design (REPLs, ad-hoc queries).

Most people type a vague prompt, iterate 15 times, burn context and money, end up at 60% quality. **The model isn't the problem - your prompt is.**

### The Data

- Vague prompts → **1.7x more issues**, **39% more cognitive complexity**, **2.74x more security vulnerabilities**
- Detailed specifications → **95%+ first-attempt accuracy**

**The quality of your output is capped by the quality of your input.**

### Why Iteration Fails

1. **Burns context** - each correction adds to history, pushing toward bloat
2. **Confuses the model** - contradictory instructions across rounds
3. **Pays twice** - you paid for the bad output AND the correction
4. **Loses coherence** - by iteration 8, the agent forgot iteration 1 (lost-in-the-middle)

### The Method: Research → Spec → Ship

#### Phase 1: Research (30-60 minutes)

Before building, know what "good" looks like:

1. **Find best examples** - Search for top 3-5 implementations, study their tech stack and shared features
2. **Analyze UI patterns** - Screenshot the best UIs, note layouts, color schemes, component patterns
3. **Study the tech stack** - Pick the stack the best implementations use, not your default
4. **Find the pitfalls** - Search for common mistakes. Every pitfall in your prompt = one fewer iteration

#### Phase 2: Write the Spec (15-30 minutes)

Turn research into a blueprint:

```markdown
# Project: [Name]

## Context
[What this is, who it's for, why it exists]

## Research Summary
[Key findings - what the best implementations do]

## Tech Stack
- Framework: [choice based on research]
- UI Library: [choice]
- Key Dependencies: [list]

## Features (Priority Order)
1. [Feature] - [acceptance criteria]
2. [Feature] - [acceptance criteria]

## File Structure
[Project organization]

## Quality Bar
- [ ] Responsive, error handling, loading states
- [ ] Clean code, no TODOs in final output

## What NOT To Do
- [Pitfall from research]
```

**Why this works:** You're not asking the AI to make 50+ decisions - you've already made them based on research. The AI executes, not strategizes. Blueprints, not vibes.

#### Phase 3: Delegate and Ship

Send the spec to a **coding agent**, not your orchestrator:

```
sessions_spawn({
  task: "[full spec]",
  mode: "run",
  runtime: "subagent"  // or "acp" for Codex/Claude Code
})
```

- **Run Memory Bridge preflight first.** Before spawning any coding agent, inject vault context:
  `node scripts/memory-bridge/preflight-context.js --task "..." --workdir <project>`
  This writes a CONTEXT.md with relevant past decisions and patterns. See [Part 13](./part13-memory-bridge.md).
- **Send to a coding model.** Your main model plans, not builds. For hard architecture work, Opus can code directly (#1 SWE-bench).
- **Include everything in one prompt.** If you're thinking "I'll clarify later," you haven't researched enough.
- **Attach reference images** for vision-capable models.

### Let Your Agent Do the Research

You don't have to research manually - make your agent do Phase 1:

```
Before building anything, research first:
1. Find top 5 [things] that exist. What tech/UI patterns do they share?
2. Search "[thing] best practices 2026" - summarize key patterns.
3. Search "[thing] common mistakes" - list top pitfalls.
4. Based on research, write a detailed spec with tech stack, features,
   file structure, and quality bar.
Do NOT start building until the spec is written and I approve it.
```

**The workflow:**

```
You: "Research and spec out a [thing]"     → 2 min
Agent: [Tavily research → writes spec]     → 3-5 min
You: "Looks good, build it"                → 30 sec
Agent: [builds from spec]                  → one-shot quality
```

5 minutes of research saves 3+ hours of iteration. The math always works out.

---

## Part 9: Vault Memory System (Stop Losing Knowledge Between Sessions)

> **Read this if** Part 4's flat memory works but the agent is getting dumber the more you teach it, or you have 200+ memory files and search returns noise.
> **Skip if** you have fewer than ~50 memory files — stay on the basics from Part 4 until you hit the wall.

Part 4 gave you memory. But after months of daily use, **your agent gets dumber, not smarter.** We hit this: 358 memory files, 100MB+ of accumulated knowledge, vector search returning irrelevant results because every query matches 15 slightly different files. Date-named files that tell you nothing. Research conclusions lost because nobody saved them.

**The more you teach it, the worse it gets.** That's the sign your memory architecture is broken.

### Why Flat Files + Vector Search Breaks Down

Vector search finds what's *similar* - not what's *connected*. Ask "what do we know about God Mode?" and you get 8 files that all mention Cerebras. None give the full picture because it's spread across 12 files that vector search doesn't know are related.

| Problem | What Happens |
|---------|-------------|
| **Date-named files** | `2026-03-19.md` - what's in it? Who knows |
| **No connections** | Related files don't know about each other |
| **Bloat pollutes results** | Generic knowledge drowns specific insights |
| **Session amnesia** | Agent starts fresh, no breadcrumbs from last session |
| **MEMORY.md overflow** | Index grows past injection limit, context truncated |

**The fix isn't better embeddings. It's structure.**

### The Solution: Vault Architecture

An Obsidian-inspired linked knowledge vault with four key ideas:

1. **Notes named as claims** - the filename IS the knowledge
2. **MOCs (Maps of Content) link related notes** - one page = full picture
3. **Wiki-links create a traversable graph** - follow connections, not similarity
4. **Agent Notes provide cross-session breadcrumbs** - next session picks up where this one left off

#### Folder Structure

```
vault/
  00_inbox/      ← Raw captures. Dump here, structure later
  01_thinking/   ← MOCs + synthesized notes
  02_reference/  ← External knowledge, tool docs, API references
  03_creating/   ← Content drafts in progress
  04_published/  ← Finished work
  05_archive/    ← Inactive content. Never delete, always archive
  06_system/     ← Templates, vault philosophy, graph index
```

#### Claim-Named Notes

Stop naming files by date. Name them by what they claim:

```
BAD:  2026-03-19.md              GOOD: nemotron-mamba-wont-train-on-windows.md
BAD:  session-notes.md           GOOD: memory-is-the-bottleneck.md
BAD:  cerebras-research.md       GOOD: god-mode-is-cerebras-plus-orchestration.md
```

The agent reads filenames before content. When every filename is a claim, scanning a folder gives the agent a map of everything you know - without opening a single file.

#### MOCs - Maps of Content

A MOC connects related notes with `[[wiki-links]]`. Example:

```markdown
# Memory Is The Bottleneck

## Key Facts
- 358 memory files in memory/, mostly date-named
- Vector search (qwen3-embedding or nomic-embed-text, ~45ms local, $0) finds similar, not connected
- MEMORY.md must stay under 5K - injected on every message

## Connected Topics
- [[vault/decisions/memory-architecture.md]]
- [[vault/research/rag-injection-research.md]]
- [[vault/projects/reasoning-traces.md]]

## Agent Notes
- [x] Vault restructure completed - 8 MOCs + philosophy doc
- [ ] Every session MUST save knowledge to memory
```

The `## Agent Notes` section is the cross-session breadcrumb trail. Each session updates these notes; the next session reads them and picks up where the last one stopped.

#### Vault Philosophy Document

Save to `vault/06_system/vault-philosophy.md` - this teaches your agent HOW to use the vault:

1. **The Network Is The Knowledge** - No single note is the answer. The answer is the path through connected notes.
2. **Notes Are Named As Claims** - Bad: `local-models.md`. Good: `local-models-are-the-fast-layer.md`.
3. **Links Woven Into Sentences** - Not footnotes. Context-rich inline links.
4. **Agent Orients Before Acting** - Scan MOCs → read relevant MOC → follow links → respond.
5. **Agent Leaves Breadcrumbs** - Update MOC "Agent Notes" after every session.
6. **Capture First, Structure Later** - Dump in `00_inbox/` now. Organize later.

### The Graph Tools

MOCs and wiki-links create a graph, but the agent needs tooling to traverse it. See `scripts/vault-graph/` for the complete tools:

| Script | Purpose |
|--------|---------|
| `graph-indexer.mjs` | Scans all `.md` files, parses `[[wiki-links]]`, builds JSON adjacency graph |
| `graph-search.mjs` | CLI for traversing the graph - finds files + direct/2nd-degree connections |
| `auto-capture.mjs` | Creates claim-named notes in `00_inbox/`, auto-links to related MOCs |
| `process-inbox.mjs` | Reviews inbox notes and suggests/auto-moves to appropriate vault folders |
| `update-mocs.mjs` | Health check - finds broken wiki-links, stale items, orphaned notes |

**Graph search vs vector search:**
- `memory_search("topic")` → Find files you didn't know were relevant (similarity)
- `node scripts/vault-graph/graph-search.mjs "topic"` → Navigate files you know are connected (structure)

Use both. Vector search discovers; graph search navigates.

### The Orientation Protocol

Add to your `AGENTS.md`:

```markdown
## Vault Orientation Protocol
1. Scan `vault/01_thinking/` - read MOC filenames (claim-named = instant topic map)
2. If user message relates to an existing MOC, read it before responding
3. Follow [[wiki-links]] from the MOC for deeper context
4. After session work: update MOC "Agent Notes" with what was done/discovered
5. New knowledge → claim-named notes in `vault/00_inbox/`
```

This creates a cycle: orient → work → capture → update → next session orients from breadcrumbs.

### Kill the Bloat

If you have a `memory/knowledge-base/` full of generic reference material, move it:

```bash
mv memory/knowledge-base vault/05_archive/knowledge-base
```

Your primary search path (`memory/` + `vault/01_thinking/`) should contain only YOUR knowledge - not generic docs the agent could web search.

**Before:** "memory architecture" returns 15 results - 3 about your system, 12 generic RAG articles.
**After:** Same search returns 3 results - all about your actual system.

### Results

| Metric | Before (Flat Files) | After (Vault System) |
|--------|--------------------|--------------------|
| **Files** | 358 flat, date-named | 326 indexed, claim-named |
| **Search method** | Vector only | Graph traversal + vector |
| **Wiki-links** | 0 | 71 bidirectional |
| **MOC pages** | 0 | 8 in 01_thinking/ |
| **Cross-session memory** | None - starts fresh | Agent Notes breadcrumbs |
| **Knowledge capture** | Manual (usually forgotten) | auto-capture creates claim-named notes |
| **Search relevance** | 15 partial matches, 3 useful | 3 connected results via graph |

### Quick Setup

1. **Create vault structure:** `mkdir -p vault/{00_inbox,01_thinking,02_reference,03_creating,04_published,05_archive,06_system}`
2. **Create your first MOC** in `vault/01_thinking/` - name it as a claim, follow the template above
3. **Save vault philosophy** to `vault/06_system/vault-philosophy.md`
4. **Set up graph tools:** `mkdir -p scripts/vault-graph` - save the scripts from this repo
5. **Build initial graph:** `node scripts/vault-graph/graph-indexer.mjs`
6. **Add orientation protocol** to AGENTS.md
7. **Move bloat to archive:** `mv memory/knowledge-base vault/05_archive/knowledge-base`
8. **Rebuild graph:** `node scripts/vault-graph/graph-indexer.mjs`

---

## Part 14: Quick Checklist

> **Read this if** you want a single printable page of everything else in the guide, for reviewing an install or onboarding a teammate.
> **Skip if** you're reading the guide linearly — this will repeat what you just read.

Run through this in 30 minutes:

- [ ] MEMORY.md under 3 KB (pointers only)
- [ ] SOUL.md under 1 KB
- [ ] AGENTS.md under 2 KB
- [ ] Total workspace context under 8 KB
- [ ] Context pruning enabled (`mode: "cache-ttl"`)
- [ ] Cron sessions cleaned up / isolated sessions configured
- [ ] Ollama installed + embedding model pulled (`qwen3-embedding:0.6b` recommended, see Part 10 for tiers)
- [ ] vault/ directory structure created
- [ ] Model strategy chosen (orchestrator + sub-agents + fallbacks)
- [ ] Faster/cheaper fallback model added
- [ ] Web search API configured (Tavily recommended, Gemini grounding for free)
- [ ] Unused plugins disabled
- [ ] Reasoning mode - high for best quality, low/off for speed
- [ ] Orchestration rules in AGENTS.md
- [ ] `memory_search` habit added to SOUL.md
- [ ] Vault orientation protocol in AGENTS.md
- [ ] For big tasks: research first, spec second, build third (Part 8)
- [ ] `.learnings/` directory created with HOT.md, corrections.md, ERRORS.md (Part 12)
- [ ] Micro-learning loop added to AGENTS.md (Part 12)
- [ ] Daily learnings promotion cron set up — $0 on Cerebras (Part 12)
- [ ] Memory Bridge scripts installed — `preflight-context.js` + `memory-query.js` (Part 13)
- [ ] AGENTS.md updated: run preflight before every Codex spawn (Part 13)
- [ ] Built-in dreaming enabled in memory-core config (Part 22) — replaces the retired custom autoDream pattern
- [ ] Config protection: "only ops writes openclaw.json" rule in all agent workspaces
- [ ] `.gitignore` in `.openclaw/` blocking `openclaw.json`, `auth-profiles.json`, `*.sqlite`
- [ ] Gateway crash-loop fix: stale PID cleanup in `gateway.cmd` (Part 15)
- [ ] PreCompletion verification rule in AGENTS.md (Part 5)
- [ ] Loop detection rule in AGENTS.md (Part 5)
- [ ] Multi-session projects: `progress.txt` pattern in AGENTS.md (Part 5)
- [ ] **Auto-capture hook installed** (NOT the built-in session-memory — the custom one from Part 11)
- [ ] Auto-capture API key set (CEREBRAS_API_KEY or AUTOCAPTURE_API_KEY env var)
- [ ] **Telegram/Discord users:** session rotation configured (manual `/new` daily or cron every 4h)
- [ ] **Telegram/Discord users:** session continuity rule in SOUL.md (don't announce resets)
- [ ] Temporal decay: 60 days for vault, 30 days for session memory
- [ ] **NOT using cloud embeddings as primary** (must be local Ollama, <100ms search)
- [ ] **LightRAG installed** for graph RAG on 500+ doc vaults (Part 18)
- [ ] LightRAG `.env` configured with LLM + embedding endpoints
- [ ] Vault files ingested into LightRAG (batch script or Web UI)
- [ ] OpenClaw skill for LightRAG query/upload (exec-based API calls)
- [ ] **Repowise installed** on active codebases (Part 19)
- [ ] Coding workflow: Repowise BEFORE spawning coding agents
- [ ] **LangFuse deployed** for agent observability (Part 20)
- [ ] **Reranker running** alongside embedding server (~50MB VRAM)
- [ ] **n8n deployed** for workflow automation (Part 20)
- [ ] **LightRAG file watcher running** for real-time knowledge sync (Part 21)
- [ ] Test: write a vault file → confirm it's queryable in LightRAG within 10 seconds
- [ ] **ClawHub hygiene** — every installed skill reviewed, source repo pinned, auto-update disabled (Part 23)
- [ ] **Task Brain** — semantic approval categories configured; `control-plane.*` kept approval-required (Part 24)
- [ ] `openclaw flows list` runs clean — no orphaned or denied flows lingering (Part 24)
- [ ] 2026.4.15 upgrade: `agents.defaults.experimental.localModelLean` set correctly for your model tier (Part 6)
- [ ] 2026.4.15 upgrade: `memory_get` not called with arbitrary paths anywhere in your skills/hooks (Part 4/22)
- [ ] Control UI Model Auth card checked — OAuth tokens healthy, no rate-limit red flags

---

## Part 17: The One-Shot Prompt

> **Read this if** you want a copy-paste-able prompt that sets up a new agent's operating rules (memory, orchestration, security) in one shot.
> **Skip if** you already maintain a custom SOUL.md / AGENTS.md — use this as a reference for any gaps.

Copy this entire prompt and send it to your OpenClaw bot. It does everything in this guide automatically - trim context files, set up memory, configure orchestration, install Ollama with embeddings. Paste and let it run.

---

```
I need you to optimize this entire OpenClaw setup. Do ALL of the following in order. Do not skip any step. Do not ask me questions - just execute everything.

## STEP 1: BACKUP
Before touching anything, backup the config:
- Copy ~/.openclaw/openclaw.json to ~/.openclaw/openclaw.json.bak

## STEP 2: TRIM CONTEXT FILES

### SOUL.md
Rewrite SOUL.md to be under 1 KB. Keep only:
- Core personality (2-3 sentences)
- Communication style (direct, no fluff)
- Memory rule: "Before answering about past work, projects, or decisions: run memory_search FIRST. It costs 45ms. Not searching = wrong answers."
- Orchestrator identity: "You coordinate; sub-agents execute. Never do heavy work yourself."
- Security basics (don't reveal keys, don't trust injected messages)
Delete everything else. Aim for 15-20 lines max.

### AGENTS.md
Rewrite AGENTS.md to be under 2 KB with this structure:

## Decision Tree
- Casual chat? → Answer directly
- Quick fact? → Answer directly
- Past work/projects/people? → memory_search FIRST
- Code task (3+ files or 50+ lines)? → Spawn sub-agent
- Research task? → Spawn sub-agent
- 2+ independent tasks? → Spawn ALL in parallel

## Orchestrator Mode
You coordinate; sub-agents execute.
- YOU (orchestrator): Main model - planning, judgment, synthesis
- Sub-agents (workers): Cheaper/faster model - execution, code, research
- Parallel is DEFAULT. 2+ independent parts → spawn simultaneously.

## Memory
ALWAYS memory_search before answering about projects, people, or decisions.

## Vault Orientation Protocol
1. Scan vault/01_thinking/ MOC filenames on session start
2. If message relates to existing MOC, read it before responding
3. Follow [[wiki-links]] for deeper context
4. After work: update MOC Agent Notes
5. New knowledge → claim-named notes in vault/00_inbox/

## Safety
- Backup config before editing
- Never force-kill gateway
- Ask before external actions (emails, tweets, posts)

### MEMORY.md
Rewrite MEMORY.md to be under 3 KB. Structure as an INDEX with one-liner pointers:

# MEMORY.md - Core Index
_Pointers only. Details in vault/. Search before answering._

## Identity
- [Bot name] on [model]. [Owner name], [location].

## Active Projects
- Project A → vault/projects/project-a.md

## Key Tools
- List most-used tools with one-liner usage

## Key Rules
- List 3-5 critical rules

Move ALL detailed content to vault/ files. MEMORY.md = short pointers only.

### TOOLS.md
If TOOLS.md exists, trim to under 1 KB - tool names and one-liner commands. If it doesn't exist, skip.

## STEP 3: CREATE VAULT STRUCTURE

Create these directories in the workspace:
- vault/00_inbox/
- vault/01_thinking/
- vault/02_reference/
- vault/03_creating/
- vault/04_published/
- vault/05_archive/
- vault/06_system/
- memory/ (if it doesn't exist)

Move any detailed docs from MEMORY.md into the appropriate vault/ subdirectory.

Create vault/06_system/vault-philosophy.md with these principles:
1. The Network Is The Knowledge - answers are paths through connected notes
2. Notes Named As Claims - filename IS the knowledge
3. Links Woven Into Sentences - not footnotes
4. Agent Orients Before Acting - scan MOCs → read → follow links → respond
5. Agent Leaves Breadcrumbs - update Agent Notes after every session
6. Capture First, Structure Later - dump in 00_inbox/, organize later

## STEP 4: INSTALL OLLAMA + EMBEDDING MODEL

Check if Ollama is installed:
- Try running: ollama --version
- If not installed:
  - Windows: winget install Ollama.Ollama
  - Mac: brew install ollama
  - Linux: curl -fsSL https://ollama.com/install.sh | sh

Pull the embedding model (pick ONE based on your hardware):
- **Most setups (recommended):** ollama pull qwen3-embedding:0.6b (best quality-to-size ratio, 1024 dims, 32K context, same family as MTEB #1 model)
- **32GB+ RAM or dedicated GPU:** ollama pull qwen3-embedding:4b (higher quality, ~3GB RAM)
- **RTX 3090+ or 5080+ with 16GB+ VRAM:** Use Qwen3-Embedding-8B via Fireworks or local vLLM (4096 dims, SOTA quality — see Part 10)
- **Low RAM or potato hardware:** ollama pull nomic-embed-text (768 dims, smallest footprint — noticeably worse quality)

Do NOT use cloud embeddings (Gemini, OpenAI, Voyage, Copilot) as your primary — 2-5 second round-trip latency per search vs <100ms local. Cloud embeddings defeat the entire purpose of fast memory search. (Copilot is new in 2026.4.15 — useful for corporate setups with existing Copilot seats, but still cloud-latency.)

## STEP 5: ADD FALLBACK MODEL

In openclaw.json, find your main agent config and add a fallback model. Use a faster/cheaper model from the same provider.

## STEP 6: DISABLE UNUSED PLUGINS

In openclaw.json, any plugin not actively used → set "enabled": false.

## STEP 7: SET UP SELF-IMPROVING SYSTEM (Part 12)

Create the learnings directory:
- workspace/.learnings/HOT.md (empty, header: "# HOT Learnings")
- workspace/.learnings/corrections.md (header: "# User Corrections Log")
- workspace/.learnings/ERRORS.md (header: "# Error Log")
- workspace/.learnings/LEARNINGS.md (header: "# General Learnings")
- workspace/.learnings/FEATURE_REQUESTS.md (header: "# Feature Requests")
- workspace/.learnings/projects/ (empty dir)
- workspace/.learnings/domains/ (empty dir)
- workspace/.learnings/archive/ (empty dir)

Add the micro-learning loop to AGENTS.md (insert before the decision tree):

### Micro-Learning Loop (EVERY MESSAGE — silent, <100 tokens)
After EVERY response, silently check:
  1. Did user correct me? → append 1-line to .learnings/corrections.md
  2. Did a command/tool fail? → append 1-line to .learnings/ERRORS.md
  3. Did I discover something? → append 1-line to .learnings/LEARNINGS.md
Format: "- [YYYY-MM-DD] what happened → what to do instead"

## STEP 8: ADD HARNESS ENGINEERING PATTERNS

Add these to AGENTS.md (insert before decision tree):

### PreCompletion Verification
Before finishing ANY task: re-read original request, compare output, fix gaps. For code: run tests.

### Loop Detection  
If editing same file 5+ times without progress, STOP and reconsider approach entirely.

### Multi-Session Projects
One feature at a time. Create progress.txt (done/in-progress/next). Start sessions by reading it.

## STEP 9: SET UP MEMORY CONSOLIDATION

**OpenClaw 2026.4+ (recommended):** Enable built-in dreaming in openclaw.json:
```json
{
  "plugins": {
    "entries": {
      "memory-core": {
        "config": {
          "dreaming": {
            "enabled": true
          }
        }
      }
    }
  }
}
```
That's it. Dreaming runs daily at 3am automatically. See Part 22 for full config.

**Older versions (< 2026.4):** Upgrade. The custom autoDream AGENTS.md pattern that used to live in Part 16 has been retired — the built-in Dreaming system is a drop-in replacement and is actively maintained. See [Part 26 — Migration Guide](./part26-migration-guide.md) for the upgrade path.

## STEP 10: CONFIG PROTECTION + SECURITY

Add to AGENTS.md in every agent workspace:
"You are NOT allowed to write openclaw.json. Only the ops agent can. Propose changes as a message."

Create .gitignore in ~/.openclaw/:
```
openclaw.json
openclaw.json.*
auth-profiles.json
*.sqlite
agents/*/sessions/*.jsonl
```

## STEP 11: INSTALL MEMORY BRIDGE (Part 13)

Clone or copy the Memory Bridge scripts:
- git clone https://github.com/OnlyTerp/memory-bridge.git scripts/memory-bridge
- Or manually create scripts/memory-bridge/memory-query.js and preflight-context.js

Add to AGENTS.md coding workflow: "Before spawning Codex, run: node scripts/memory-bridge/preflight-context.js --task '...' --workdir <dir>"

## STEP 12: INSTALL AUTO-CAPTURE HOOK (Part 11) — CRITICAL

⚠️ This is NOT the same as the built-in session-memory hook. The built-in one just dumps raw conversation text. This custom hook extracts actual knowledge (decisions, lessons, facts) into claim-named files.

1. Create the hook directory: mkdir -p ~/.openclaw/hooks/auto-capture
2. Copy hooks/auto-capture/HOOK.md and hooks/auto-capture/handler.ts from this repo into ~/.openclaw/hooks/auto-capture/
3. Set your extraction model API key (pick one):
   - Cerebras (free, fast): export CEREBRAS_API_KEY="your-key" (get one at https://cloud.cerebras.ai/)
   - Or use your existing model: export AUTOCAPTURE_API_URL="your-provider-url" AUTOCAPTURE_API_KEY="your-key" AUTOCAPTURE_MODEL="model-name"
4. Enable: openclaw hooks enable auto-capture

Without this hook, your vault/00_inbox/ never gets populated automatically and your memory system depends entirely on built-in Dreaming mining raw chat logs — which is slow, expensive, and lossy.

## STEP 13: SESSION MANAGEMENT FOR LONG-RUNNING CHATS (Telegram, Discord, etc.)

If you use Telegram, Discord, or any channel where you chat in one long continuous thread:

⚠️ One endless session = context fills up → compaction fires → older knowledge gets summarized away → bot "forgets." This is the #1 cause of "my bot doesn't remember anything."

**Understanding /new:** The `/new` command resets the bot's context window, NOT your chat history. Your Telegram/Discord messages stay exactly where they are — fully scrollable, forever. `/new` just tells the bot to start fresh so it's not dragging hours of old conversation through its context.

**Option A: Manual /new (simplest)**
- Type `/new` once a day (morning, or when you switch topics)
- The session-memory hook + auto-capture hook save everything important before reset

**Option B: Automatic session rotation (recommended for Telegram users)**
- Add a cron job that runs `/new` every 4 hours
- Add to SOUL.md or AGENTS.md:
  ```
  ## Session Continuity
  When a new session starts, DO NOT announce it. DO NOT say "new session" or "how can I help."
  Instead, silently read MEMORY.md and your most recent memory/ file to understand what was being discussed.
  Continue the conversation naturally as if nothing happened.
  The user should never know a session rotation occurred.
  ```
- This keeps context lean while the memory system handles persistence
- The user never notices — the bot just stays fast and remembers everything through vault + memory search

## STEP 14: TEMPORAL DECAY TUNING

If your embedding config has temporal decay:
- Set vault documents (vault/**) to 60-day half-life — curated knowledge shouldn't decay fast
- Set session files (memory/**) to 30-day half-life — these are raw and get consolidated by built-in Dreaming (Part 22)
- Don't set decay below 30 days for anything — it makes the bot forget things it just learned

## STEP 15: VERIFY

After all changes:
1. Restart the gateway: openclaw gateway stop && openclaw gateway start
2. Run: openclaw doctor
3. Test memory_search by asking about something in your vault files
4. Test Memory Bridge: node scripts/memory-bridge/memory-query.js "test query"
5. Check Control UI → Model Auth card (2026.4.15+): all OAuth tokens green, no rate-limit warnings
6. Run `openclaw flows list` (2026.3.31-beta.1+): no orphaned or denied control-plane flows
7. Report what you changed with before/after file sizes

## IMPORTANT RULES
- Do NOT delete any config - only trim and reorganize
- Keep all original content - just move it to vault/
- If a file doesn't exist, skip it
- Total workspace context (all .md files in root) should be under 8 KB when done
- Restart the gateway AFTER all changes, not during
```

---

That's it. One paste, your bot does everything. If anything fails, your config backup is at `openclaw.json.bak`.

---

## Troubleshooting

**One-shot prompt only partially completed:**
Re-paste just the steps that didn't complete. The prompt is idempotent - running a step twice won't break anything.

**memory_search not working:**
Make sure Ollama is running (`ollama serve` or `ollama ps`) and your embedding model is pulled (qwen3-embedding:0.6b or nomic-embed-text). OpenClaw auto-detects on localhost:11434. If search takes 2+ seconds, you're hitting a cloud embedding provider instead of local — check your embedding config in openclaw.json.

**Auto-capture hook not working:**
The built-in `session-memory` hook is NOT the auto-capture hook. The built-in one just dumps raw text. Check `openclaw hooks list` for 🧠 auto-capture. If it's missing, you need to install the custom hook from this repo's hooks/auto-capture/ directory. Also verify your API key is set: the handler needs CEREBRAS_API_KEY or AUTOCAPTURE_API_KEY as an environment variable.

**Bot forgets everything on Telegram/Discord:**
You're probably running one long continuous session. Context fills up, compaction summarizes away details, and the bot "forgets." Use `/new` daily or set up automatic session rotation (Step 13). `/new` does NOT delete your chat history — it only resets the bot's working memory.

**Bot still feels slow after trimming:**
Check total workspace file sizes. If over 10KB, files weren't trimmed. Also check reasoning mode - `high` adds 2-5 seconds per message.

**Sub-agents not spawning:**
Make sure your model supports `sessions_spawn` and you have a fallback model configured.

**Gateway won't restart:**
Run `openclaw doctor --fix`. If needed, restore backup: `cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json`

---

### Parts 18-21 Troubleshooting (LightRAG, Repowise, Services, Watcher)

**LightRAG pipeline hangs / queries return nothing:**
LightRAG depends on your embedding server. If the embedding server goes down, LightRAG's pipeline hangs indefinitely waiting for embeddings. Fix: restart the embedding server first, then restart LightRAG. Check with `curl http://localhost:8100/health` before touching LightRAG.

**Embedding server keeps crashing:**
The #1 cause is `pip install` upgrading `sentence-transformers` or `openai` to an incompatible version. `lightrag-hku` and `repowise` both pull newer versions of `openai` that can break your embedding server. Fix: after installing new packages, test the embedding server immediately. If it crashes on startup, check the error — common causes:
- `SentenceTransformer.__init__() got multiple values for keyword argument 'device'` → remove `device` from `config_kwargs` (sentence-transformers 5.x changed the API)
- `got an unexpected keyword argument 'use_safetensors'` → remove `use_safetensors` from constructor args
- Unicode encoding error on Windows (`cp1252`) → set `PYTHONIOENCODING=utf-8` before launching

**Zombie Python processes blocking GPU:**
If you launch servers via background processes (Start-Process, nohup) and they crash, the Python process can stay alive holding GPU memory. Your new server launch fails silently because the GPU is full. Fix: check `nvidia-smi` for orphaned processes, or check Task Manager for Python processes using lots of memory. Kill them manually, then restart services.

**LightRAG DELETE endpoint wiped everything:**
⚠️ `DELETE /documents` with a body of `{"ids":[...]}` performs a FULL WIPE of all storage, not a selective delete. This is a LightRAG API gotcha — the batch delete is nuclear. If you need to delete a single document, use the individual document endpoint. If you accidentally wipe, re-run your ingestion script (it tracks state so it won't re-upload already-processed files if you keep the state file).

**LightRAG ingestion stuck on huge files:**
Files over 100KB (especially 1MB+) can clog the pipeline for hours as the LLM tries to extract entities from hundreds of chunks. Fix: add a size guard to your ingestion script — skip files over 100KB. Those monster files produce noisy graphs anyway. The 95% of value comes from your normal-sized vault files.

**Repowise crashes on Windows:**
Common Windows issues:
- `cp1252 encoding error` → set `PYTHONIOENCODING=utf-8` environment variable
- `repowise init` creates a global DB but `repowise mcp` expects a repo-local `.repowise/wiki.db` → always run `init` from inside the project directory
- `py -m repowise` doesn't work → use the full path: `C:\Python312\Scripts\repowise.exe`
- `openai` package conflict → repowise requires openai<2 but lightrag installs openai 2.x. If both are installed, one will break. Consider using separate virtual environments.

**Docker ClickHouse fails on Windows:**
ClickHouse throws filesystem rename permission errors on Windows bind mounts. Fix: use Docker named volumes for ClickHouse instead of host bind mounts. Other services (Neo4j, Postgres, n8n) work fine with bind mounts.

**File watcher not syncing:**
Check: (1) is the watcher process running? `python lightrag-watcher.py --status` (2) is LightRAG healthy? The watcher queues files when LightRAG is down and auto-flushes when it comes back. (3) Check the log at `scripts/lightrag-watcher.log` for errors.

**Everything is slow after installing new services:**
The embedding server, LightRAG, and file watcher all run as separate Python processes. If your machine is RAM-constrained, they compete for resources. Monitor with Task Manager:
- Embedding server: ~2-4GB RAM + ~8GB VRAM
- LightRAG: ~500MB RAM (spikes during ingestion)
- File watcher: ~50MB RAM
- Docker stack: ~2GB RAM total
Total: ~5-7GB RAM + ~8GB VRAM. If you're tight on RAM, stop services you're not actively using.

**Best practice: Create a startup script**
Don't rely on manually starting services. Create a single `.cmd` or `.ps1` that starts everything in the right order:
1. Embedding server (must be up first — LightRAG depends on it)
2. LightRAG server (depends on embeddings)
3. File watcher (depends on LightRAG)
4. Docker services auto-restart on their own

---

**One-shot prompt struggles on your model:**
Do these 3 things manually instead:
1. Copy files from `/templates` into your workspace root
2. Run `ollama pull qwen3-embedding:0.6b`
3. Restart gateway: `openclaw gateway stop && openclaw gateway start`

## FAQ

**Why markdown files instead of a real database?**
Zero-infrastructure entry point. No Docker, no database admin. For power users, the architecture scales into a real database backend (e.g., TiDB vector). Markdown is the starting line, not the finish line.

**Doesn't the expensive model need to do the hard tasks?**
No. Your expensive model PLANS and JUDGES. Execution (code, research, analysis) gets delegated to cheaper models via sub-agents. Frontier judgment + budget execution.

**Does this work with models other than Claude Opus?**
Architecture works with any model supporting `memory_search` and `sessions_spawn` in OpenClaw. Tested on Opus 4.7 (the new Anthropic default as of 2026.4.15); most frontier models should handle the one-shot prompt.

**How is this different from other memory solutions?**
Most add external databases or cloud services. This gives you 90% of the benefit with 10% of the parts - local files + vector search. Nothing to install except Ollama. Nothing leaves your machine.

**Should I use LightRAG or the basic vault system?**
Start with the basic vault system (Parts 4, 9). It works well up to ~500 files. Once you cross that threshold and start getting irrelevant search results, upgrade to [LightRAG (Part 18)](./part18-lightrag-graph-rag.md). LightRAG builds a knowledge graph on top of your existing vault — same files, dramatically better retrieval. In our testing, basic vector search returned 6 unrelated snippets for a question that LightRAG answered perfectly with a synthesized narrative citing multiple sources.

---

## Part 22: Built-In Dreaming

> **Read this if** you're on OpenClaw 2026.4+ and want automatic memory consolidation (the native replacement for the retired Part 16 autoDream pattern).
> **Skip if** you're on a pre-2026.4 install — upgrade first (Part 26), then come back here.

### Memory You Can Afford (April 2026 research wave)

The week of April 10–17 produced a pile of memory-system papers and benchmarks that collectively shifted the default answer to "what model runs my memory layer?" from "the same one as my orchestrator" to **"something much cheaper."** The numbers are striking:

| System | Published | Result | Model class for memory ops |
|--------|-----------|--------|------------------------------|
| **[vbfs/agent-memory-store](https://github.com/iflow-mcp/vbfs-agent-memory-store)** | Apr 15, 2026 | **92.1% Recall@5** | **Zero LLM calls** — pure vector store + reranker |
| **[LightMem](https://arxiv.org/abs/2604.07798)** | Apr 12, 2026 | **+2.5 F1** over baseline on LoCoMo, **83 ms** retrieval | **Small language model** for STM/MTM/LTM consolidation |
| **[Mem²Evolve](https://arxiv.org/html/2604.10923v1)** | Apr 14, 2026 | **+18.53%** over baseline on mixed agent-task benchmark | Co-evolves skills + memory without expensive model calls |
| **[AMFS (Apache 2.0 MCP server)](https://dev.to/bruno_andrade_357863927e2/your-claude-code-and-cursor-agents-have-amnesia-heres-the-fix-2l3a)** | Apr 13, 2026 | Drop-in MCP memory for any harness | Runs on whatever model you want, including local |

The unifying insight: **memory consolidation is cheap, dense, deterministic work**. Using Opus 4.7 on it burns $100/month you don't need to spend.

**The practical OpenClaw configuration** — run memory-core's Deep-phase sweep on a small/local model, keep your orchestrator on top-tier:

```json
{
  "plugins": {
    "entries": {
      "memory-core": {
        "config": {
          "dreaming": {
            "enabled": true,
            "models": {
              "light":  "ollama/qwen3:4b",
              "deep":   "cerebras/qwen-3-235b-a22b-instruct-2507",
              "rem":    "ollama/qwen3:4b"
            }
          }
        }
      }
    }
  }
}
```

Why these picks:

- **Light phase** is short-term staging — pattern matching, deduplication. A 4B local model nails it.
- **Deep phase** is the scoring + promotion step — the one that writes MEMORY.md. Worth a capable cheap model (Cerebras `qwen-3-235b` runs at 1400 tok/s for pennies on the API).
- **REM phase** is reflection — narrative summarization. Local Qwen3:4b is fine; you're not doing complex reasoning.

Combined with memory-lancedb on local Ollama embeddings (see [Part 4](#part-4-memory-stop-forgetting-everything)), total memory-layer cost drops to near zero without sacrificing recall.

Full three-tier discipline — raw sources, curated summaries, generated artifacts — in [Part 31 — The LLM Wiki Pattern](./part31-the-llm-wiki-pattern-in-openclaw.md). SkillClaw's co-evolution of skills + memory in [Part 32](./part32-self-evolving-skills-with-skillclaw.md).

> **OpenClaw 2026.4+** — The official memory consolidation system built into memory-core. This replaces the retired custom autoDream pattern that used to live in Part 16.

### What Changed (and the Part 16 Retirement)

Earlier editions of this guide included a custom AGENTS.md-driven memory-consolidation pattern called **autoDream** — reverse-engineered from the Claude Code / memory-core source leak. It worked for pre-2026.4 installs but required you to set up triggers, state tracking, and consolidation logic manually. **The Part 16 file has been removed from the repo as of this release**; if you were running that pattern, migrate to the built-in Dreaming described below (see also [Part 26](./part26-migration-guide.md)).

OpenClaw 2026.4+ ships a **built-in dreaming system** inside memory-core that does all of this natively. If you're on 2026.4+, use the built-in version instead.

> **Default changed in 2026.4.15 stable:** `dreaming.storage.mode` now defaults to **`separate`** (was `inline`). Dreaming phase blocks (`## Light Sleep`, `## REM Sleep`) now land in `memory/dreaming/{phase}/YYYY-MM-DD.md` instead of being injected into the daily memory file at `memory/YYYY-MM-DD.md`. Daily memory files stay readable and the daily-ingestion scanner no longer has to compete with hundreds of phase-block lines on every run. If you preferred the old behavior, opt back in with `plugins.entries.memory-core.config.dreaming.storage.mode: "inline"`.

### How It Works

Dreaming runs a 3-phase sweep on a cron schedule (default: 3am daily):

| Phase | What It Does | Writes to MEMORY.md? |
|-------|-------------|---------------------|
| **Light** | Sorts and stages recent short-term material. Dedupes daily signals. | No |
| **Deep** | Scores candidates and promotes durable entries to MEMORY.md using weighted ranking. | Yes |
| **REM** | Extracts themes and reflective patterns. Builds reflection summaries. | No |

Plus a **Dream Diary** — a human-readable narrative entry in DREAMS.md written by a background subagent turn after each sweep.

### Deep Ranking Signals

Deep phase decides what becomes long-term memory using 6 weighted signals:

| Signal | Weight | What It Measures |
|--------|--------|-----------------|
| Frequency | 0.24 | How many short-term signals the entry accumulated |
| Relevance | 0.30 | Average retrieval quality for the entry |
| Query diversity | 0.15 | Distinct query/day contexts that surfaced it |
| Recency | 0.15 | Time-decayed freshness score |
| Consolidation | 0.10 | Multi-day recurrence strength |
| Conceptual richness | 0.06 | Concept-tag density from snippet/path |

Entries must pass `minScore`, `minRecallCount`, and `minUniqueQueries` thresholds to be promoted.

### Quick Start

```json
{
  "plugins": {
    "entries": {
      "memory-core": {
        "config": {
          "dreaming": {
            "enabled": true
          }
        }
      }
    }
  }
}
```

### Custom Cadence

```json
{
  "plugins": {
    "entries": {
      "memory-core": {
        "config": {
          "dreaming": {
            "enabled": true,
            "timezone": "America/New_York",
            "frequency": "0 */6 * * *"
          }
        }
      }
    }
  }
}
```

### Slash Commands

```
/dreaming status    — Check current state, last run, next scheduled run
/dreaming on        — Enable dreaming
/dreaming off       — Disable dreaming
/dreaming help      — Show usage info
```

### CLI Commands

```bash
# Preview what would be promoted (dry run)
openclaw memory promote

# Apply promotions to MEMORY.md
openclaw memory promote --apply

# Limit to top N candidates
openclaw memory promote --limit 5

# Explain why a specific candidate would/wouldn't promote
openclaw memory promote-explain "router vlan"

# Preview REM reflections without writing
openclaw memory rem-harness

# JSON output for scripting
openclaw memory promote --json
openclaw memory rem-harness --json
```

### What Gets Written

| Location | Content |
|----------|---------|
| `memory/.dreams/` | Machine state — recall store, phase signals, ingestion checkpoints, locks |
| `DREAMS.md` | Human-readable Dream Diary entries + phase summaries |
| `memory/dreaming/<phase>/YYYY-MM-DD.md` | Optional phase reports |
| `MEMORY.md` | Long-term promoted entries (Deep phase only) |

### Canonical Memory Files (changed in 2026.4.15)

As of 2026.4.15, memory-core treats **MEMORY.md and DREAMS.md as the only canonical memory files** — the ones the built-in `memory_get` tool is allowed to read. This was tightened after a path-traversal report against the `memory-qmd` backend that let `memory_get("any/path/in/workspace.md")` read arbitrary workspace files.

Practical impact:

- **Good:** skills and hooks that just need to see "what does the agent currently know?" read from MEMORY.md and DREAMS.md — same as before.
- **Breaking if you did this:** any skill or hook that called `memory_get("vault/projects/x.md")` or similar. That now returns an error. Switch to `memory_search` (if you want semantic retrieval) or to a normal file read via `exec`/`read_file` (if you want a specific path).
- **Backend restriction:** memory-core's QMD backend no longer reads paths outside the canonical set. If you were using QMD-backed memory for ad-hoc file access, move that logic to a vault skill or regular file I/O.

If you're writing a new skill that needs to read arbitrary workspace files, **don't shim `memory_get`** — use `memory_search` for retrieval or explicit file reads for exact paths. `memory_get` is strictly for the canonical agent indexes now.

### Dreams UI

The Gateway Dreams tab shows:
- Current enabled/disabled state
- Phase-level status and managed-sweep presence
- Short-term, long-term, and promoted-today counts
- Next scheduled run timing
- Expandable Dream Diary reader

### Use This If / Skip If

**Use Part 22 (built-in dreaming)** if you're on OpenClaw 2026.4+. It's the official, supported implementation with proper scoring, phase management, and a UI.

**If you're on a pre-2026.4 install:** upgrade. The old Part 16 custom-autoDream workaround is no longer in the repo, and the built-in system is a drop-in replacement. See [Part 26 — Migration Guide](./part26-migration-guide.md).

*Source: [OpenClaw Dreaming Documentation](https://clawdocs.org/concepts/dreaming)*

---

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=OnlyTerp/openclaw-optimization-guide&type=Date)](https://www.star-history.com/#OnlyTerp/openclaw-optimization-guide&Date)

If this guide saved you time, a ⭐ helps other OpenClaw operators find it.

## Featured / mentioned in

*We'll list the talks, blog posts, newsletters, and release notes that reference this guide here. Open a PR with the link if you've written about it.*

## Sibling resources in this repo

| Resource | Purpose |
|---|---|
| **[SCORECARD.md](./SCORECARD.md)** | 50-item Production Readiness Scorecard (2 pts each, max 100). Shareable. |
| **[AWESOME.md](./AWESOME.md)** | Curated list of skills, guides, talks, research, adjacent ecosystems. |
| **[templates/](./templates/)** | Reference config starter kit: `openclaw.example.json`, SOUL / AGENTS / MEMORY / TOOLS templates for 2026.4.15 stable. |
| **[benchmarks/](./benchmarks/)** | Reproducible benchmark methodology + harness + run template. Submit your numbers via PR. |
| **[CONTRIBUTING.md](./CONTRIBUTING.md)** · **[SECURITY.md](./SECURITY.md)** · **[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)** · **[SUPPORT.md](./SUPPORT.md)** | Contributor + community policy. |

## About

*Built by [Terp — Terp AI Labs](https://x.com/OnlyTerp).*

The optimization guide for OpenClaw — covering speed, memory, context management, model selection, web search, orchestration, vault architecture, observability, infrastructure hardening, skills marketplace, control-plane security, and spec-driven development. Battle-tested daily on a 14+ agent production deployment.

**Prefer scripts?** Run `bash setup.sh` (macOS/Linux) or `powershell setup.ps1` (Windows) from the repo root. Or grab the full reference kit from [`templates/`](./templates/).

**Saved you tokens or time?** Post your [scorecard](./SCORECARD.md) score or ping [@OnlyTerp](https://x.com/OnlyTerp) on X with your before/after numbers.

### Related resources

- [OpenClaw Documentation (clawdocs.org)](https://clawdocs.org/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Changelog](https://openclawai.io/changelog/)
- [OpenClaw Discord Community](https://discord.gg/clawd)
- [ClawHub — Skills Marketplace](https://clawhub.com)
- [This guide, rendered as a searchable site](https://onlyterp.github.io/openclaw-optimization-guide/) *(deploys from `master` via MkDocs-material)*
