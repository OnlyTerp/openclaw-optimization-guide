# Memory + RAG Playbook (source: Kevin's uploaded brief, 2026-05-03)

> Archived verbatim summary of Kevin's uploaded "Memory_skills" brief. This is the
> canonical playbook for how this workspace handles memory, RAG, ingestion, and skills.
> When in doubt, defer to this doc + AGENTS.md + SECURITY.md.

## Executive summary

**Already working / do not change:**
- OpenClaw core memory (SQLite index, MEMORY.md, daily notes) is functioning.
- Gateway and chat interface stay unchanged.
- Built-in hybrid search (vector + BM25) already enabled when an API key is set.
- Personal identity memory (MEMORY.md) and basic agent setup: untouched.
- Default active-memory plugin (memory-core) preserved for conversation recall.
- Avoid installing unvetted skills or radically altering gateway/firewall/identity.

**High-leverage upgrades:**
- Document ingestion + indexing pipeline.
- Chunking strategy.
- Memory search tuning.
- Convert PDFs → Markdown preserving structure (headings, tables) for accurate RAG.
- Enable hybrid search (OpenAI/Gemini embeddings); only use local QMD reranking if precision fails.
- Keep MEMORY.md lean — durable facts only.

**Recommended architecture:**
- Default SQLite hybrid engine + `memorySearch.extraPaths` for knowledge folders.
- Knowledge folder = controlled Markdown directory, then indexed.
- Keep metadata per chunk: file, page, heading, chunk ID.
- QMD only if hybrid precision is insufficient.
- Memory-Wiki only for curated, high-value knowledge with provenance.
- MEMORY.md = identity + preferences only. Project docs/prompts → external knowledge folders.

**Minimal skill set:**
- MinerU PDF Extractor (complex PDFs with tables/formulas).
- PDF OCR Extraction (scanned docs).
- Markdown Lint (formatting cleanup).
- Avoid bulk ClawHub packs. Read each SKILL.md before use. Disable skills that add token cost without clear benefit.

**Cost / latency risks:**
- Unnecessary LLM calls and embeddings.
- Flagship models when smaller ones suffice.
- QMD reranker (large local model).
- Indexing too much data.
- Pin embedding provider (e.g. `text-embedding-3-small`) to control cost variance.
- Watch chunk size and overlap.

## Next 3 actions (per the playbook)

1. **Inspect current state**: `openclaw --version`, `openclaw doctor`, `openclaw memory status`. Adjust plan if commands have changed.
2. **Set up knowledge folders**: confirm `~/openclaw-knowledge/` (inbox, originals, processed/markdown, etc.) and configure `memorySearch.extraPaths` at the agent default level.
3. **Test ingestion pipeline**: process one representative PDF → clean Markdown + metadata (source map, summary). Verify retrieval via `memory_search` before scaling up.

## Top-tier RAG + agent efficiency principles

1. Never paste whole docs into chat. Ingest into the agent's knowledge base.
2. Convert documents to clean, source-preserving Markdown (headings stay headings, lists stay lists, tables stay tables).
3. Index only stable knowledge. Skip ephemeral logs / drafts / chat transcripts. Use `memorySearch.extraPaths`.
4. Hybrid retrieval (vector + BM25). Always keep BM25 (`textWeight`) on alongside vector; tune weights per need.
5. Rerank only when necessary. QMD has cost/latency. Use only if hybrid misses.
6. Chunk by document structure, not arbitrarily. Top-down on headings; small overlap (10–20%).
7. Preserve provenance metadata per chunk: file, page, heading, chunk id. OpenClaw can append `Source: path#L..` footers.
8. Keep MEMORY.md lean — durable, biographical, decisions, preferences. No trivia.
9. Store document knowledge in project files, not identity memory.
10. Review before promoting anything to MEMORY.md. Trust but verify.
11. Active Memory (memory-core) = conversational recall. Indexed knowledge base = factual RAG.
12. Memory-Wiki = curated knowledge dashboards (post-processing, QA). Don't auto-ingest raw docs.
13. QMD only when builtin search is insufficient (`memory.backend="qmd"`).
14. Skills are narrow procedures (one job each).
15. Keep skill count minimal. Prefer workspace-local skills.
16. Workspace skills load last, override globals. Use for project-specific tools.
17. Use per-agent allowlists when available.
18. Separate agent roles (Assistant for general, Librarian for ingestion, etc.).
19. Adversarially test retrieval. Needle-in-haystack queries. Verify citations.
20. Track metrics: precision@K, recall@K, context relevancy, citation fidelity, cost/latency.

## OpenClaw memory model (canonical)

**Layers:**
- **Immediate context window** — last ~n tokens, current turn only, not persistent.
- **Session transcript** — full dialogue log, only stored if session-memory is enabled.
- **Compaction (memory-flush)** — periodic auto-summary that writes important context to memory files.
- **MEMORY.md** — long-term, durable facts, identity, preferences. Loaded at session start.
- **memory/YYYY-MM-DD.md** — daily notes; today + yesterday auto-loaded as context.
- **DREAMS.md** — if dreaming enabled, narrative consolidation; human-review only, not fed back.

**Tools:**
- `memory_search` — semantic search over indexed memory (SQLite).
- `memory_get` — exact retrieval by file + line.

**Engines:**
- **Builtin SQLite** — FTS keywords + optional vector embeddings. Default. Always available.
- **QMD** — local sidecar, BM25 + vector + reranker (local LLM). Higher precision, higher cost.

**Plugins:**
- **memory-core (active-memory)** — default. Provides search/get tools; handles dreaming if enabled.
- **memory-wiki** — optional. Compiles curated knowledge into a wiki with claims + evidence. Separate `wiki` corpus.

**External indexed knowledge:** `memorySearch.extraPaths` — read-only Markdown folders, indexed and searchable, separate from MEMORY.md.

**Skills:** action modules, not memory. Never used as a knowledge store.

## What loads automatically

- MEMORY.md
- Today's and yesterday's `memory/YYYY-MM-DD.md`
- Configured plugins/skills

## What needs retrieval

- Anything older than the window.
- Daily notes beyond yesterday.
- Files in `extraPaths`.

## What belongs where

- **MEMORY.md** → durable personal: preferences, long-term decisions, identity traits. Concise, high-signal.
- **`openclaw-knowledge/processed/markdown/`** → business docs, research, prompt libraries, technical notes. Indexed, searchable, never merged into MEMORY.md.
</content>
</invoke>
<invoke name="exec">
<parameter name="command">cd /home/clawadmin/.openclaw/workspace && openclaw --version 2>&1 | head -5; echo "---memory status---"; openclaw memory status 2>&1 | head -30; echo "---config show---"; openclaw config get 2>&1 | head -40