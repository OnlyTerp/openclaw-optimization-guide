# Benchmark harness

Scripts that produce the numbers documented in [../METHODOLOGY.md](../METHODOLOGY.md).

> **Status: scaffold.** The scripts below are thin wrappers with a documented interface. Fleshing them out is explicitly invited — see the roadmap in [../METHODOLOGY.md §7](../METHODOLOGY.md#7-roadmap).

## Scripts

| Script | Measures | Pillar |
|---|---|---|
| `bench_context.sh` | Injected-context footprint (bytes per user turn, broken down by role) | Speed |
| `bench_memory_search.py` | `memory_search` warm/cold latency across ~25K chunks | Memory |
| `bench_orchestration.sh` | Wall-clock for N parallel workers on a fixed task | Orchestration |
| `bench_taskbrain.sh` | Added latency from Task Brain approval path vs. `allow` baseline | Security / Observability |

## Invocation

From the repo root:

```bash
make bench                 # run all four, print a summary table
make bench-context         # Pillar 1 only
make bench-memory          # Pillar 2 only
make bench-orchestration   # Pillar 3 only
make bench-taskbrain       # Pillar 4 only
```

Each invocation writes to `benchmarks/runs/_scratch/$(date +%Y%m%dT%H%M%S)/` so you can diff between runs without clobbering previous numbers.

## Environment assumptions

- OpenClaw 2026.4.15 stable running locally. `openclaw doctor` returns clean.
- The reference config at [`templates/openclaw.example.json`](../../templates/openclaw.example.json) is in `~/.openclaw/openclaw.json` (or the harness will refuse to run).
- Local Ollama at `http://localhost:11434` with `qwen3-embedding:0.6b` pulled.

## Philosophy

- **Boring is good.** We measure synthetic things because synthetic things reproduce. Qualitative tasks live in [`real-world/`](./real-world/) for pairing.
- **Fail loudly.** If a script can't produce numbers (gateway unreachable, wrong model, missing vault), it exits non-zero. We never silently fake a number.
- **No model-vendor bakeoffs.** This harness measures *the guide's patterns* on a given setup, not "which LLM is smartest today."

## Writing a new benchmark

1. Create `bench_$name.sh` or `bench_$name.py`.
2. Write it so that `./bench_$name.sh --help` documents flags and exit codes.
3. Output a single-line JSON summary to stdout (so `jq` can fold multiple benches into one table).
4. Add the bench to the `make bench` target in the repo's `Makefile`.
5. Update [../METHODOLOGY.md](../METHODOLOGY.md) with a new pillar or sub-pillar entry.
6. Update [../runs/TEMPLATE.md](../runs/TEMPLATE.md) with a matching section.
