# Part 10: State-of-the-Art Embeddings (Pick the Right Local Model)

*By Terp - [Terp AI Labs](https://x.com/OnlyTerp)*

---

The main guide's one-shot prompt installs a local embedding model via Ollama. Pick the right tier for your hardware:

> **Read this if** you care about retrieval quality, you're running local embeddings, or you want to evaluate the GitHub Copilot embedding provider added in 2026.4.15.
> **Skip if** you're using cloud embeddings behind a managed memory service and don't mind the latency/cost — the defaults are fine for casual single-user setups.

## Embedding Model Tiers

| Tier | Model | Dims | RAM | Speed | Quality | Best For |
|------|-------|------|-----|-------|---------|----------|
| **Budget** | `nomic-embed-text` | 768 | ~300MB | Fast | Good | Minimal hardware, getting started |
| **Recommended** | `qwen3-embedding:0.6b` | 1024 | ~500MB | Fast | Great | Most setups (Mac Mini, laptops) |
| **Power** | `qwen3-embedding:4b` | 2048 | ~3GB | Medium | Excellent | 32GB+ RAM, want best local quality |
| **GPU Beast** | Qwen3-Embedding-8B | 4096 | ~8GB VRAM (INT8) | Fast | SOTA | Dedicated GPU (RTX 3090+, 5080+) |
| **Cloud** ⚠️ | Gemini, OpenAI, Voyage, Copilot | varies | 0 | **SLOW (2-5s)** | Excellent | **NOT recommended** — latency kills UX |

> **⚠️ Do not use cloud embeddings as your primary provider.** Every memory search round-trips to an API server, adding 2-5 seconds of latency PER QUERY. This defeats the entire purpose of fast memory search. Local embeddings respond in <100ms. Use cloud only as a fallback if you have no local option at all.

### GitHub Copilot Embeddings (new in OpenClaw 2026.4.15)

OpenClaw 2026.4.15 added a `copilot` memory-search provider. If your org already pays for Copilot Business/Enterprise, this reuses that seat for embeddings:

```json5
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "copilot",
        "model": "copilot-text-embedding"
      }
    }
  }
}
```

**When it makes sense:** a corporate deployment already standardized on Copilot that doesn't want another vendor (OpenAI, Voyage, etc.) in procurement.

**When it doesn't:** a personal/power-user setup. The latency is still cloud-cloud (2-5s round trip), you lose offline capability, and you're still better off with a local Ollama `qwen3-embedding:0.6b` that answers in <100ms for free.

**Gotcha:** Copilot embeddings share rate limits with Copilot chat completions. If you also use Copilot as an agent model, heavy memory-search traffic can starve chat — watch the new Model Auth card in Control UI for rate-limit pressure and keep a local fallback configured.

The `qwen3-embedding:0.6b` model is the sweet spot for most users — it's from the same Qwen3 family that holds #1 on MTEB, runs on anything, and blows away nomic on quality. Install via `ollama pull qwen3-embedding:0.6b`.

If you have a dedicated GPU with 16GB+ VRAM, read on for the power user setup with Qwen3-VL-Embedding-8B.

---

Here's everything we learned building a production embedding system on a Windows RTX 5090.

---

## Why nomic-embed-text Hits a Ceiling

| | nomic-embed-text | Qwen3-Embedding-8B |
|---|---|---|
| **Dimensions** | 768 | 4096 |
| **MTEB Rank** | ~Top 20 | **#1 family** |
| **Multimodal** | No | No (text-only, which is what you need for memory) |
| **Context** | 512 tokens | 8192 tokens |
| **Serving** | Ollama (GGUF) | FastAPI custom server (INT8 quantized) |
| **VRAM** | ~300MB | ~8GB (INT8) |

768-dim vectors mean less expressiveness. You get fuzzy matches where you wanted exact hits, and the model misses subtle distinctions between concepts.

Qwen3-Embedding-8B is from the Qwen3 family that holds #1 on MTEB. 4096 dimensions, 8K context, text-focused. If you have a GPU with 8GB+ VRAM, this is the upgrade.

> **Note:** We originally used Qwen3-**VL**-Embedding-8B (the vision-language variant) but switched to the non-VL text-only version. Same 4096 dims, same cache compatibility, but more stable and we don't need multimodal embeddings for markdown files. The migration from VL → non-VL was seamless — no re-indexing needed.

---

## The Architecture: Stark Edition Server

Don't just point Ollama at Qwen3-VL. Ollama uses GGUF format and can't serve this model efficiently. Instead, build a proper production embedding server — we called ours the "Stark Edition" because GPT-5.4 (Codex) built it and it's absurdly overengineered for a personal memory system.

### Core features
- **Dynamic request batching** — collects requests for up to 10ms, merges into single GPU batch
- **L1 cache** — in-memory LRU (50,000 entries), answers in <1ms
- **L2 cache** — persistent SQLite with LZ4 compression (survives reboots)
- **Pre-warm on startup** — loads last 10,000 L2 entries into L1 at boot
- **threading.Lock** — serializes GPU inference, prevents concurrent CUDA errors
- **GPU OOM recovery** — catches OOM, halves batch, retries automatically
- **Prometheus metrics** — `/health` and `/metrics` endpoints
- **Windows Scheduled Task** — auto-starts on boot, auto-restarts on failure

After the initial reindex (~5-10 min), real-world cache hit rate is 99%+. Almost every query is served from memory in <1ms. GPU only fires for brand new, never-seen-before queries.

### Full server code

The complete server lives at `scripts/qwen_embed_server_v3.py` in your local OpenClaw install (installed by the one-shot prompt — see [Part 17](./README.md#part-17-the-one-shot-prompt)). The path below assumes you're running it as a standalone script on Windows.

To run it:
```cmd
set QWEN_EMBED_PORT=8100
set QWEN_EMBED_ENABLE_TORCH_COMPILE=false
python C:\path\to\qwen_embed_server_v3.py
```

Wait for `"Warmup complete"` in the output before restarting OpenClaw.

---

## OpenClaw Config

```json5
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "openai",
        "model": "Qwen3-VL-Embedding-8B",
        "remote": {
          "baseUrl": "http://YOUR-GPU-PC-IP:8100/v1/",
          "apiKey": "local"
        },
        "query": {
          "hybrid": {
            "enabled": true,
            "vectorWeight": 0.6,
            "textWeight": 0.4,
            "candidateMultiplier": 6,
            "mmr": { "enabled": true, "lambda": 0.65 },
            "temporalDecay": { "enabled": true, "halfLifeDays": 60 }
          }
        }
      }
    }
  }
}
```

Key difference from the default config: `halfLifeDays: 60` instead of 30. Vault reference docs are evergreen — they shouldn't get penalized just because they're a month old.

---

## Windows-Specific Gotchas (Learned the Hard Way)

### 1. torch.compile crashes on Windows under concurrent load
`mode="max-autotune"` uses CUDA graph capture which is buggy on Windows when multiple requests arrive simultaneously. Always disable it:
```
set QWEN_EMBED_ENABLE_TORCH_COMPILE=false
```

### 2. CUDA "Already borrowed" error
When multiple async requests hit the GPU simultaneously, you get this cryptic error. Fix: add `threading.Lock()` around the inference call — not `asyncio.Semaphore` (which only works within the same event loop), but a real thread-level lock:
```python
self._gpu_lock = threading.Lock()

def embed_texts(self, texts):
    with self._gpu_lock:
        return self._embed_texts_impl(texts)
```

### 3. Non-interactive WinRM sessions can't load CUDA
When launching Python via WinRM (remote PowerShell), CUDA sometimes hangs forever during model load. Fix: use a Windows Scheduled Task with `LogonType = Interactive` instead. The server included in this repo has `install_service.py` which sets this up automatically.

### 4. Start the embedding server BEFORE restarting the gateway
OpenClaw floods the embedding server with ~15 simultaneous requests on startup. If the server isn't fully warmed up (torch.compile autotune takes ~3 min), the concurrent burst corrupts the CUDA context. Always wait for `"Warmup complete"` before touching the gateway.

### 5. Port 8000 vs 8100
The default config uses port 8000. The server launches on 8100 by default (to avoid conflicts with other services). Don't forget to update your OpenClaw config to match whichever port you use.

---

## Remote Control: WinRM Setup

If your embedding server runs on a separate GPU PC (common setup: TerpHQ orchestrates, 5090 PC serves), set up WinRM so your orchestrator can restart the embedding server remotely without you touching anything.

**On the GPU PC (admin PowerShell):**
```powershell
winrm quickconfig -q
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
Set-PSSessionConfiguration -Name Microsoft.PowerShell -AccessMode Remote -Force
Restart-Service WinRM
net user YourUsername YourPassword
```

**On the orchestrator PC (admin PowerShell):**
```powershell
winrm quickconfig -q
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
winrm set winrm/config/client '@{AllowUnencrypted="true"}'
```

**Test:**
```powershell
$cred = New-Object System.Management.Automation.PSCredential("Username", (ConvertTo-SecureString "Password" -AsPlainText -Force))
Invoke-Command -ComputerName GPU_PC_IP -Port 5985 -Credential $cred -Authentication Basic -ScriptBlock { "connected as $env:USERNAME" }
```

Once connected, you can restart the embedding server remotely, push updated files, check logs — all without touching the GPU PC.

---

## Real-World Results

After running this setup in production:

| Metric | nomic-embed-text | Qwen3-VL Stark Edition |
|--------|-----------------|------------------------|
| **Dimensions** | 768 | 4096 |
| **Cache hit rate** | N/A (no cache) | 99.8% |
| **Avg latency** | ~45ms (Ollama) | 14ms (cached) / 29ms (new) |
| **L2 cache entries** | None | 6,000+ after first week |
| **Concurrent requests** | Ollama queues them | threading.Lock serializes |
| **Stability** | Rock solid (simple) | Rock solid (after threading fix) |
| **Search quality** | Good | Noticeably better |

The 99.8% cache hit rate is the real win. After a week of use, almost everything you'd ever search for has been embedded and cached. You're paying 14ms for what used to cost 45ms, and the matches are meaningfully more accurate.

---

## The Upgrade Path

1. **Still getting started?** Use `nomic-embed-text` on Ollama (Part 4). Zero setup, works fine.
2. **Have a GPU with 16GB+ VRAM?** Upgrade to Qwen3-VL with the Stark Edition server.
3. **GPU PC is separate from your main PC?** Set up WinRM for remote control.

Don't over-engineer if you don't need it. But if you're running 900+ vault files and doing serious AI work, 4096-dim embeddings with persistent caching make a real difference.
