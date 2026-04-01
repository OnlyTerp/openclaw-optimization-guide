# Part 11: Auto-Capture Hook (Stop Manually Writing Memory)

*By Terp - [Terp AI Labs](https://x.com/OnlyTerp)*

---

The vault system from Part 9 is powerful, but there's a gap: you have to manually write knowledge to vault files. In practice, after a long session, you forget. Insights from debugging sessions, configuration discoveries, architectural decisions — they disappear when the context compacts or you reset.

> **⚠️ This is NOT the same as OpenClaw's built-in `session-memory` hook.** The built-in hook just dumps raw conversation text to a dated markdown file. It does NOT extract knowledge — no decisions, no lessons, no claim-named files. If you enabled `session-memory` and thought you were done, you're not. You need THIS custom hook for real auto-capture. The built-in one is a session saver, not a knowledge extractor.

ByteRover (a community plugin on ClawHub) solves this with an `afterTurn` hook that curates every conversation turn. But it depends on an external `brv` binary that inherits your full environment and conversation content. We built the same thing natively using OpenClaw's hook system — no external binary, no trust issues, your own models.

---

## How It Works

The auto-capture hook fires on three events:
- **`/new`** — when you start a new session (captures the session that just ended)
- **`/reset`** — same
- **`session:compact:before`** — right before compaction, when the session is richest

On each trigger it:
1. Reads the session transcript (`.jsonl` file)
2. Extracts the last 30 user/assistant messages, strips metadata noise
3. Skips if fewer than 4 user messages (too short to extract from)
4. Calls **Cerebras qwen235b** ($0, ~3 seconds) with an extraction prompt
5. Gets back claim-named notes as JSON
6. Writes each note to `vault/00_inbox/` as a `.md` file

Runs entirely async — fires and forgets. You never feel it.

---

## Installation

### 1. Create the hook directory

```bash
mkdir -p ~/.openclaw/hooks/auto-capture
cd ~/.openclaw/hooks/auto-capture
git init  # Codex requires a git repo
```

### 2. Copy the hook files

Copy [`hooks/auto-capture/HOOK.md`](./hooks/auto-capture/HOOK.md) and [`hooks/auto-capture/handler.ts`](./hooks/auto-capture/handler.ts) from this repo into `~/.openclaw/hooks/auto-capture/`.

Or clone this repo and symlink:
```bash
ln -s /path/to/openclaw-optimization-guide/hooks/auto-capture ~/.openclaw/hooks/auto-capture
```

### 3. Set environment variables

The handler reads config from environment variables. Set these before starting your gateway:

**Option A: Cerebras (free, recommended)**
```bash
# Get a free key at https://cloud.cerebras.ai/
export CEREBRAS_API_KEY="csk-your-key-here"
```

**Option B: Anthropic (if you're on Claude Max and don't want another provider)**
```bash
export AUTOCAPTURE_API_URL="https://api.anthropic.com/v1/messages"
export AUTOCAPTURE_API_KEY="sk-ant-your-key-here"
export AUTOCAPTURE_MODEL="claude-sonnet-4-20250514"
```

**Option C: Any OpenAI-compatible API**
```bash
export AUTOCAPTURE_API_URL="https://your-provider.com/v1/chat/completions"
export AUTOCAPTURE_API_KEY="your-key"
export AUTOCAPTURE_MODEL="model-name"
```

The inbox path auto-detects to `~/.openclaw/workspace/vault/00_inbox`. Override with:
```bash
export AUTOCAPTURE_INBOX="/custom/path/to/vault/00_inbox"
```

### 4. Enable and restart

```bash
openclaw hooks enable auto-capture
openclaw gateway restart
```

Verify it's running:
```bash
openclaw hooks list
# Should show: 🧠 auto-capture ✓
```

---

## What Gets Saved

The model is instructed to extract only durable knowledge:
- Technical decisions and why they were made
- Facts about projects, tools, infrastructure, configurations
- Bugs found and how they were fixed
- Lessons learned
- Model/library version information

It skips:
- Small talk
- Questions with simple factual answers
- Anything that won't be relevant in a month

Each note gets a **claim-based filename** — the filename IS the knowledge:
```
threading-lock-prevents-cuda-concurrent-errors.md
winrm-requires-allowunencrypted-true-for-basic-auth.md
qwen3-vl-embedding-8b-is-top-mmeb-model.md
```

---

## What Doesn't Get Saved (By Design)

The hook reads the transcript from disk but does NOT have access to tool call results, exec outputs, or file contents — only the text of user/assistant messages. This is intentional: it means only information that was explicitly discussed ends up in the vault, not raw command output.

---

## Example Output

After a session debugging an embedding server:

```
vault/00_inbox/
├── cuda-graph-capture-fails-on-windows-with-concurrent-requests.md
├── threading-lock-serializes-gpu-calls-prevents-already-borrowed-error.md
├── winrm-non-interactive-session-blocks-cuda-model-load.md
├── qwen3-vl-requires-device-map-cuda-not-to-device-call.md
└── torch-compile-max-autotune-broken-on-windows.md
```

Each file is a standalone, searchable knowledge note. Next session, `memory_search("CUDA concurrent requests")` finds these immediately.

---

## Comparing to ByteRover

| | ByteRover | Auto-Capture Hook |
|---|---|---|
| **Trigger** | After every turn | /new, /reset, compact |
| **External binary** | Yes (brv CLI) | No |
| **Your env vars exposed** | Yes (to brv process) | No |
| **Model** | brv's internal model | Your choice (default: Cerebras $0) |
| **Destination** | brv's internal store | Your vault/00_inbox/ |
| **Integrates with vault** | No | Yes (claim-named .md files) |
| **Cost** | brv pricing | $0 (Cerebras free tier) |

ByteRover captures more (every turn vs session end), but at the cost of trusting an external binary with your conversation content. Auto-capture is native, zero-cost, and writes directly into your existing vault structure.

---

## Tuning

**Want it to capture more aggressively?** Lower `MIN_USER_MESSAGES` from 4 to 2.

**Want different output format?** Edit the `SYSTEM_PROMPT` constant in `handler.ts`.

**Want to use a different model?** Replace the `extractNotes()` function with any API that returns the same JSON structure.

**Want it to fire more often?** Add `"message:received"` to the events list in `HOOK.md` — but be careful, this fires on every single message.
