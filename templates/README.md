# Reference Config Starter Kit

A working-by-default starter bundle that matches the patterns documented in the [OpenClaw Optimization Guide](../README.md). Copy these files into a fresh OpenClaw workspace and you're running the guide's baseline setup.

> Tested on **OpenClaw 2026.4.15 stable** (2026-04-16). See [Part 26 — Migration Guide](../part26-migration-guide.md) if you're on an older version.

## What's in this directory

| File | What it is | Target size | Introduced in |
|---|---|---|---|
| `openclaw.example.json` | Reference config. Copy to `~/.openclaw/openclaw.json` (or your project root), replace `${...}` env var refs with real credentials, edit to taste. | ~2 KB | [Part 15](../part15-infrastructure-hardening.md), [Part 24](../part24-task-brain-control-plane.md) |
| `SOUL.md` | Agent personality file (tone + anti-patterns). Injected every message. | **< 1 KB** | [Part 2](../README.md#part-2-context-engineering--the-discipline) |
| `AGENTS.md` | Operating rules: decision tree, orchestration, approval categories, safety. Injected every message. | **< 2 KB** | [Part 5](../README.md#part-5-orchestration-stop-doing-everything-yourself) |
| `MEMORY.md` | Pure index with links into `vault/`. Injected every message. | **< 3 KB** | [Part 4](../README.md#part-4-memory-stop-forgetting-everything) |
| `TOOLS.md` | Tool name + one-liner per line. Stops model re-reading full tool schemas. | **< 1 KB** | [Part 2](../README.md#part-2-context-engineering--the-discipline) |
| `vault/projects/` | Project-level notes directory (one folder per active project). | — | [Part 9](../part9-vault-memory.md) |

Combined injected-context footprint target: **< 8 KB**. Compare against [benchmarks/](../benchmarks/).

## 30-second install

```bash
# 1. Back up your existing config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-guide.$(date +%Y%m%d) 2>/dev/null || true

# 2. Drop the reference config in (after replacing ${...} with your real keys)
cp templates/openclaw.example.json ~/.openclaw/openclaw.json

# 3. Drop the injected-context files into your workspace
cp templates/SOUL.md templates/AGENTS.md templates/MEMORY.md templates/TOOLS.md ./

# 4. Restart the gateway
openclaw gateway restart

# 5. Verify
openclaw doctor
```

Full setup in [setup.sh](../setup.sh) / [setup.ps1](../setup.ps1) at the repo root.

## Philosophy (one screen)

1. **Target < 8 KB of injected context.** Every KB above that pays tax on every turn. See [Part 1 — Speed](../README.md#part-1-speed-stop-being-slow) and [Part 2 — Context Engineering](../README.md#part-2-context-engineering--the-discipline).
2. **MEMORY.md is an index, not a store.** Details go in `vault/`. Memory-core's built-in dreaming keeps it small automatically. See [Part 4](../README.md#part-4-memory-stop-forgetting-everything) + [Part 22](../README.md#part-22-built-in-dreaming).
3. **Orchestrator + workers, not a megamind.** Frontier model plans, cheap workers execute. See [Part 5](../README.md#part-5-orchestration-stop-doing-everything-yourself) + [Part 24](../part24-task-brain-control-plane.md).
4. **Semantic approvals, not name allowlists.** Read-only allow, execution ask, write.network ask, control-plane deny. See [Part 24](../part24-task-brain-control-plane.md).
5. **Never commit credentials.** Use env var refs in `openclaw.json`. See [Part 15](../part15-infrastructure-hardening.md).

## When this kit does *not* match what you should run

- **Single-agent personal-dev setup:** you can skip the Task Brain approval block and pin one model.
- **Local-only setup on a 14B-or-smaller model:** flip `agents.defaults.experimental.localModelLean: true` in `openclaw.json`.
- **Team deployment with multi-user approvals:** override `taskBrain.approvals` per-agent — see [Part 24](../part24-task-brain-control-plane.md).
- **Large vault (500+ files):** add LightRAG ([Part 18](../part18-lightrag-graph-rag.md)) and Repowise ([Part 19](../part19-repowise-codebase-intelligence.md)).
