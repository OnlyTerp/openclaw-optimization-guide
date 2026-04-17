# Benchmark Methodology

How the numbers in [benchmarks/README.md](./README.md) and the main [README](../README.md#what-you-get-numbers-from-our-production-deployment) are produced. If you want to reproduce them — or contribute your own — this is the contract.

> **TL;DR:** three environments, four pillars measured, repeatable scripts under [`harness/`](./harness/). Run `make bench` to see your own numbers; open a PR to add them to [`runs/`](./runs/).

## 1. Environments

We publish numbers from three deliberately different setups, so readers can see how the guide's patterns scale up and down:

| Label | Machine | OpenClaw version | Purpose |
|---|---|---|---|
| **Prod** | Windows 11, RTX 5090 (24 GB VRAM), 128 GB RAM, AMD Ryzen 9 7950X | 2026.4.15 stable | Real 14-agent production deployment (TerpHQ). "Best case with local embedding server." |
| **Baseline** | MacBook Pro M3 Max (36 GB), stock OpenClaw + Ollama | 2026.4.15 stable | Typical developer laptop. Most readers land near this. |
| **Minimal** | Linux VM, 8 GB RAM, no GPU, cloud embedding | 2026.4.15 stable | Low-end. Shows the floor of what the guide still buys you. |

Readers' numbers will fall somewhere in the envelope defined by these three. If yours are wildly outside that envelope, open an issue — that's the kind of data we want.

## 2. What we measure

Four pillars, chosen to align with the [Production Readiness Scorecard](../SCORECARD.md):

### 2.1 Context-injection footprint

- **Metric:** bytes injected per user message (SOUL.md + AGENTS.md + MEMORY.md + TOOLS.md + system prompt overhead).
- **How:** enable gateway debug logging for one turn, extract the `messages[*]` payload, count bytes by role.
- **Why it matters:** Part 1 / Part 2 of the guide. Injected context is a tax on every turn.
- **Pass bar:** ≤ 8 KB for Prod/Baseline, ≤ 10 KB for Minimal.

### 2.2 Memory search latency

- **Metric:** p50 / p95 latency of `memory_search` across a vault of ~25K chunks.
- **How:** `harness/bench_memory_search.py` issues 500 warm queries, 500 cold queries (cache-flushed), measures round-trip including dimensionality reduction.
- **Why it matters:** Part 4 / Part 10. Memory search is the most-called tool in a long session.
- **Pass bar:** warm p95 ≤ 150 ms, cold p95 ≤ 500 ms.

### 2.3 Sub-agent spawn fan-out

- **Metric:** wall-clock time for N parallel workers doing a fixed task (Research-the-docs of a 100-page PDF corpus).
- **How:** `harness/bench_orchestration.sh` spawns N ∈ {1, 2, 4, 8} workers, records latency + token usage.
- **Why it matters:** Part 5 / Part 24. The whole orchestration thesis only pays off if workers actually parallelize.
- **Pass bar:** 8-worker run ≤ 1.6× single-worker run (super-linear is noise; 2.0× is a config bug).

### 2.4 Task Brain approval overhead

- **Metric:** median added latency when a gated tool call (category = `execution.*`) hits the approval path vs. baseline `allow`.
- **How:** `harness/bench_taskbrain.sh` exercises a known-safe sandbox tool 200 times with policy flipped between `allow` and `ask` (auto-approved for the test).
- **Why it matters:** Part 24. If Task Brain adds unbearable overhead, people turn it off. It doesn't.
- **Pass bar:** ≤ 40 ms median added latency per gated call.

## 3. Protocol

Every published run follows the same protocol — this is the contract for `runs/*.md`:

1. **Cold-start the gateway.** Kill any stale processes; start fresh (`openclaw gateway restart`).
2. **Warm once.** Send one throwaway message per model to establish caches.
3. **Run each harness script five times.** Report the median; call out p95 where relevant.
4. **Record model + plugin versions exactly.** `openclaw doctor > runs/$LABEL-doctor.txt`.
5. **Run [Production Readiness Scorecard](../SCORECARD.md).** Record total and per-pillar scores.
6. **Write up.** One markdown file in `runs/`, filled against the template at [`runs/TEMPLATE.md`](./runs/TEMPLATE.md).

## 4. Honesty rules

This is the most important section. A benchmark repo is only as useful as the honesty of its "what we didn't do":

1. **Publish the misses.** If a pattern didn't help you, that's a contribution. Add it to `runs/` with `outcome: no-improvement`.
2. **No mid-run tweaks.** If you discover a config fix partway through a run, redo the run from scratch. Don't patch the numbers.
3. **Call out hardware advantages.** The Prod numbers come from an RTX 5090; they are *not* "what you'll get on a laptop". Every `runs/*.md` file opens with a hardware line and a "caveats" section.
4. **Version-pin everything.** OpenClaw, plugin versions, model versions, embedding model. Numbers on `opus` without a version tag are suspect forever.
5. **Link the raw log.** `runs/$LABEL/raw.jsonl` (gzipped if large). Readers should be able to replay your numbers locally.

## 5. How to submit your numbers

1. Fork this repo.
2. Copy `runs/TEMPLATE.md` to `runs/YYYY-MM-your-label.md` (e.g. `runs/2026-04-apple-m4-pro.md`).
3. Run the harness (`make bench` at the repo root).
4. Fill in the template. Attach `raw.jsonl.gz`.
5. Open a PR with the `benchmark` label. We review weekly.

## 6. What we will *not* publish

- **Vendor-funded numbers.** If your org pays for cloud LLM credits that offset cost, we're not running a model-provider bakeoff — results are welcome but go in a separate `runs/vendor-funded/` directory that readers can filter out.
- **Anything without a matching scorecard score.** Numbers without a scorecard context don't help a reader decide what to do.
- **Synthetic-benchmark-only runs.** You also have to run against `harness/real-world/`, a task corpus of 10 actual production-ish tasks. Synthetic numbers alone are cheap to game.

## 7. Roadmap

- [ ] `harness/` scripts — initial scaffolding is in this PR; next pass fills them in with real implementations.
- [ ] `runs/TEMPLATE.md` — in this PR.
- [ ] `runs/2026-04-prod.md` — will be published as Terp's production numbers, next pass.
- [ ] `runs/real-world/` — task corpus for qualitative grading (paired with quantitative numbers).
- [ ] CI job that re-runs synthetic benchmarks against every PR that touches `templates/openclaw.example.json`.

If you want to drive any of these to completion, open an issue and tag yourself. This is explicitly a community-owned subproject.
