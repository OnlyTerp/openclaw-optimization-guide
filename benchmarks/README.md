All benchmarks from a production system running on Windows with RTX 5090 (embedding server) + TerpHQ gateway. Your numbers will vary based on hardware, vault size, and model choice.

## Memory Search Performance
| Metric | nomic-embed-text (768-dim) | Qwen3-VL-Embedding-8B (4096-dim) |
|--------|---------------------------|----------------------------------|
| Dimensions | 768 | 4096 |
| MMEB Rank | ~Top 20 | #1 |
| Search latency | ~45ms | ~45ms (L1 cache hit) / ~70ms (cold) |
| Index size (our system) | 73-180 chunks per agent | 24,700+ chunks per agent |
| Files indexed | 5-16 per agent | 947-962 per agent |
| Cache entries | 59-293 | 6,682-41,617 |
| Multimodal | No | Yes (text + image) |
| VRAM required | ~300MB (Ollama) | ~16GB (custom Python server) |

## Context Optimization
| Metric | Stock OpenClaw | After Optimization |
|--------|---------------|-------------------|
| Workspace context per msg | 15-20 KB | 4-5 KB |
| SOUL.md | 3-5 KB | < 1 KB (772 bytes target) |
| MEMORY.md | 5-15 KB | < 3 KB (pointers only) |
| AGENTS.md | 3-8 KB | < 2 KB (decision tree) |
| TOOLS.md | 2-5 KB | < 1 KB (one-liners) |
| Total injected | 15-30 KB | < 8 KB |
| Token cost per msg (Opus) | ~$0.25 (50K tokens) | ~$0.025 (5K tokens) |
| Response time | 4-8 sec | 1-3 sec |

## Memory Bridge Impact
| Metric | Without Bridge | With Bridge |
|--------|---------------|-------------|
| Vault chunks available to Codex | 0 | 8-18 per task |
| Past mistake repetition | Frequent | Rare |
| Architecture alignment | Guesses | Follows established patterns |
| Iteration rounds needed | 3-5 | 1-2 |
| First-attempt quality | ~60% | ~85% |

## Self-Improving System Compounding
| Week | Corrections Logged | Mistakes Avoided | HOT.md Entries | Promoted to AGENTS.md |
|------|-------------------|------------------|----------------|----------------------|
| 1 | ~5 | 0 | 0 | 0 |
| 2 | ~12 | ~3 | ~3 | 0 |
| 4 | ~25 | ~10 | ~8 | ~2 |
| 8 | ~40 | ~25 | ~12 | ~5 |
| 12 | ~50 | ~35+ | ~15 | ~8 |

(Projected based on daily usage patterns. Actual numbers will vary.)

## Vault System
| Metric | Flat Files | Vault + MOCs |
|--------|-----------|-------------|
| Total files | 358 (date-named) | 951+ (claim-named) |
| Search method | Vector only | Vector + graph traversal |
| Wiki-links | 0 | 71+ bidirectional |
| MOC pages | 0 | 8+ in 01_thinking/ |
| Cross-session memory | None | Agent Notes breadcrumbs |
| Search relevance | 15 partial matches, 3 useful | 3-5 connected results |

## Agent Reindex (768→4096 dim)
| Agent | Before (nomic) | After (Qwen3-VL) |
|-------|---------------|------------------|
| ops | 951 files, 24,733 chunks, 768-dim | 951 files, 24,752 chunks, 4096-dim |
| alpha | 5 files, 73 chunks, 768-dim | 950 files, 24,789 chunks, 4096-dim |
| content | 4 files, 42 chunks, 768-dim | 949 files, 24,758 chunks, 4096-dim |
| scout | 2 files, 24 chunks, 768-dim | 947 files, 24,738 chunks, 4096-dim |
| godmode | 16 files, 180 chunks, 768-dim | 962 files, 24,860 chunks, 4096-dim |

## SWE-bench Coding Model Rankings (March 2026)
| Rank | Model | Score |
|------|-------|-------|
| #1 | Claude Opus 4.6 | 1549 |
| #2 | Claude Opus 4.6 (thinking) | 1545 |
| #3 | Claude Sonnet 4.6 | 1524 |
| #6 | GPT-5.4 | 1457 |