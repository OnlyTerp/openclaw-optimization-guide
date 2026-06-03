# Scripts

Runnable companions to the guide. The parts describe what each script does and
why; the source lives here so you can `git clone` once and run them instead of
copy-pasting out of Markdown.

All scripts are zero-dependency: the `.mjs` tools need only Node.js (ES
modules), and the `.sh` wrappers need only `bash` plus the CLIs called out in
their comments (`openclaw`, `git`, `jq`, `awk`, `bc`).

## Vault graph tools — [Part 9](../part9-vault-memory.md)

Run these from your workspace root (or set `OPENCLAW_WORKSPACE` to point at it).

| Script | Purpose |
|--------|---------|
| [`vault-graph/graph-indexer.mjs`](./vault-graph/graph-indexer.mjs) | Scans every `.md` file, parses `[[wiki-links]]`, writes a JSON adjacency graph to `vault/06_system/graph-index.json`. |
| [`vault-graph/graph-search.mjs`](./vault-graph/graph-search.mjs) | Traverses the graph — finds a file plus its direct and 2nd-degree connections. |
| [`vault-graph/auto-capture.mjs`](./vault-graph/auto-capture.mjs) | Turns an insight into a claim-named note in `vault/00_inbox/` and links it to related MOCs. |
| [`vault-graph/process-inbox.mjs`](./vault-graph/process-inbox.mjs) | Reviews inbox notes and suggests (or moves them to) the right vault folder. |
| [`vault-graph/update-mocs.mjs`](./vault-graph/update-mocs.mjs) | Health check — finds broken wiki-links, stale items, and orphaned notes. |

```bash
# typical first run
mkdir -p vault/{00_inbox,01_thinking,02_reference,03_creating,04_published,05_archive,06_system}
node scripts/vault-graph/graph-indexer.mjs
node scripts/vault-graph/graph-search.mjs "memory"
```

> Note: `vault-graph/auto-capture.mjs` (Part 9) is **not** the same as the
> `auto-capture` hook in [`hooks/auto-capture/`](../hooks/auto-capture/) (Part
> 11). The Part 9 script files a note you hand it; the Part 11 hook extracts
> notes from a session transcript automatically.

## Autonomy wrappers

| Script | Part | Purpose |
|--------|------|---------|
| [`ralph.sh`](./ralph.sh) | [Part 30](../part30-ralph-loop-in-openclaw.md) | Runs the Ralph loop — a fresh OpenClaw session per iteration until `PRD.json` is `done` or the iteration / wall-clock / USD budget is exhausted. Needs `PRD.json` and `loop-prompt.md` in the project root. |
| [`fan-out.sh`](./fan-out.sh) | [Part 15](../part15-infrastructure-hardening.md) | Spawns one agent per `*.md` task prompt across N git worktrees, then waits on all of them and reports failures. |

```bash
scripts/ralph.sh /path/to/project
scripts/fan-out.sh ./tasks
```

## Referenced elsewhere (not bundled here)

A few scripts mentioned in the guide intentionally live outside this repo —
their source isn't reproduced in the Markdown, so committing a copy here would
just go stale. Here's where each one actually comes from:

| Path in the guide | Part | Where it lives |
|-------------------|------|----------------|
| `scripts/memory-bridge/memory-query.js`, `preflight-context.js` | [Part 13](../part13-memory-bridge.md) | Standalone Memory Bridge tool — copy the two scripts into `scripts/memory-bridge/` in your own workspace as described in Part 13. |
| `lightrag-watcher.py` | [Part 21](../part21-realtime-knowledge-sync.md) | Your real-time sync watcher — Part 21 shows the config block to edit; deploy it under your own `scripts/`. |
| `scripts/qwen_embed_server_v3.py` | [Part 10](../part10-state-of-the-art-embeddings.md) | Ships inside your local OpenClaw install (installed by the one-shot prompt in Part 17), not in this guide repo. |
