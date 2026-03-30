# Memory is the bottleneck

## Key Facts

- Context length ≠ usable memory; recall degrades past 32k tokens
- Semantic search (embedding + vector DB) outperforms naive context stuffing
- Hybrid retrieval: 60% vector, 40% keyword (FTS5), with MMR re-ranking
- Latency: 45ms average from query to result across 24,700 chunks
- Top models for recall: qwen3-vl-embedding-8b, bge-m3, e5-mistral-7b

## Connected Topics

- [[local-models-are-the-fast-layer]] — Fast inference enables real-time memory-augmented workflows
- [[ollama-embedding-setup]] — Operational setup for local embedding pipelines
- [[vault-philosophy]] — Memory-first design in knowledge systems

## Agent Notes

- [2026-03-11] memory_search p95 was 180ms — upgraded to RTX 5090, now 45ms
- [2026-03-13] Switched from pure vector to hybrid retrieval — precision up 31%
- [2026-03-15] Implemented MMR diversification — fewer redundant results
- [2026-03-16] Indexed 24,700 chunks from vault, memory, and session transcripts
- [2026-03-17] memory-query agent now caches frequent patterns — 28% hit rate
- [2026-03-18] Temporal decay applied: 60-day half-life for recency boosting
- [2026-03-19] memory-bridge now preloads context for Codex tasks
- [2026-03-20] memory_search now first step in every project session