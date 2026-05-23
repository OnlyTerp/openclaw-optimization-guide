# TOOLS.md — one-liners only

## Env (Openclaw-s-2vcpu-2gb-nyc1)

- Memory: SQLite+FTS5 `~/openclaw-knowledge/db/memory.sqlite` · Qdrant `localhost:6333` (`corvus_memory`) · LanceDB `~/openclaw-knowledge/db/lancedb` · Redis `localhost:6379` (24h TTL)
- venv: `source ~/openclaw-knowledge/sandbox/venvs/core/bin/activate`

## Scripts (in `scripts/`)

- `retrieve.py` — tri-engine hybrid search
- `retrieve_verbatim.py` — exact chunk lookup
- `coparent_message_audit.py` — BIFF auditor (approval-gated)
- `brand_voice_check.py` — CR/VFD clarity gate
- `business_context_router.py` — mode/model/lane router
- `generate_pdf_report.py` — PDF from Markdown
- `promote_memory_candidate.py` — approval-gated MEMORY.md promotion

## Providers

- Anthropic: haiku-4-5, sonnet-4-6, opus-4-7 (`ANTHROPIC_API_KEY`)
- OpenAI: text-embedding-3-small (`OPENAI_API_KEY`)
- Groq: llama-3.3-70b, llama-3.1-8b-instant (`GROQ_API_KEY`)
- OpenRouter: mistral-small-2603 (`OPENROUTER_API_KEY`)
- Gemini: gemini-2.0-flash (`GEMINI_API_KEY`)

Full guidance + examples: `vault/06_system/tools-full.md`.
