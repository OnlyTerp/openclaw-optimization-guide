# Phase 1 Repo Inventory

Generated: 2026-05-10

## Standalone part files

- `part9-vault-memory.md` — 36360 bytes, 915 lines. ---
- `part10-state-of-the-art-embeddings.md` — 11529 bytes, 235 lines. *By Terp - [Terp AI Labs](https://x.com/OnlyTerp)*
- `part11-auto-capture-hook.md` — 6542 bytes, 171 lines. *By Terp - [Terp AI Labs](https://x.com/OnlyTerp)*
- `part12-self-improving-system.md` — 5531 bytes, 128 lines. Your agent makes a mistake Monday. You correct it. Tuesday, same mistake. Wednesday, same mistake. Every session starts fresh — corrections evaporate.
- `part13-memory-bridge.md` — 7034 bytes, 187 lines. When you spawn Codex or Claude Code to build something, they start blind. They don't know your architecture decisions, past mistakes, or what's already been built. They code from scratch every time.
- `part15-infrastructure-hardening.md` — 20435 bytes, 444 lines. Your OpenClaw setup probably has hidden landmines that cause crash loops, GPU contention, and rate limit spirals. We found all of ours in one session. Here's what to check and how to fix each one.
- `part18-lightrag-graph-rag.md` — 12434 bytes, 320 lines. *From "find similar text" to "reason about relationships." The single biggest intelligence upgrade you can make.*
- `part19-repowise-codebase-intelligence.md` — 5486 bytes, 148 lines. *60% fewer tokens. 4x faster. Your coding agents stop guessing and start knowing.*
- `part20-observability-and-services.md` — 5492 bytes, 181 lines. *See what your agents are actually doing. Connect to 400+ apps. Make search 40% better.*
- `part21-realtime-knowledge-sync.md` — 7531 bytes, 201 lines. *No cron. No polling. File changes hit your knowledge graph in under 6 seconds.*
- `part23-clawhub-skills-marketplace.md` — 11086 bytes, 171 lines. ClawHub is the official skills marketplace for OpenClaw v4.0+. A "skill" is a bundled `.skill.md` (instructions) + optional scripts, tools, and hook wiring. You install one and the agent suddenly knows how to do somethin
- `part24-task-brain-control-plane.md` — 14147 bytes, 217 lines. Before 2026.3.31-beta.1, OpenClaw had four separate ways to run something:
- `part25-architecture-overview.md` — 11400 bytes, 204 lines. The exact 95/5 split was always a mnemonic, not a law. The useful part survived the late-April release wave: changing weights helps, but the big operator wins come from context budgets, memory discipline, provider routin
- `part26-migration-guide.md` — 20063 bytes, 319 lines. | You're on | Do this first | Then | Finally |
- `part27-gotchas-and-faq.md` — 13259 bytes, 189 lines. | Cause | Fix |
- `part28-glossary-and-terminology.md` — 26672 bytes, 343 lines. This is a single-page reference. Terms are alphabetical. Each entry includes the shortest-possible definition, the part where it's introduced or covered in depth, and (when relevant) the release it was added in.
- `part29-hook-catalog.md` — 18902 bytes, 389 lines. An agent reading AGENTS.md is *advisory*. Hooks are *mandatory* — they run outside the model's control, at well-defined lifecycle events, and they can hard-block a tool call or session before it continues.
- `part30-ralph-loop-in-openclaw.md` — 12514 bytes, 245 lines. Named for Ralph Wiggum's "me fail English? that's unpossible" — because the loop's defining feature is that the agent is *not allowed to give up*. It keeps running until the exit condition is met by reality (tests green,
- `part31-the-llm-wiki-pattern-in-openclaw.md` — 9336 bytes, 138 lines. From the April 2026 gist and YouTube walkthrough: a production LLM system needs a **three-tier memory model**, each tier with a different owner, a different update cadence, and a different read path.
- `part32-self-evolving-skills-with-skillclaw.md` — 8652 bytes, 141 lines. Static skills work fine for the first 20. Past that, you hit:
- `part33-late-april-2026-field-guide.md` — 9380 bytes, 173 lines. OpenClaw's late-April releases changed the operator playbook in five places: providers, memory, messaging, browser/Codex automation, and plugin security. This page is the catch-up map.

## README inline anchors verified from AGENTS map

- Part 1 line 396
- Part 2 line 488
- Part 3 line 610
- Part 4 line 661
- Part 5 line 757
- Part 6 line 946
- Part 7 line 1077
- Part 8 line 1122
- Part 9 inline line 1236
- Part 14 line 1399
- Part 17 line 1466
- Part 22 line 1843

## Top-level directories

- `.github/` — 15 files. GitHub workflow and PR/issue automation.
- `.ralph/` — 6 files. Ralph audit artifacts for this recovery PR.
- `benchmarks/` — 5 files. Benchmark methodology and future benchmark suites.
- `configs/` — 1 files. Reference OpenClaw configs; balanced config is PRESERVE.
- `docs/` — 1 files. Supplemental docs.
- `examples/` — 8 files. Worked examples.
- `hooks/` — 2 files. Auto-capture hook implementations and docs.
- `parts/` — 0 files. Category-specific supplemental docs.
- `screenshots/` — 4 files. Guide images.
- `scripts/` — 14 files. Operational scripts and library modules.
- `server-config/` — 286 files. PRESERVE deployed workspace snapshot.
- `templates/` — 7 files. PRESERVE user-facing templates.

## Sparse or empty build targets

- `hooks/auto-capture/` has only the legacy handler/HOOK docs; Iteration 8 must add git-commit, file-save, and test-result hooks.
- `skills/` is absent at repo root; Iteration 4 and backlog skills need new skill packages.
- `benchmarks/` has methodology but lacks embedding-latency and memory-retrieval result suites.
- `examples/` lacks ralph-on-fresh-repo and memory-bridge-end-to-end examples.

## Missing implementations referenced by plan or parts

- `skills/ralph-superpowers/SKILL.md` — Iteration 4.
- `scripts/healthcheck.test.sh` — Iteration 6.
- `templates/ralph/` bootstrap templates — Iteration 7.
- `hooks/auto-capture/git-commit-hook.js`, `file-save-hook.js`, `test-result-hook.js` — Iteration 8.
- `scripts/lib/embeddings-client.js` — Backlog B1.
- `scripts/lib/lancedb-retrieval.js` — Backlog B2.
- `skills/repowise/`, `skills/lightrag/`, `skills/clawhub/`, `skills/skillclaw/` — Backlog B3-B5/B12.
- `benchmarks/embedding-latency/` and `benchmarks/memory-retrieval/` — Backlog B6-B7.
- `scripts/patches/gateway-graceful-restart.sh` — Backlog B10.
- `part34-ralph-loop-failure-modes.md` — Backlog B13.
- `tests/ralph-loop-smoke.test.sh` — Backlog B14.
- `.github/PULL_REQUEST_TEMPLATE.md` — Backlog B15.
