# Part 15: Infrastructure Hardening (Stop Crashing Yourself)

Your OpenClaw setup probably has hidden landmines that cause crash loops, GPU contention, and rate limit spirals. We found all of ours in one session. Here's what to check and how to fix each one.

---

> **Read this if** you're running OpenClaw in production, have more than one user on it, or have ever hit a gateway crash loop, GPU contention, or a secret leak in an approval prompt.
> **Skip if** you're experimenting on a single-user dev box and don't mind restarting every few hours.

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

### The Reserve-Token Trap on Small Local Models (fixed in 2026.4.15)

If you pointed `compaction.model` at a small local model (a 14B Qwen with a 16K-32K context window), you could hit a *different* infinite loop. When `reserveTokens` was larger than the model's context window, compaction would compute "I need to free more tokens than this model even accepts" — fail — retry — forever. Same crash-loop symptom, different root cause.

2026.4.15 caps the reserve-token floor at the model's actual context window. If you're running a small local compaction worker, **upgrade to 2026.4.15 or later** and this class of loop is gone. If you can't upgrade yet, keep `reserveTokens` strictly under your compaction model's window (e.g. `reserveTokens: 4000` on a 16K-context model — never higher than ~25% of the window).

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

## Secret Leak Prevention: Your AI Is Leaking Your Keys

### The Problem

GitGuardian's 2026 report found that **Claude Code-assisted commits leak secrets at 3.2%** — roughly **double the GitHub baseline**. Two CVEs were published against Claude Code for API key exfiltration. If you're using AI coding agents to make commits, your API keys, passwords, and tokens are statistically more likely to end up in your git history.

This isn't theoretical. Anthropic themselves just shipped their entire Claude Code source code in a `.map` file on npm (March 31, 2026). If a $10B AI safety company can't keep their own files out of public packages, what chance do the rest of us have without explicit safeguards?

### Where Secrets Hide in OpenClaw

| File | Risk | Contains |
|------|------|----------|
| `openclaw.json` | 🔴 CRITICAL | API keys for every provider (Anthropic, OpenRouter, Google, xAI, Cerebras) |
| `auth-profiles.json` | 🔴 CRITICAL | OAuth tokens, refresh tokens, account IDs |
| `agents/*/sessions/*.jsonl` | 🟡 HIGH | Full conversation transcripts — may contain keys discussed in chat |
| `memory/*.md` | 🟡 HIGH | Session summaries — may contain passwords, IPs, credentials mentioned in sessions |
| `*.sqlite` | 🟠 MEDIUM | Vector DB with text chunks from all indexed files — searchable for secrets |

### The Fixes

**1. Add `.gitignore` to your `.openclaw/` directory:**

```gitignore
# Secrets - NEVER commit
openclaw.json
openclaw.json.*
auth-profiles.json
*.sqlite
*.sqlite-wal
*.sqlite-shm

# Session transcripts contain secrets in conversation
agents/*/sessions/*.jsonl
agents/*/sessions/*.jsonl.*

# Clobbered config backups
openclaw.json.clobbered.*
```

**2. Stop writing credentials into memory files.**

Add this rule to every agent's AGENTS.md:
```markdown
Never write credentials (API keys, passwords, tokens, IP+port+password combos) into memory files, session summaries, or vault entries. Reference them as "see auth config" instead.
```

**3. Scan your existing commits:**

```bash
# Check all repos for leaked secrets
git log --all -p | grep -E "sk-ant-|sk-or-v1-|AIzaSy|xai-[a-zA-Z0-9]{20}|password.*=|apiKey.*:"
```

If you find anything, rotate those keys immediately. Git history is permanent — even if you delete the file, the key is in the commit history unless you force-push a rewritten history.

**4. Consider a secrets proxy.**

After the Claude Code leak, a developer built [secretgate](https://github.com/nickcaglar/secretgate) — a local proxy that intercepts outbound AI traffic and redacts secrets before they leave your machine. Early stage (v0.6, ~170 regex patterns) but addresses the root cause: secrets shouldn't leave your machine in API calls.

### Gateway Auth Hot-Reload (new in 2026.4.15)

Before 2026.4.15, rotating a gateway auth secret required a full gateway restart — every agent, every running sub-agent, every in-flight cron job got dropped. That made rotation so painful that most operators just… didn't. Expired OAuth tokens quietly degraded half the setup.

2026.4.15 adds `secrets.reload`: drop a new value into your secret store and the gateway picks it up without restarting. New requests use the new secret; in-flight requests finish on the old one.

```bash
# Example: rotate an Anthropic key without killing the gateway
# (exact command depends on how your secrets are wired)
openclaw secrets set ANTHROPIC_API_KEY "sk-ant-new-key-here"
openclaw secrets reload   # verb varies across 2026.4.x betas—check `openclaw --help`
openclaw doctor  # confirm new key picked up
```

**Use this to finally rotate those 12-month-old keys you're embarrassed about.** Ideally wire it into a quarterly cron or your password-manager rotation policy.

### Approvals Secret Redaction (new in 2026.4.15)

When a tool call required approval, the approval prompt used to echo the full argument payload to the approver — including any API keys, tokens, or passwords the tool was about to send. A reviewer clicking "approve" on a `curl` call was reading the raw `Authorization: Bearer …` header.

2026.4.15 redacts secret-shaped strings (`sk-*`, `sk-ant-*`, `AIza*`, `xai-*`, `Bearer *`, `password=*`, etc.) from approval prompts before they reach the reviewer. The tool still receives the real values — only the approval UI sees placeholders.

**Practical impact:** if you run OpenClaw with human-in-the-loop approvals (most multi-user deployments should — see [Part 24](./part24-task-brain-control-plane.md)), upgrade. Before this fix, every approval was a credential leak to the approver.

### Gateway Tool-Name Collision Rejection (new in 2026.4.15 stable)

The 2026.4.15 stable release closed a subtle but ugly class of privilege inheritance: if a **client-supplied tool definition** normalized to the same name as a built-in tool, it used to silently *inherit* the built-in's trust envelope — in particular the local-media (`MEDIA:`) passthrough path. A malicious or poorly-vetted ClawHub skill could register a tool like `Browser` or `exec` with a trailing space that normalize-collided with a built-in and ride the built-in's trust.

2026.4.15 anchors the trusted local-media passthrough on the **exact raw name** of that run's registered built-in tools, and **rejects any client tool whose name normalize-collides with a built-in or with another client tool in the same request** — on both JSON and SSE paths — with `400 invalid_request_error`.

```
POST /v1/chat/completions
{ "tools": [ { "name": "Browser", ... } ] }
 → 400 invalid_request_error
   "client tool name collides with built-in 'browser'"
```

Practical impact:

- If you maintain skills in-house that deliberately shadow a built-in (don't — rename instead), they will start hard-failing after the upgrade.
- If you install community skills from [Part 23](./part23-clawhub-skills-marketplace.md), this is one of the structural defenses against the ClawHavoc-style supply-chain attack: even a signed-but-compromised skill can't inherit a built-in's trust by name anymore.
- Combine with: local-roots containment on webchat audio (same release), Task Brain semantic approvals ([Part 24](./part24-task-brain-control-plane.md)), and the skill scope allowlist ([Part 23](./part23-clawhub-skills-marketplace.md)).

### Gateway Crash Loop Fix

While we're hardening — if your gateway enters a crash loop because a stale process is blocking the port (we had a 10-hour outage from this), add a pre-start cleanup to your `gateway.cmd`:

```batch
rem Kill any stale node processes holding the gateway port
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":18789 " ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul
```

This kills any orphaned gateway process before starting a new one. Without this, the Scheduled Task will keep spawning and crashing every ~4 minutes indefinitely.

---

## The Hardening Checklist

- [ ] Compaction model set explicitly (not defaulting to Flash)
- [ ] `reserveTokens` safe for your compaction model's context window (2026.4.15+ caps this automatically)
- [ ] All agent fallbacks point to reliable providers (Cerebras, Groq, local)
- [ ] Web search uses Tavily (not Gemini grounding)
- [ ] Embedding server on dedicated GPU (not shared with gaming/inference)
- [ ] Embedding model quantized to INT8 if VRAM-constrained
- [ ] No Gemini Flash in any infrastructure role
- [ ] `.gitignore` in `.openclaw/` blocking secrets, sqlite, sessions
- [ ] No credentials written in memory/session files (rule in AGENTS.md)
- [ ] Existing git history scanned for leaked secrets
- [ ] Gateway startup script has stale-process cleanup
- [ ] Gateway auth hot-reload tested (2026.4.15+): rotate a test key and confirm the Canvas **Model Auth status card** picks up the new credential without a full gateway restart (backed by the `models.authStatus` gateway method)
- [ ] Approval prompts show redacted secrets, not raw values (2026.4.15+)
- [ ] Config backed up before changes
- [ ] Gateway restarted after config changes

### Verify

After hardening, these errors should be gone from your logs:
```powershell
Select-String -Path C:\tmp\openclaw\openclaw-*.log -Pattern "429|quota exceeded|already borrowed|database is locked"
```

---

*Added 2026-03-30. Updated 2026-03-31 with secret leak prevention (3.2% stat from GitGuardian) and gateway crash-loop fix.*
