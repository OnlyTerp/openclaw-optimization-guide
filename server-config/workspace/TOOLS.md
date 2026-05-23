# TOOLS.md — one-liners

## Env (Openclaw-s-2vcpu-2gb-nyc1)

- Memory: SQLite+FTS5 `db/memory.sqlite` · Qdrant `:6333` (`corvus_memory`) · LanceDB `db/lancedb` · Redis `:6379`
- venv: `source ~/openclaw-knowledge/sandbox/venvs/core/bin/activate`

## Scripts (`scripts/`)

- `retrieve.py` / `retrieve_verbatim.py` — hybrid search / exact lookup
- `coparent_message_audit.py` — BIFF auditor (approval-gated)
- `brand_voice_check.py` — CR/VFD clarity gate
- `business_context_router.py` — mode/model/lane router
- `generate_pdf_report.py` · `promote_memory_candidate.py`

## Providers

- Anthropic: haiku-4-5, sonnet-4-6, opus-4-7
- OpenAI: text-embedding-3-small · Groq: llama-3.3-70b, llama-3.1-8b-instant
- OpenRouter: mistral-small-2603 · Gemini: gemini-2.0-flash

Full reference: `vault/06_system/tools-full.md`.
