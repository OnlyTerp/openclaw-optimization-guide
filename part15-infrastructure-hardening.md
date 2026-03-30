# Part 15: Infrastructure Hardening (Stop Crashing Yourself)

Your OpenClaw setup probably has hidden landmines that cause crash loops, GPU contention, and rate limit spirals. We found all of ours in one session. Here's what to check and how to fix each one.

---

## The Compaction Crash Loop

### The Problem

OpenClaw uses a model to "compact" (summarize) old conversation history when sessions get long. By default, this uses whatever model your Google plugin provides — usually **Gemini 2.5 Flash**.

When you hit Gemini's rate limit (1M tokens/min), compaction starts failing with 429 errors. Instead of backing off, it **retries immediately** — creating an infinite loop:

```
compaction: Full summarization failed (429 quota exceeded)
compaction: Partial summarization also failed (429)
compaction: Full summarization failed (429)
... every 2 seconds, forever
```

This makes OpenClaw "crash" when you open a chat — the gateway is stuck in a compaction retry loop.

### The Fix

Set an explicit compaction model that won't rate-limit you:

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "model": "cerebras/qwen-3-235b-a22b-instruct-2507",
        "mode": "safeguard",
        "reserveTokens": 15000
      }
    }
  }
}
```

**Why Cerebras?** 3,000 tokens/second, generous rate limits, and the 235B MoE model produces quality summaries.

**Never use for compaction:** Gemini Flash (rate limits), expensive models like Opus (waste of money for summarization).

---

## The Gemini Flash Trap

### The Problem

Gemini 2.5 Flash sneaks into more places than you realize:

| Subsystem | What It Does | Why Flash Is Bad Here |
|-----------|-------------|----------------------|
| **Compaction** | Summarizes old messages | Rate limits → crash loop |
| **Slug generation** | Names your sessions | Timeouts → errors in logs |
| **Session memory hooks** | Saves session context | Rate limits → data loss |
| **Auto-capture hooks** | Extracts learnings | Rate limits → missed captures |
| **Agent fallbacks** | Backup when primary fails | Also rate-limited when you need it most |
| **Web search grounding** | Powers `web_search` tool | Shares quota with everything else |

When multiple subsystems hit Flash simultaneously, you blow through the quota instantly. One agent doing research + compaction + session saves = 3+ concurrent Flash calls = instant rate limit.

### The Fix

**1. Audit every Flash reference:**
```powershell
Select-String -Path ~/.openclaw/openclaw.json -Pattern "gemini-2.5-flash"
```

**2. Replace in priority order:**
- Compaction model → Cerebras or local model
- Agent fallbacks → Cerebras qwen235b
- Web search provider → Tavily

---

## GPU Contention: The Embedding Server Problem

### The Problem

If you run a local embedding server on the same GPU you game/infer on:

- Embedding server allocates 15GB+ VRAM (Qwen3-VL-8B in FP16)
- CUDA "already borrowed" errors → embedding server crashes
- Kill embedding server to game → memory system dies

### The Fix: Dedicated GPU + INT8 Quantization

Move the embedding server to a second GPU and quantize to INT8:

```python
from transformers import AutoModel, BitsAndBytesConfig

quantization_config = BitsAndBytesConfig(load_in_8bit=True)
model = AutoModel.from_pretrained(
    "Qwen/Qwen3-Embedding-8B",
    quantization_config=quantization_config,
    device_map="auto",
    trust_remote_code=True,
)
```

| Model | FP16 VRAM | INT8 VRAM | Dimensions |
|-------|-----------|-----------|------------|
| Qwen3-VL-Embedding-8B | 15GB | N/A | 4096 |
| **Qwen3-Embedding-8B** | **14GB** | **7.6GB** | **4096** |
| BAAI/bge-large-en-v1.5 | 1.25GB | N/A | 1024 |

**Key insight:** Use `Qwen3-Embedding-8B` (text-only), NOT `Qwen3-VL-Embedding-8B` (vision). Same 4096 dims, same quality, but the text-only variant quantizes cleanly to INT8 at 7.6GB.

### OpenAI-Compatible Server

Build your embedding server with OpenAI-compatible endpoints so OpenClaw works out of the box:

```
GET  /health           → server status, VRAM usage
GET  /v1/models        → model list
POST /v1/embeddings    → OpenAI-format embedding generation
```

Config:
```json
{
  "memorySearch": {
    "provider": "openai",
    "remote": {
      "baseUrl": "http://127.0.0.1:8100/v1/",
      "apiKey": "local"
    },
    "model": "Qwen3-Embedding-8B"
  }
}
```

All agents inherit from `agents.defaults` — one config change, all 11+ agents updated.

---

## Web Search: Tavily Over Gemini Grounding

### Why Switch

Gemini grounding shares the same rate limit pool as all other Gemini API calls. Heavy research + compaction + hooks = quota exhaustion.

### Config

```json
{
  "tools": {
    "web": {
      "search": {
        "enabled": true,
        "provider": "tavily"
      }
    }
  },
  "plugins": {
    "entries": {
      "tavily": {
        "enabled": true,
        "config": {
          "webSearch": {
            "apiKey": "your-tavily-api-key",
            "baseUrl": "https://api.tavily.com"
          }
        }
      }
    }
  }
}
```

Tavily is built for AI agents — structured results, `search_depth=advanced`, no shared quota with other subsystems.

---

## The Hardening Checklist

- [ ] Compaction model set explicitly (not defaulting to Flash)
- [ ] All agent fallbacks point to reliable providers (Cerebras, Groq, local)
- [ ] Web search uses Tavily (not Gemini grounding)
- [ ] Embedding server on dedicated GPU (not shared with gaming/inference)
- [ ] Embedding model quantized to INT8 if VRAM-constrained
- [ ] No Gemini Flash in any infrastructure role
- [ ] Config backed up before changes
- [ ] Gateway restarted after config changes

### Verify

After hardening, these errors should be gone from your logs:
```powershell
Select-String -Path C:\tmp\openclaw\openclaw-*.log -Pattern "429|quota exceeded|already borrowed|database is locked"
```

---

*Added 2026-03-30 — learned the hard way so you don't have to.*
