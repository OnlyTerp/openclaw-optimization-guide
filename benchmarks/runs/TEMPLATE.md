# $LABEL benchmark run

<!-- Filename: YYYY-MM-short-label.md (e.g. 2026-04-apple-m4-pro.md) -->
<!-- See ../METHODOLOGY.md for the contract. -->

- **Date:** 2026-MM-DD
- **Author:** @your-handle
- **OpenClaw version:** 2026.4.15 stable (or whatever you're on — be exact)
- **Scorecard score:** XX / 100 — link to your scorecard snapshot if public
- **Outcome:** `improved` / `no-improvement` / `regressed` / `partial`

## Hardware

- **Machine:** (e.g. MacBook Pro M4 Pro, 48 GB unified, 14-core CPU)
- **GPU:** (or "integrated" / "none")
- **OS:** (e.g. macOS 15.4)

## Caveats

Anything that makes your numbers non-transferable. Always include at least one. If you can't think of any, reread [METHODOLOGY.md §4](../METHODOLOGY.md#4-honesty-rules) and try again.

## Setup

- Primary model: `anthropic:opus` (Claude Opus 4.7, 2026.4.15 stable)
- Compaction model: `...`
- Embedding: `...`
- Vault size: `...` files, `...` chunks
- Relevant deviations from [`templates/openclaw.example.json`](../../templates/openclaw.example.json): `...`

## Numbers

### Context-injection footprint

| File | Size |
|---|---|
| SOUL.md | `X.X KB` |
| AGENTS.md | `X.X KB` |
| MEMORY.md | `X.X KB` |
| TOOLS.md | `X.X KB` |
| **Total injected** | **`X.X KB`** |

Pass bar: ≤ 8 KB. Result: `pass` / `fail`.

### Memory search latency

| Metric | p50 | p95 |
|---|---|---|
| Warm | `XX ms` | `XX ms` |
| Cold | `XX ms` | `XX ms` |

Pass bar: warm p95 ≤ 150 ms, cold p95 ≤ 500 ms. Result: `pass` / `fail`.

### Sub-agent spawn fan-out

| Workers | Wall-clock | vs 1-worker |
|---|---|---|
| 1 | `XX s` | 1.00× |
| 2 | `XX s` | `X.XX×` |
| 4 | `XX s` | `X.XX×` |
| 8 | `XX s` | `X.XX×` |

Pass bar: 8-worker ≤ 1.6× single-worker. Result: `pass` / `fail`.

### Task Brain approval overhead

- Baseline (`allow`): `XX ms` median per call
- Gated (`ask` → auto-approve): `XX ms` median per call
- Added overhead: `XX ms`

Pass bar: ≤ 40 ms added. Result: `pass` / `fail`.

## Real-world task scores

From `harness/real-world/` (qualitative, pass/fail per task):

| Task | Result | Notes |
|---|---|---|
| `migrate-legacy-codebase` | `pass` / `fail` | |
| `triage-bug-backlog` | `pass` / `fail` | |
| `rewrite-docs-site` | `pass` / `fail` | |
| … | | |

## Raw logs

- `raw.jsonl.gz` (attach or link)
- `doctor.txt` (output of `openclaw doctor`)

## Takeaways

2-4 sentences. What changed vs. your previous run? What single thing had the biggest impact? What surprised you?
