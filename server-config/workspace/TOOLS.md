# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## Related

- [Agent workspace](/concepts/agent-workspace)

## Active Environment (Kevin's VPS — Openclaw-s-2vcpu-2gb-nyc1)

### Memory Engines
- SQLite + FTS5: `~/openclaw-knowledge/db/memory.sqlite` — 213 items, 12 lanes
- Qdrant: `localhost:6333` — collection: `corvus_memory`, 213 points (Docker: `sudo docker start qdrant`)
- LanceDB: `~/openclaw-knowledge/db/lancedb` — table: `documents`, 272 rows
- Redis: `localhost:6379` — session memory, TTL 24h

### Python venv
- `source ~/openclaw-knowledge/sandbox/venvs/core/bin/activate`

### Key scripts
- `scripts/retrieve.py` — tri-engine hybrid search
- `scripts/retrieve_verbatim.py` — exact chunk lookup
- `scripts/coparent_message_audit.py` — BIFF auditor (approval-gated)
- `scripts/brand_voice_check.py` — CR/VFD clarity gate
- `scripts/business_context_router.py` — mode/model/lane router
- `scripts/generate_pdf_report.py` — PDF from Markdown
- `scripts/promote_memory_candidate.py` — approval-gated MEMORY.md promotion

### Providers wired
- Anthropic: haiku-4-5, sonnet-4-6, opus-4-7 (env: ANTHROPIC_API_KEY)
- OpenAI: text-embedding-3-small (env: OPENAI_API_KEY)
- Groq: llama-3.3-70b, llama-3.1-8b-instant (env: GROQ_API_KEY)
- OpenRouter: mistral-small-2603 (env: OPENROUTER_API_KEY)
- Gemini: gemini-2.0-flash (env: GEMINI_API_KEY — free tier, upgrade for production)
