# OpenClaw Optimization Guide
### Make Your OpenClaw AI Agent Faster, Smarter, and Actually Useful
#### Speed optimization, memory architecture, context management, model selection, and one-shot development for OpenClaw

*By Terp — [Terp AI Labs](https://x.com/OnlyTerp)*

---

## Table of Contents

1. [Speed](#part-1-speed-stop-being-slow) — Trim context files, add fallbacks, manage reasoning mode
2. [Context Bloat](#part-2-context-bloat-the-silent-performance-killer) — Why 50% context = broken, quadratic scaling, built-in defenses
3. [Cron Session Bloat](#part-3-cron-session-bloat-the-hidden-killer) — Session file accumulation, cleanup, isolated sessions
4. [Memory](#part-4-memory-stop-forgetting-everything) — 3-tier memory system, Ollama vector search, vault architecture
5. [Orchestration](#part-5-orchestration-stop-doing-everything-yourself) — Sub-agent delegation, CEO/COO/Worker model
6. [Models](#part-6-models-what-to-actually-use) — Provider comparison, pricing, local models, membership setup
7. [Web Search](#part-7-web-search-give-your-agent-eyes-on-the-internet) — Tavily, Brave, Serper, Gemini grounding comparison
8. [One-Shotting Big Tasks](#part-8-one-shotting-big-tasks-stop-iterating-start-researching) — Research-first methodology, spec-driven development
9. [Quick Checklist](#part-9-quick-checklist) — 30-minute setup checklist
10. [The One-Shot Prompt](#part-10-the-one-shot-prompt) — Copy-paste automation prompt

---

## The Problem

If you're running a stock OpenClaw setup, you're probably dealing with some of these:

- **Freezing and hitting context limits.** Your workspace files are so bloated that the model runs out of context window on complex tasks. It just stops mid-response.
- **Slow responses.** Every message injects 15-20KB+ of context files the model has to read before it can even start answering. That's hundreds of milliseconds of latency on every single reply.
- **Forgetting everything.** New session = blank slate. Your bot doesn't remember what you built yesterday, what decisions you made last week, or what your preferences are. You're re-explaining context constantly.
- **Inconsistent behavior.** Without clear rules, the bot's personality drifts. Sometimes it's helpful, sometimes it's verbose, sometimes it ignores your preferences entirely.
- **Doing everything the expensive way.** Your main model writes code, does research, AND orchestrates — all at top-tier pricing. No delegation.
- **Flying blind.** Your agent can't search the web, so it guesses at anything after its training cutoff. No grounding, no real-time info.
- **No idea which model to use.** You picked whatever was default and never looked back. You're either overpaying or underperforming.

## What This Fixes

After this setup, your bot:

- **Responses feel instant.** 4-8 second lag drops to near-instant on most queries. Less context to process = faster time to first token.
- **Memory actually works.** Your bot references things from weeks ago correctly — not just the most recent session. Projects, people, decisions, preferences — all instantly retrievable.
- **No context ceiling.** Long sessions don't degrade. You'll never hit context limits on normal conversations again because context stays under 8KB.
- **Multitask while working.** Give a second task while the first is still running. The agent spawns sub-agents for heavy work and stays conversational with you.
- **Stays consistent.** A lean SOUL.md with clear rules means the bot's personality and behavior are the same every session. It follows YOUR rules, not its defaults.
- **$0 memory cost.** All vector search runs locally via Ollama. Nothing leaves your machine. No cloud database fees.
- **Grounded in reality.** Web search gives your agent real-time information instead of guessing from stale training data.
- **Right model for each job.** Your orchestrator uses a frontier model. Sub-agents use fast/cheap models. Code goes to coding models. You stop overpaying.

**The key insight:** Your workspace files become **lightweight routers, not storage.** All the actual knowledge lives in a local vector database on your machine. The bot only loads exactly what it needs for the current question — not everything it's ever learned.

### How It Works

```
You ask a question
    ↓
Orchestrator (main model, lean context ~5KB)
    ↓
┌─────────────────────────────────────────┐
│  memory_search() — 45ms, local, $0     │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │MEMORY.md│→ │memory/*.md│→ │vault/* │ │
│  │(index)  │  │(quick)   │  │(deep)  │ │
│  └─────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────┘
    ↓
Only relevant context loaded (~200 tokens)
    ↓
Fast, accurate response + sub-agents for heavy work
```

### Real Numbers

```
                    Before          After
Context per msg:    15-20 KB        4-5 KB
Time to respond:    4-8 sec         1-2 sec
Memory recall:      Forgets daily   Remembers weeks
Token cost/msg:     ~5,000 tokens   ~1,500 tokens
Long sessions:      Degrades        Stable
Concurrent tasks:   One at a time   Multiple parallel
```

### What The Optimized Files Look Like

Here's a peek at the template files (full versions in [`/templates`](./templates)):

**SOUL.md** (772 bytes — injected every message):
```markdown
## Who You Are
- Direct, concise, no fluff. Say the useful thing, then stop.
- Have opinions. Disagree when warranted. No sycophancy.

## Memory Rule
Before answering about past work, projects, people, or decisions:
run memory_search FIRST. It costs 45ms. Not searching = wrong answers.

## Orchestrator Rule
You coordinate; sub-agents execute. Never write 50+ lines of code yourself.
```

**MEMORY.md** (581 bytes — slim pointer index):
```markdown
## Active Projects
- Project A → vault/projects/project-a.md
- Project B → vault/projects/project-b.md

## Key People
- Person A — role, relationship → vault/people/person-a.md
```

That's it. The details live in vault/. The bot finds them via vector search in 45ms.

This isn't a settings tweak. It's a **complete architecture change** — memory routing, context engineering, and orchestration — that work together. The vector search is what makes small files possible. The small files are what make it fast. The orchestration is what makes it affordable. They're connected.

**The one-shot prompt at the bottom does the entire setup automatically.** One paste into your OpenClaw bot, walk away, done.

These are the exact optimizations I run daily on my own setup. Not theoretical — battle-tested over weeks of heavy use.

> **Note:** Tested and confirmed working with Claude Opus 4.6. Other frontier models (Sonnet, GPT, Gemini, etc.) should work if they can follow multi-step instructions. Haven't confirmed all of them yet.

> **Templates included:** Check the [`/templates`](./templates) folder for ready-to-use versions of SOUL.md, AGENTS.md, MEMORY.md, TOOLS.md, and a sample vault/ structure. Copy them directly into your workspace as a starting point.

---

## Part 1: Speed (Stop Being Slow)

Every message you send, OpenClaw injects ALL your workspace files (SOUL.md, AGENTS.md, MEMORY.md, TOOLS.md) into the prompt. If those files are bloated, every single reply is slower and more expensive. This is the #1 speed issue people don't realize they have.

### Why Trimming Works (It's Not Just About Size)

The key insight: **you don't need big files anymore once you have vector search.**

Old approach: Stuff everything into MEMORY.md so the bot "sees" it every message. Result: 15KB+ context, slow responses, wasted tokens on info that's irrelevant to the current question.

New approach: MEMORY.md is a slim index of pointers. Full details live in vault/ files. When the bot needs something, `memory_search()` finds it instantly via vector embeddings (local Ollama, $0). The bot only loads what's relevant to RIGHT NOW.

This means your workspace files can be tiny without losing any knowledge. The knowledge just moves from "always loaded" to "loaded on demand."

### Trim Your Context Files

| File | Target Size | What Goes In It | Why This Size |
|------|------------|-----------------|---------------|
| SOUL.md | < 1 KB | Personality, tone, core rules | Injected EVERY message — every byte costs latency |
| AGENTS.md | < 2 KB | Decision tree, tool routing | Needs to fit in working memory, not be a manual |
| MEMORY.md | < 3 KB | **Pointers only** — NOT full docs | Vector search replaces the need for big files |
| TOOLS.md | < 1 KB | Tool names + one-liner usage | Just reminders, not documentation |
| **Total** | **< 8 KB** | Everything injected per message | Down from 15KB+ = 50-66% faster |

**Before:** 15 KB injected per message. Bot reads everything every time, even if 90% is irrelevant.
**After:** 5 KB injected per message. Bot loads detailed knowledge on-demand via vector search.

The rule: if it's longer than a tweet thread, it's too long for a workspace file. Move the details to vault/.

### Add a Fallback Model

Whatever your main model is, add a faster/cheaper model as fallback for when it's rate-limited or for simple tasks:

```json
"fallbackModels": ["your-provider/faster-cheaper-model"]
```

For example: if your main model is a large reasoning model, set a smaller/faster model from the same provider as fallback. OpenClaw automatically switches when needed.

### Reasoning Mode — Know the Tradeoff

Run `/status` in your chat to see your current reasoning mode.

- **Off** — fastest, no thinking phase
- **Low** — slight thinking, faster responses
- **High** — deep reasoning before every answer, adds 2-5 seconds

I personally run on **high** and keep it there. Yes it's slower, but the quality difference is massive — high reasoning catches things that get missed on low/off. Complex debugging, architecture decisions, multi-step planning — high reasoning is worth every second of delay.

If speed matters more than quality for your use case, drop to low. But if you want the best answers possible, stay on high. The context trimming from the other steps more than compensates for the reasoning overhead.

### Disable Unused Plugins

Every enabled plugin adds overhead. If you're not actively using `memory-lancedb`, `memory-core`, or other plugins, disable them:

```json
"enabled": false
```

### Ollama Housekeeping

If Ollama is running on your machine, check what's loaded:

```bash
ollama ps
```

If a big model (7B+) is sitting idle in memory, unload it:

```bash
ollama stop modelname
```

The only model you need loaded for memory search is `nomic-embed-text` (300 MB). Everything else should be loaded on-demand.

---

## Part 2: Context Bloat (The Silent Performance Killer)

You trimmed your workspace files. Good. But do you know *why* that actually matters? Context bloat isn't just "my files are big" — it's a fundamental physics problem with how LLMs work, and most people don't realize how bad it gets.

### The Quadratic Problem

Every LLM uses an attention mechanism that scales **quadratically** with context length. That means:

- **2x the tokens = 4x the compute cost**
- **3x the tokens = 9x the compute cost**

This isn't linear. It's exponential. When your context goes from 50K to 100K tokens, the model isn't doing twice the work — it's doing **four times** the work. That directly translates to slower responses and higher bills.

### What Happens at 50% of Your Context Window

If you're running a model with a 1M token context window (like Claude Opus or Gemini Pro), you might think "I've got plenty of room." You don't.

Real-world benchmarks show:

- **11 out of 12 models** tested dropped below 50% accuracy by just 32K tokens
- **GPT-4.1** showed a **50x increase in response time** at ~133K tokens — it hit a wall
- Models exhibit **"lost-in-the-middle" bias** — they pay attention to the beginning and end of context but literally lose track of information buried in the middle
- By the time you're at 500K tokens (50% of a 1M window), you're experiencing significant latency spikes, accuracy drops, and cost explosions

**The takeaway:** Just because a model *advertises* 1M context doesn't mean it *performs well* at 1M. Effective context is usually a fraction of the max.

### Where Bloat Actually Comes From

It's not just your workspace files. Context accumulates from multiple sources in every single message:

| Source | Typical Size | Injected When |
|--------|-------------|---------------|
| System prompt | 2-5 KB | Every message |
| Workspace files (SOUL, AGENTS, MEMORY, TOOLS) | 5-20 KB | Every message |
| Conversation history | Grows per turn | Every message |
| Tool results (exec, read, web_search) | 1-50 KB each | After tool calls |
| Skill files | 1-5 KB each | When skill activates |
| Bootstrap/context files | 1-10 KB | Session start |

In agentic workflows, **tool spam** is the worst offender. Every tool call dumps its full output into the context. A single `exec` that returns a large file read? That's 20K+ tokens added permanently to your session. Five tool calls in a row? You just burned 100K tokens of context space that the model has to re-read on every subsequent message.

### The Cost Math

Providers charge per token. Here's what context bloat actually costs you:

```
Lean context (5K tokens/msg):
  → Claude Opus: $0.025/msg input + $0.0025 cached
  
Bloated context (50K tokens/msg):
  → Claude Opus: $0.25/msg input + $0.025 cached
  
That's 10x more per message. Over 100 messages/day = $22.50/day vs $2.25/day.
```

Even with caching, you're paying for every token on the first write. And if your session goes idle past the cache TTL? You re-cache the entire bloated context at full price.

### What OpenClaw Does About It (Built-In Defenses)

OpenClaw has two built-in mechanisms most people don't know about:

**Session Pruning** — Trims old tool results from context before each LLM call. Only affects in-memory context, not your saved session history. Enable it:

```json
{
  "agents": {
    "defaults": {
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "5m"
      }
    }
  }
}
```

**Auto-Compaction** — When a session nears the context window limit, OpenClaw automatically summarizes older conversation into a compact summary and keeps recent messages intact. You can also trigger it manually with `/compact`.

**Use both.** Pruning handles tool result bloat per-request. Compaction handles conversation history bloat over time. Together they keep your context lean without you thinking about it.

### Your Context Bloat Checklist

- [ ] Workspace files under 8 KB total (you did this in Part 1)
- [ ] Context pruning enabled (`mode: "cache-ttl"`)
- [ ] Use `/compact` proactively when sessions feel slow or stale
- [ ] Use `/new` or `/reset` when switching topics entirely
- [ ] Delegate heavy tool work to sub-agents (their context is separate from yours)
- [ ] Monitor your context usage with `/status` — watch the token count and percentage

**The golden rule:** Your main session context should rarely exceed 10-15% of your model's context window. If `/status` shows you're above 20%, something is bloating.

---

## Part 3: Cron Session Bloat (The Hidden Killer)

If you run cron jobs — automated tasks on a schedule — there's a second type of bloat that builds up silently over weeks and months. It's not context window bloat. It's **session file bloat**.

### The Problem

Every cron job execution creates a session transcript file (`.jsonl`). These live in your agent's sessions directory and get tracked in `sessions.json`. Over time:

- **30 cron jobs × 48 runs/day × 30 days = 43,200 session files**
- Each file can be 10-100 KB depending on what the cron did
- The `sessions.json` index grows to track all of them
- Session loading slows down as the index balloons

You won't notice it at first. After a few weeks, your bot starts taking an extra second or two to respond. After a month, session management becomes a noticeable bottleneck.

### How to Spot It

Check your session file count:

```bash
# Linux/Mac
ls ~/.openclaw/agents/*/sessions/*.jsonl | wc -l

# Windows (PowerShell)
(Get-ChildItem ~\.openclaw\agents\*\sessions\*.jsonl).Count
```

If you're seeing thousands of files, you have cron session bloat.

### The Fix

**1. Configure session rotation**

OpenClaw can automatically rotate large session files. Add this to your `openclaw.json`:

```json
{
  "session": {
    "maintenance": {
      "rotateBytes": "100mb"
    }
  }
}
```

**2. Clean up old cron sessions**

Run periodic cleanup of stale session entries:

```bash
openclaw sessions cleanup
```

This prunes entries older than the configured `pruneAfter` threshold (default: 30 days).

**3. Use isolated sessions for cron**

When setting up cron jobs, use `sessionTarget: "isolated"` so each run gets its own throwaway session instead of accumulating in a shared session:

```json
{
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Do the thing"
  }
}
```

Isolated sessions don't pile up in your main agent's session history.

### Prevention > Cleanup

The best fix is not generating the bloat in the first place:

- If your cron output already saves to a database or vault file, you don't need the session transcript too
- Use `delivery: { "mode": "none" }` on crons where you don't need the output announced
- Keep cron tasks focused and small — a cron that runs 15 tool calls generates 15x more session data than one that runs 1

---

## Part 4: Memory (Stop Forgetting Everything)

Out of the box, OpenClaw forgets everything between sessions. The fix is a 3-tier memory system that makes your bot remember every project, decision, and preference.

### The Architecture

```
MEMORY.md          ← Slim index (< 3 KB), pointers only
memory/            ← Auto-searched by memory_search()
  projects.md
  people.md  
  decisions.md
vault/             ← Deep storage, searched via memory
  projects/
  people/
  decisions/
  lessons/
  reference/
  research/
```

### How It Works

1. **MEMORY.md** is your table of contents. It contains one-liner pointers to where real info lives. Never put full documents here.

2. **memory/*.md** files get automatically searched when the bot calls `memory_search("query")`. This is where you put things the bot needs to find quickly.

3. **vault/** is deep storage. Detailed project docs, research notes, full profiles. Referenced from memory/ files.

### Setting It Up

**Step 1: Install Ollama + embedding model**

```bash
# Windows
winget install Ollama.Ollama

# Mac/Linux  
curl -fsSL https://ollama.com/install.sh | sh

# Then pull the embedding model
ollama pull nomic-embed-text
```

That's it. OpenClaw detects Ollama on localhost:11434 and uses nomic-embed-text for `memory_search()` automatically. No config needed.

**Step 2: Create the directory structure**

```
workspace/
  MEMORY.md
  memory/
  vault/
    projects/
    people/
    decisions/
    lessons/
    reference/
    research/
```

**Step 3: Slim down MEMORY.md**

Your MEMORY.md should look like this:

```markdown
# MEMORY.md — Core Index
_Pointers only. Search before answering._

## Identity
- [Bot name] on [model]
- Owner: YourName, location, preferences

## Active Projects
- Project A → vault/projects/project-a.md
- Project B → vault/projects/project-b.md

## Key Tools
- Tool X: `command here`
- Tool Y: `command here`

## Key Rules  
- Rule 1
- Rule 2
```

**Step 4: Move everything else to vault/**

Every detailed document, project spec, research note — move it to vault/ and leave a one-liner pointer in MEMORY.md or memory/.

### The Golden Rule

Before answering anything about past work, projects, people, decisions, or preferences, your bot should call `memory_search()` first. Add this to your SOUL.md:

```markdown
## Memory
Before answering about past work, projects, or decisions: 
run memory_search FIRST. It costs 45ms. Not searching = wrong answers.
```

---

## Part 5: Orchestration (Stop Doing Everything Yourself)

Your main model should NEVER do heavy work directly. It should plan and delegate to cheaper, faster sub-agents.

### The Mental Model

- **You** = CEO (gives direction)
- **Your Bot (main model)** = COO (plans, coordinates, makes decisions)  
- **Sub-agents (cheaper/faster model)** = Workers (execute tasks fast and cheap)

### Add This to AGENTS.md

```markdown
## Core Rule
You are the ORCHESTRATOR. You coordinate; sub-agents execute.
- Code task (3+ files)? → Spawn coding agent
- Research task? → Spawn research agent  
- 2+ independent tasks? → Spawn ALL in parallel

## How to Spawn
sessions_spawn({
  task: "description...",
  mode: "run",
  runtime: "subagent",
  model: "your-provider/your-cheaper-faster-model"
})

## Model Strategy
- YOU (orchestrator): Your best model — planning, judgment, synthesis
- Sub-agents (workers): Cheaper/faster model — execution, code, research
```

### Why This Matters

Your main model is expensive and slow. A smaller model from the same provider is usually much cheaper and faster for execution tasks. If your bot writes 200 lines of code on your expensive model, you're overpaying. Spawn a cheaper agent for the code, let your main model focus on deciding WHAT to build.

---

## Part 6: Models (What to Actually Use)

Not all models are created equal for agent work. After weeks of daily testing across every major provider, here's what actually works — and what each model is best at.

### The Model Strategy

You don't want one model doing everything. You want the **right model for each job**:

| Role | What It Does | Best Model(s) | Why |
|------|-------------|----------------|-----|
| **Orchestrator** (main) | Plans, judges, coordinates | Claude Opus 4.6 | Best at complex reasoning, tool use, and following nuanced instructions |
| **Daily driver** | General assistant, balanced | Claude Sonnet 4.6, Gemini 3.1 Pro | Great quality at lower cost than Opus |
| **Sub-agents** (workers) | Execute delegated tasks | Gemini 3 Flash, Kimi K2.5, MiMo V2 Pro | Fast, cheap, capable enough for execution |
| **Coding** | Write/refactor code | GPT-5.3 Codex, Claude Sonnet | Purpose-built for code generation |
| **Research** | Web search, analysis | Gemini 2.5 Flash + Tavily | Built-in grounding + structured search |
| **Free tier** | Zero-cost operations | Gemini (all variants), Groq open models | $0 with generous rate limits |

### Model Deep Dive

**Claude Opus 4.6** — The Best Orchestrator
- Unmatched at multi-step reasoning and complex tool use
- Follows long, nuanced system prompts better than any other model
- Best "memory search then act" behavior — actually searches before answering
- 1M context window with prompt caching (saves up to 90% on cached tokens)
- Downside: most expensive per-token. Use it for orchestration, not execution
- **Cost (API):** $5/M input, $25/M output, $0.50/M cached read
- **Cost (Max subscription):** Included in your $100/month plan — drastically cheaper for heavy use. If you're sending 100+ messages/day on Opus, Max pays for itself in the first week

**Claude Sonnet 4.6** — The Sweet Spot
- 80% of Opus quality at 20% of the cost
- Excellent for daily driving if you don't need Opus-level reasoning
- Same 1M context window and caching benefits
- Great as a fallback when Opus is rate-limited
- Strong at coding tasks — can replace dedicated coding models for most work
- **Cost (API):** $3/M input, $15/M output, $0.30/M cached read
- **Cost (Pro subscription):** Included in your $20/month plan. Best value if Sonnet is your daily driver

> **💡 Pro tip:** Don't pay API rates for Claude if you have a subscription. Claude Pro ($20/month) covers Sonnet usage, Claude Max ($100/month) covers Opus. For power users, Max is the best value in AI right now — unlimited Opus orchestration for a flat rate instead of paying per-token. See the [membership setup guide](#using-anthropic-membership-the-best-way) below.

**Gemini 3.1 Pro / 3 Pro** — Free Powerhouse
- Legitimately competitive with Sonnet on most tasks — and it's free
- 1M context window, multimodal (text + image)
- Google's API has generous free-tier rate limits
- Excellent as a default model if you want to keep costs at $0
- Weaker than Claude on complex agentic tool-use chains
- **Cost:** Free (API key required)

**Gemini Flash (2.5 / 3)** — Speed Demon
- Fastest responses of any capable model
- Perfect for sub-agents and research tasks where speed > depth
- Same free pricing as Gemini Pro
- Flash Lite variants are even faster for simple tasks
- **Cost:** Free

**GPT-5.3 / 5.4 Pro** — OpenAI's Best
- GPT-5.4 Pro is a strong thinking model with 1M context
- Good at code and structured output
- Competitive with Claude on many tasks, slightly weaker on long agentic chains
- OpenAI's Codex models are purpose-built for code tasks — fast and cheap
- **Cost:** GPT-5.3: $1.75/M input, $14/M output | GPT-5.4 Pro: $30/M input, $180/M output

**Grok 4 / 4.1 Fast** — The Dark Horse  
- Surprisingly good at reasoning tasks
- Grok 4.20 has a massive 2M context window (largest available)
- Fast reasoning variant is great for tasks that need thinking + speed
- Grok 4.1 Fast is insanely cheap — $0.20/M input
- **Cost:** Grok 4: $3/M input, $15/M output | Grok 4.1 Fast: $0.20/M input, $0.50/M output | Grok 4.20: $2/M input, $6/M output

**Kimi K2.5** — Budget Sub-Agent King
- Multimodal, 262K context, strong instruction following
- Excellent price-to-performance for delegated tasks
- Available via OpenRouter with Fireworks backend for fast inference
- Perfect for sub-agents that need to be capable but cheap
- **Cost:** $0.45/M input, $2.20/M output

**MiMo V2 Pro (Xiaomi)** — The Sleeper
- 1T parameter model with 1M context window
- Surprisingly capable for an open-weight model
- Good for agentic tasks via OpenRouter
- Great as a sub-agent model when you need large context on a budget
- **Cost:** $1/M input, $3/M output

### OpenRouter: The Model Marketplace

[OpenRouter](https://openrouter.ai) gives you access to dozens of models through one API key. It's the easiest way to add variety to your setup without managing multiple provider accounts.

**The Free Router — `openrouter/free`**

This is a hidden gem. Point your model config at [`openrouter/free`](https://openrouter.ai/openrouter/free) and OpenRouter automatically picks the best free model for your request. It analyzes what you need (tool calling, image understanding, structured output) and routes to a capable free model. Zero cost, zero thinking about which model to use.

```json
{
  "id": "openrouter/free",
  "name": "OpenRouter Free Auto-Router"
}
```

Perfect for sub-agents where you want $0 cost and don't care which model does the work — just that it gets done.

**Notable OpenRouter Models:**

**Xiaomi MiMo V2 Pro** — *Free right now (launch week)*
- 1 trillion parameter model, 1M context window
- Launched anonymously as "Hunter Alpha" and topped OpenRouter rankings before anyone knew it was Xiaomi
- Designed specifically for agentic scenarios — tool use, multi-step planning
- **Currently free for developers** as part of the launch promotion. Try it now before pricing kicks in
- Normal pricing: $1/M input, $3/M output
- Add it: `openrouter/xiaomi/mimo-v2-pro`

**Kimi K2.5 (Moonshot AI)** — Budget Powerhouse
- 262K context, multimodal, strong instruction following
- $0.45/M input, $2.20/M output — one of the best price-to-performance ratios
- Excellent for delegated sub-agent tasks
- Add it: `openrouter/moonshotai/kimi-k2.5`

**Perplexity Sonar** — Built-In Web Search
- Research model with native search grounding — no separate search tool needed
- Great for sub-agents doing web research
- $3/M input, $15/M output (Sonar Pro)
- Add it: `openrouter/perplexity/sonar`

### Local Models: $0 Forever, No Rate Limits

If you have a GPU (even a modest one), local models via Ollama give you unlimited inference at zero cost. No API keys, no rate limits, no data leaving your machine.

**Qwopus (Qwen 3.5 27B + Claude Opus Reasoning Distilled)**
- Someone distilled Claude Opus 4.6's chain-of-thought reasoning into a Qwen 3.5 27B model
- It actually works — you get Opus-style structured thinking in a model that runs on a single RTX 3090/4090
- Excellent for local sub-agents that need reasoning capability
- Install: `ollama pull qwopus`
- Runs at ~Q4_K_M quantization, needs ~16GB VRAM

**NVIDIA Nemotron Nano 4B**
- Only 4 billion parameters but punches way above its weight
- Has toggleable System 1 / System 2 reasoning — turn deep thinking on or off per request
- 128K context window in a model that fits on basically any GPU
- 50% more throughput than other models in its class
- Perfect for: quick local tasks, edge deployments, or as an always-available local fallback
- Install: `ollama pull nemotron-nano`

**When to Use Local Models:**
- Sub-agent tasks where you want $0 cost and no rate limits
- Sensitive work where data shouldn't leave your machine
- As a fallback when cloud APIs are down or rate-limited
- Embedding/memory search (nomic-embed-text is already local if you followed Part 4)

### Using Anthropic Membership (The Best Way)

If you have a Claude Pro or Max subscription, you're probably overpaying by also buying API credits separately. Here's the thing — **your membership includes API access**, and OpenClaw can use it directly. No separate API key billing needed.

The setup is dead simple now:

**Step 1:** Open Claude Code in your terminal and run `claude` — it will ask you to log in via browser (OAuth). This creates a local auth token on your machine.

**Step 2:** Run `openclaw onboard` — during setup, it will detect your Claude Code credentials and ask if you want to use them. Say yes. That's it.

**Step 3:** Your OpenClaw bot now uses your membership allocation. No separate API key, no pay-per-token billing, no surprise charges.

**Why this matters:**
- Claude Pro ($20/month) or Max ($100/month) gives you a usage allocation that's usually way cheaper than raw API pricing
- Prompt caching works the same way — you still get 90% savings on cached tokens
- If you hit your membership limits, set a fallback to a free model (Gemini) so your bot never goes silent

```
Membership flow:
  Claude Code login (OAuth) → local auth token
      ↓
  openclaw onboard → detects token → uses membership
      ↓
  Your bot runs on your subscription. Done.
```

No terminal hacking, no environment variables, no copying keys between apps. Just paste and go.

### Recommended Setups

**Budget Setup ($0/month):**
```
Main: Gemini 3.1 Pro (free)
Fallback: OpenRouter Free Router (openrouter/free)
Sub-agents: Gemini 3 Flash (free)
Local: Nemotron Nano 4B for quick tasks
```

**Balanced Setup (~$20/month with Claude Pro membership):**
```
Main: Claude Sonnet 4.6 (via membership)
Fallback: Gemini 3.1 Pro (free)
Sub-agents: Gemini 3 Flash or Kimi K2.5
Coding: Claude Sonnet (via membership)
Local: Qwopus 27B for offline/private work
```

**Power Setup (~$100/month with Claude Max membership):**
```
Main: Claude Opus 4.6 (via membership)
Fallback: Claude Sonnet 4.6 (via membership)
Sub-agents: Kimi K2.5 / MiMo V2 Pro / Gemini Flash
Coding: GPT-5.3 Codex
Research: Gemini Flash + Perplexity Sonar
Local: Qwopus 27B for reasoning, Nemotron Nano for quick tasks
```

### Pro Tips

- **Always set fallbacks.** If your main model gets rate-limited or goes down, your bot should auto-switch, not break. Set 2-3 fallbacks in order of preference.
- **Match model to task, not vibes.** Don't use Opus to write a Python script. Don't use Flash to plan a complex architecture. Right tool, right job.
- **Cache matters on Anthropic.** Claude's prompt caching can reduce costs by 90% on repeated context. If you're using Opus/Sonnet, enable `cacheRetention: "extended"` and set up cache-ttl pruning.
- **Free models are real.** Gemini's free tier is not a toy — it's legitimately good for daily driving. Start free, upgrade when you hit limits.
- **Membership > API keys.** If you're paying for Claude Pro/Max anyway, use it through OpenClaw via OAuth. You're already paying for the tokens — don't pay twice.
- **Try MiMo V2 Pro right now.** It's free for launch week. A 1T parameter model at $0 is not something that happens often.
- **Test yourself.** These recommendations are based on our testing. Your use case might be different. Run `/model gemini` for a day, then `/model sonnet`, and compare. The best model is the one that works for YOU.

---

## Part 7: Web Search (Give Your Agent Eyes on the Internet)

Your agent's training data is months old. Without web search, it's guessing about anything that happened after its cutoff. This is the difference between "I think the answer is..." and "Here's what's actually happening right now."

### The Players

Here's every major web search API worth considering for an AI agent in 2026:

| Provider | Price per 1K queries | Free Tier | Best For | LLM-Optimized |
|----------|---------------------|-----------|----------|----------------|
| **Tavily** | ~$8 | 1,000/month | AI agents, RAG | ✅ Built for it |
| **Brave Search** | $5 | $5 credit/month | Privacy, scale | ✅ LLM Context mode |
| **Serper** | $1-3 | 2,500 credits | Budget, speed | Partial (structured JSON) |
| **SerpAPI** | $25-75/month tiers | 100/month | Multi-engine, enterprise | Partial |
| **Gemini Grounding** | Free (with Gemini) | Included | Google ecosystem | ✅ Native |
| **Perplexity Sonar** | $3/M input, $15/M output | Via OpenRouter | Research synthesis | ✅ Built for it |
| **Google Custom Search** | $5 | 100/day | ⚠️ Shutting down Jan 2027 | ❌ |

### Why We Use Tavily

After testing every option on this list, we settled on [Tavily](https://tavily.com) as our primary search API. Here's why:

**1. Built specifically for AI agents, not humans**

Traditional search APIs (Brave, Serper, SerpAPI) return what Google/Bing shows humans — a list of links with snippets. Your agent then has to fetch each page, parse the HTML, extract relevant content, and figure out what matters. That's 4-5 extra steps and tool calls burning context and time.

Tavily returns **clean, structured, pre-processed content** that an LLM can consume directly. It does the fetching, parsing, and relevance filtering for you. One API call → usable answer. Your agent's context stays lean because it's not stuffing raw HTML into the conversation.

**2. Search + Extract + Crawl in one API**

Most search APIs only search. If your agent needs the full content of a page (not just a snippet), you need a separate tool to fetch and parse it. Tavily bundles search, content extraction, and crawling into one service:

- **Search** → Find relevant results (1 credit)
- **Extract** → Pull full article content from any URL as clean markdown (1 credit per 5 URLs)
- **Crawl** → Map and crawl an entire site (1 credit per 10 pages)

This means fewer tools in your agent's toolkit, fewer context-eating tool calls, and simpler orchestration.

**3. Depth control**

Tavily lets you choose search depth per query:
- **Basic** — fast, surface-level, 1 credit. Good for simple fact checks
- **Advanced** — deep, comprehensive, 2 credits. Good for research tasks

Your agent can pick the right depth based on the task. Quick question? Basic. Deep research? Advanced. This saves credits and keeps responses fast when speed matters.

**4. The free tier is actually usable**

1,000 free API credits per month. That's 1,000 basic searches or 500 advanced searches — enough for a personal assistant that searches a few times a day. You don't need to pay anything to get real value out of it.

**5. Built-in safety**

Tavily has built-in safeguards against prompt injection from search results, PII leakage, and malicious sources. When your agent is ingesting content from the open web, this matters more than people realize.

### Setting Up Tavily with OpenClaw

**Step 1:** Get a free API key at [tavily.com](https://tavily.com) — takes 30 seconds.

**Step 2:** Your agent can use Tavily through sub-agents or custom skills. The simplest approach is to add it as a tool your agent knows about in TOOLS.md:

```markdown
## Web Search
- Tavily Search: For grounded web research. API key in environment.
- Use basic depth for quick lookups, advanced for deep research.
```

**Step 3:** For sub-agents doing research, include Tavily in their task instructions:

```
Research [topic] using Tavily search. Use advanced depth.
Summarize findings with sources.
```

### When to Use What

Not every search need is the same. Here's a quick decision tree:

```
Need real-time facts/news?
  → Tavily (basic depth) or Gemini grounding (if already using Gemini)

Need deep research with full article content?
  → Tavily (advanced depth + extract)

Need privacy-first search?
  → Brave Search API

Need structured Google results on a budget?
  → Serper ($1/1K queries)

Need search built into the model response?
  → Perplexity Sonar (via OpenRouter)

Just need free and good enough?
  → Gemini grounding (included with Gemini models)
```

### The Bottom Line

You can get by with Gemini's built-in grounding for free. But if you want your agent to do serious research — the kind where it actually reads articles, cross-references sources, and gives you grounded answers — Tavily is worth the upgrade. The free tier lets you try it without committing, and the structured output keeps your context lean instead of bloating it with raw web content.

---

## Part 8: One-Shotting Big Tasks (Stop Iterating, Start Researching)

Most people use AI agents like this: type a vague prompt, get a mediocre result, iterate 15 times, burn through context and money, end up with something that's 60% of what they wanted. Then they blame the model.

The model isn't the problem. **Your prompt is the problem.**

### The Data Behind This

This isn't opinion — there's hard data:

- AI-generated code from vague prompts contains **1.7x more issues** than human-written code
- Vague requirements lead to **39% more cognitive complexity** and **30-41% more technical debt**
- Security vulnerabilities are **2.74x higher** when requirements are ambiguous
- Logic errors are **75% more common** without clear specifications

But here's the flip side: when you give AI a **detailed specification with clear context**, first-attempt accuracy hits **95%+**. The same model, same capability — the only difference is what you put in.

**The quality of your output is capped by the quality of your input. Period.**

### Why Iteration Fails

Every time you iterate on a coding task with an AI agent, you're:

1. **Burning context** — each correction adds to the conversation history, pushing you toward bloat
2. **Confusing the model** — contradictory instructions from multiple rounds create inconsistency
3. **Paying twice** — you paid for the bad output AND the correction
4. **Losing coherence** — by iteration 8, the agent has forgotten what you said in iteration 1 (lost-in-the-middle, remember Part 2?)

One well-researched prompt beats ten lazy iterations every time.

### The Method: Research → Spec → Ship

Here's the exact workflow. Three phases, no shortcuts.

#### Phase 1: Research (30-60 minutes)

Before you tell your agent to build anything, you need to know what "good" looks like. This is where most people skip straight to prompting and pay for it later.

**Step 1: Find the best examples of what you're building**

Use Tavily or web search to find 3-5 top implementations:

```
Search: "best [thing you're building] open source 2025 2026"
Search: "top [thing you're building] UI design examples"
Search: "[thing you're building] GitHub stars:>1000"
```

You're looking for:
- What tech stack do the best ones use?
- What features do they all share? (these are table stakes)
- What features differentiate the best from the rest?
- What's the general UI layout pattern?

**Step 2: Analyze the UI patterns**

If you're building anything with a frontend, screenshots are gold. Modern models with vision can analyze UI screenshots and replicate patterns.

- Screenshot 3-5 of the best UIs you found
- Crop them clean — remove browser chrome, sidebars, anything irrelevant
- Note what works: layout, color scheme, typography, component patterns
- Note the design system: are they using cards? sidebar nav? dashboard grid?

**Step 3: Study the tech stack**

Don't just pick a stack because you like it. Pick the stack the best implementations use:

```
Search: "[thing you're building] best tech stack 2026"
Search: "[thing you're building] React vs Next.js vs [alternative]"
```

Look for:
- What framework handles this use case best?
- What UI library pairs well? (shadcn, Tailwind, Material)
- What are the common dependencies?
- Are there starter templates or boilerplate repos?

**Step 4: Find the pitfalls**

This is the step everyone skips. Search for what goes wrong:

```
Search: "[thing you're building] common mistakes to avoid"
Search: "[thing you're building] production issues lessons learned"
```

Every pitfall you find and include in your prompt is one fewer iteration later.

#### Phase 2: Write the Spec (15-30 minutes)

Now turn your research into a specification. This is not a conversation with the AI — this is a blueprint.

**The Spec Structure:**

```markdown
# Project: [Name]

## Context
[One paragraph: what this is, who it's for, why it exists]

## Research Summary
[Key findings from Phase 1 — what the best implementations do]

## Design Reference
[Describe the UI patterns you want. If you have screenshots, 
attach them and say "match this layout pattern"]

## Tech Stack
- Framework: [specific choice based on research]
- UI Library: [specific choice]
- Key Dependencies: [list them]
- Styling: [approach — Tailwind, CSS modules, etc.]

## Features (Ordered by Priority)
1. [Feature] — [specific acceptance criteria]
2. [Feature] — [specific acceptance criteria]
3. [Feature] — [specific acceptance criteria]

## File Structure
[If you care about project organization, specify it]

## Quality Bar
- [ ] Responsive design (mobile + desktop)
- [ ] Error handling on all API calls
- [ ] Loading states for async operations
- [ ] Clean, consistent code style
- [ ] No placeholder text or TODO comments in final output
- [ ] [Any other specific quality requirements]

## What NOT To Do
- Don't [common pitfall from research]
- Don't [another pitfall]
- Don't [bad pattern you've seen]
```

**Why this works:** You're not asking the AI to make decisions — you've already made them based on research. The AI's job is execution, not strategy. This is the difference between telling a contractor "build me a nice house" versus handing them architectural blueprints.

#### Phase 3: Delegate and Ship

Now send the spec to a **coding agent**, not your orchestrator:

```
sessions_spawn({
  task: "[your full spec from Phase 2]",
  mode: "run",
  runtime: "subagent"  // or "acp" for Codex/Claude Code
})
```

**Key rules for delegation:**

- **Send to a coding model, not your orchestrator.** Your main model should plan, not build. Codex, Sonnet, or a dedicated coding model does the building.
- **Include everything in one prompt.** Don't plan to "follow up" — the whole point is one shot. If you're thinking "I'll clarify later," you haven't researched enough.
- **Attach reference images if applicable.** Vision-capable models can analyze screenshots and match layout patterns.
- **Set a reasonable timeout.** Big tasks take time. Don't interrupt the agent mid-build.

### Real Example: One-Shotting a Dashboard

Here's what this looks like in practice. Say you want to build a analytics dashboard.

**Bad prompt (what most people do):**
```
Build me a cool analytics dashboard
```

This will produce a generic, mid-quality dashboard with placeholder data, random charts, and no coherent design. You'll iterate 10+ times.

**Good prompt (after 30 minutes of research):**

```markdown
# Project: Real-Time Analytics Dashboard

## Context
Internal analytics dashboard for monitoring key business metrics. 
Single-page app, real-time data updates, used daily by a small team.

## Research Summary
Analyzed top dashboards: Vercel Analytics, PostHog, Plausible, 
Linear's dashboard. Common patterns:
- Metric cards at top (KPIs with trend indicators)
- Main chart area (line/area charts, time-selectable)
- Data table below with sortable columns
- Sidebar navigation (collapsible)
- Dark mode default with light mode toggle
- All use 4px border radius, subtle shadows, muted color palette

## Design Reference
[Attached: screenshots of Vercel Analytics layout, PostHog chart 
style, Linear's sidebar pattern]
Match the Vercel Analytics layout pattern — metric cards top, 
main chart center, table bottom. Use PostHog's chart styling 
(area charts with gradient fill). Linear's sidebar navigation pattern.

## Tech Stack
- Next.js 15 (App Router)
- shadcn/ui + Tailwind CSS
- Recharts for charts
- TanStack Table for data tables
- Lucide icons

## Features (Priority Order)
1. KPI metric cards — 4 cards showing: total users, active today, 
   revenue, conversion rate. Each with sparkline and % change vs 
   previous period (green up, red down)
2. Main chart — area chart with gradient fill, time range selector 
   (24h, 7d, 30d, 90d), hover tooltips with exact values
3. Data table — sortable columns, search filter, pagination (20 rows), 
   row click expands detail view
4. Sidebar — collapsible, icon + text labels, active state highlight, 
   sections: Overview, Users, Revenue, Settings
5. Dark/light mode toggle — persist preference to localStorage
6. Responsive — sidebar collapses to icons on tablet, 
   bottom nav on mobile

## File Structure
src/
  app/
    layout.tsx
    page.tsx (dashboard)
  components/
    dashboard/
      MetricCard.tsx
      MainChart.tsx
      DataTable.tsx
    layout/
      Sidebar.tsx
      Header.tsx
  lib/
    utils.ts
    mock-data.ts (realistic sample data, not lorem ipsum)

## Quality Bar
- [ ] All components are properly typed (TypeScript strict)
- [ ] Mock data looks realistic (real-looking names, numbers, dates)
- [ ] Smooth animations on chart transitions
- [ ] Loading skeletons for async states
- [ ] Keyboard accessible (tab navigation, focus states)
- [ ] No console errors or warnings

## What NOT To Do
- Don't use random/clashing colors — stick to a cohesive palette
- Don't use placeholder text like "Lorem ipsum" or "Sample Data"
- Don't hardcode pixel values — use Tailwind spacing scale
- Don't skip error boundaries
- Don't make the sidebar fixed width on mobile (it should collapse)
```

**The difference:** The first prompt requires the AI to make 50+ decisions about design, tech, features, and structure — and it'll get most of them wrong. The second prompt makes all those decisions upfront based on research, so the AI just executes. One shot, high quality.

### Let Your Agent Do the Research For You

Here's the thing — you have an AI agent with web search. **You don't have to do the research yourself.** Make your agent do Phase 1 before it starts Phase 3. This turns a 30-minute manual research session into a 2-minute conversation.

**Just ask it:**

```
Before you build anything, I need you to research first:

1. Search for the top 5 [dashboards/landing pages/CLI tools/whatever] 
   that exist right now. What tech stack do they use? What UI patterns 
   do they share? What makes the best ones stand out?

2. Search for "[thing you're building] UI design best practices 2026" 
   and summarize the key patterns.

3. Search for "[thing you're building] common mistakes to avoid" 
   and list the top pitfalls.

4. Based on your research, write me a detailed spec for building 
   [what you want]. Include tech stack recommendation, feature list 
   with acceptance criteria, file structure, and quality bar.

Do NOT start building until the spec is written and I approve it.
```

That's it. Your agent uses Tavily/web search to do the deep dive, synthesizes everything into a spec, and waits for your approval before building. You get the same research quality in a fraction of the time.

**The workflow becomes:**

```
You: "Research and spec out a [thing]"          → 2 minutes
Agent: [does Tavily research, writes spec]      → 3-5 minutes
You: "Looks good, build it" (or tweak the spec) → 30 seconds
Agent: [builds from researched spec]            → one-shot quality
```

Total time: ~5-8 minutes instead of 30+ minutes of manual research or 3+ hours of blind iteration.

**Even better — split research and building across agents:**

```
Step 1: Ask your orchestrator to research and write the spec
Step 2: Review and approve the spec
Step 3: Orchestrator spawns a coding sub-agent with the full spec
```

Your orchestrator (Opus/Sonnet/Gemini) does the research and strategic thinking. The coding agent (Codex/Sonnet/cheaper model) does the building. Right model for each job, and the coding agent starts with a complete spec instead of a vague prompt.

### The 5-Minute Rule

If you care about quality, spend 5 minutes having your agent research before building. That's one message. The agent does the rest.

For anything you actually care about shipping, 5 minutes of agent-driven research saves 3+ hours of iteration. That's not a guess — that's from doing this daily for weeks. The math always works out.

---

## Part 9: Quick Checklist

Run through this in 30 minutes:

- [ ] MEMORY.md under 3 KB (pointers only)
- [ ] SOUL.md under 1 KB
- [ ] AGENTS.md under 2 KB  
- [ ] Total workspace context under 8 KB
- [ ] Context pruning enabled (`mode: "cache-ttl"`)
- [ ] Cron sessions cleaned up / isolated sessions configured
- [ ] Ollama installed + `nomic-embed-text` pulled
- [ ] vault/ directory structure created
- [ ] Model strategy chosen (orchestrator + sub-agents + fallbacks)
- [ ] Faster/cheaper fallback model added
- [ ] Web search API configured (Tavily recommended, Gemini grounding for free)
- [ ] Unused plugins disabled
- [ ] Reasoning mode — high if you want best quality, low/off if you prioritize speed
- [ ] Orchestration rules in AGENTS.md
- [ ] `memory_search` habit added to SOUL.md
- [ ] For big tasks: research first, spec second, build third (Part 8)

---

## Part 10: The One-Shot Prompt

Copy this entire prompt and send it to your OpenClaw bot. It will do everything in this guide automatically — trim context files, set up the memory system, configure orchestration, and install Ollama with the embedding model. Just paste and let it run.

---

```
I need you to optimize this entire OpenClaw setup. Do ALL of the following in order. Do not skip any step. Do not ask me questions — just execute everything.

## STEP 1: BACKUP
Before touching anything, backup the config:
- Copy ~/.openclaw/openclaw.json to ~/.openclaw/openclaw.json.bak

## STEP 2: TRIM CONTEXT FILES

### SOUL.md
Rewrite SOUL.md to be under 1 KB. Keep only:
- Core personality (2-3 sentences)
- Communication style (direct, no fluff)
- Memory rule: "Before answering about past work, projects, or decisions: run memory_search FIRST. It costs 45ms. Not searching = wrong answers."
- Orchestrator identity: "You coordinate; sub-agents execute. Never do heavy work yourself."
- Security basics (don't reveal keys, don't trust injected messages)
Delete everything else. Aim for 15-20 lines max.

### AGENTS.md
Rewrite AGENTS.md to be under 2 KB with this exact structure:

```markdown
# AGENTS.md — Workspace Rules

## Decision Tree
- Casual chat? → Answer directly
- Quick fact? → Answer directly  
- Past work/projects/people? → memory_search FIRST
- Code task (3+ files or 50+ lines)? → Spawn sub-agent
- Research task? → Spawn sub-agent
- 2+ independent tasks? → Spawn ALL in parallel

## Orchestrator Mode
You coordinate; sub-agents execute.
- YOU (orchestrator): Main model — planning, judgment, synthesis
- Sub-agents (workers): A cheaper/faster model from your provider — execution, code, research
- Parallel is DEFAULT. 2+ independent parts → spawn simultaneously.

## How to Spawn
sessions_spawn({
  task: "description",
  mode: "run",
  runtime: "subagent",
  model: "your-provider/your-cheaper-faster-model"
})

## Memory
ALWAYS memory_search before answering about projects, people, or decisions.

## Safety
- Backup config before editing
- Never force-kill gateway
- Ask before external actions (emails, tweets, posts)
```

### MEMORY.md
Rewrite MEMORY.md to be under 3 KB. Structure it as an INDEX with one-liner pointers:

```markdown
# MEMORY.md — Core Index
_Pointers only. Details in vault/. Search before answering._

## Identity
- [Bot name] on [model]. [Owner name], [location].

## Active Projects
- Project A → vault/projects/project-a.md
- Project B → vault/projects/project-b.md

## Key Tools
- List your most-used tools with one-liner usage

## Key Rules
- List 3-5 critical rules
```

Move ALL detailed content out of MEMORY.md into vault/ files. MEMORY.md should ONLY contain short pointers.

### TOOLS.md
If TOOLS.md exists, trim to under 1 KB — just tool names and one-liner commands. If it doesn't exist, skip.

## STEP 3: CREATE VAULT STRUCTURE

Create these directories in the workspace:
- vault/projects/
- vault/people/
- vault/decisions/
- vault/lessons/
- vault/reference/
- vault/research/
- memory/ (if it doesn't exist)

Move any detailed docs from MEMORY.md into the appropriate vault/ subdirectory.

## STEP 4: INSTALL OLLAMA + EMBEDDING MODEL

Check if Ollama is installed:
- Try running: ollama --version
- If not installed:
  - Windows: winget install Ollama.Ollama
  - Mac: brew install ollama
  - Linux: curl -fsSL https://ollama.com/install.sh | sh

Pull the embedding model:
- ollama pull nomic-embed-text

Verify it works:
- ollama run nomic-embed-text "test" (should return embeddings)

## STEP 5: ADD FALLBACK MODEL

In openclaw.json, find your main agent config and add a fallback model. Use a faster/cheaper model from the same provider as your main model. For example:
- If you use a large reasoning model, add a smaller/faster variant as fallback
- The fallback kicks in automatically when your main model is slow or rate-limited

## STEP 6: DISABLE UNUSED PLUGINS

In openclaw.json, find the plugins section. Any plugin you're not actively using, set to:
"enabled": false

Common ones to disable if unused: memory-lancedb, memory-core, any experimental plugins.

## STEP 7: VERIFY

After all changes:
1. Restart the gateway: openclaw gateway stop && openclaw gateway start
2. Run: openclaw doctor
3. Test memory_search by asking about something in your vault files
4. Report what you changed with before/after file sizes

## IMPORTANT RULES
- Do NOT delete any config — only trim and reorganize
- Keep all original content — just move it to vault/ instead of keeping it in workspace root files
- If a file doesn't exist, skip it — don't create empty files
- Total workspace context (all .md files in root) should be under 8 KB when done
- Restart the gateway AFTER all changes, not during
```

---

That's it. One paste, your bot does everything. If anything fails, your config backup is at `openclaw.json.bak`.

---

## Troubleshooting

**One-shot prompt only partially completed:**
Your model may have hit a context limit or timed out mid-execution. Run `/status` to check, then re-paste just the steps that didn't complete. The prompt is designed to be idempotent — running a step twice won't break anything.

**memory_search not working after setup:**
Make sure Ollama is running (`ollama ps`) and nomic-embed-text is pulled (`ollama pull nomic-embed-text`). OpenClaw auto-detects Ollama on localhost:11434. If Ollama is on a different machine, you'll need to configure the Ollama URL in your OpenClaw settings.

**Bot still feels slow after trimming:**
Check your total workspace file sizes: `ls -la *.md` in your workspace root. If total is still over 10KB, you have files that weren't trimmed. Also check if reasoning mode is set to `high` — that adds 2-5 seconds per message (worth it for quality, but know the tradeoff).

**Sub-agents not spawning:**
Make sure your model supports `sessions_spawn`. Check that you have a fallback model configured — sub-agents use the fallback model by default so your main model stays available for you.

**Gateway won't restart after config changes:**
Run `openclaw doctor --fix` to validate and repair your config. If you backed up before making changes (the prompt does this automatically), you can always restore: `cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json`

**One-shot prompt only works partially on your model:**
If your model struggles with the full prompt, do these 3 things manually instead:
1. Copy the files from `/templates` into your workspace root
2. Run `ollama pull nomic-embed-text`
3. Restart gateway: `openclaw gateway stop && openclaw gateway start`

That gets you 90% of the benefit. The one-shot prompt just automates these steps + moves your existing content to vault/.

---

## FAQ

**Why markdown files instead of a real database like Postgres?**

The .md + vault approach is the zero-infrastructure entry point. No Docker, no database admin, no config — just files + Ollama. You're set up in 30 minutes. For power users who want more, the architecture scales naturally into a real database backend (we're using TiDB vector for hybrid SQL + semantic search on our own setup). Think of the markdown approach as the starting line, not the finish line.

**Doesn't the expensive model need to do the hard tasks?**

No — and this is the key insight of the orchestration section. Your expensive model (Opus, GPT, etc.) should PLAN and JUDGE. The actual execution (writing code, doing research, running analysis) gets delegated to cheaper/faster models via sub-agents. The expensive model decides WHAT to build. The cheap model builds it. The expensive model reviews the output. You get frontier-quality judgment with budget-tier execution costs.

**What if my model isn't smart enough to follow the one-shot prompt?**

Run `setup.sh` (Mac/Linux) or `setup.ps1` (Windows) instead — they do the same thing without needing your model to interpret instructions. Or just copy the files from `/templates` into your workspace manually. Three paths, same result.

**Does this work with models other than Claude Opus?**

Tested and confirmed on Opus 4.6. The architecture works with any model that supports `memory_search` and `sessions_spawn` in OpenClaw. The one-shot prompt needs a model that can follow multi-step instructions well — most frontier models (Sonnet, GPT, Gemini) should handle it fine.

**How is this different from other memory solutions?**

Most agent memory tools add external databases, cloud services, or complex dependency chains. This guide gives you 90% of the practical benefit (persistent memory across sessions, fast retrieval, zero forgetting) with 10% of the moving parts — just local files + vector search. Nothing to install except Ollama. Nothing leaves your machine. If you outgrow this approach, the vault structure maps cleanly to any database backend.

---

## About

*Built by [Terp — Terp AI Labs](https://x.com/OnlyTerp)*

The definitive optimization guide for OpenClaw — covering speed, memory, context management, model selection, web search, orchestration, and spec-driven development. Battle-tested daily on a production OpenClaw setup.

**Saved you tokens/time?** Drop a ⭐ on this repo or ping me [@OnlyTerp](https://x.com/OnlyTerp) on X with your before/after numbers — happy to feature real user results.

**Prefer scripts over the prompt?** Run `bash setup.sh` (Mac/Linux) or `powershell setup.ps1` (Windows) from the repo root.

### Related Resources
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Discord Community](https://discord.gg/clawd)
- [ClawHub — Skills Marketplace](https://clawhub.com)
