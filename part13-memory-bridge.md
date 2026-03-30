# Part 13: Memory Bridge (Give Coding Agents Your Brain)

When you spawn Codex or Claude Code to build something, they start blind. They don't know your architecture decisions, past mistakes, or what's already been built. They code from scratch every time.

**The fix: inject your vault knowledge into the coding agent's workspace before it starts.**

## The Problem

```
You: "Build a training pipeline for Nemotron"
Codex: *starts from scratch, ignores the fact you already tried vLLM (failed), 
       already have LoRA adapters on HuggingFace, already know Q4_K_M works best*
Result: repeats your past mistakes, misses your past wins
```

## The Solution: Memory Bridge

Two scripts, zero dependencies:

### 1. Preflight Context Injection (run BEFORE spawning Codex)

```bash
node scripts/memory-bridge/preflight-context.js \
  --task "Build a training pipeline for Nemotron" \
  --workdir C:\path\to\project
```

What it does:
1. Extracts keywords from the task description
2. Searches your vault from 3-5 different angles
3. Deduplicates and ranks results by relevance
4. Writes a `CONTEXT.md` file to the project directory

Codex reads `CONTEXT.md` automatically (it reads all markdown in the workdir). Now it knows:
- What you've tried before
- What worked and what failed
- Your architecture decisions
- Relevant code patterns from past projects

### 2. On-Demand Memory Search (Codex calls this MID-TASK)

```bash
node scripts/memory-bridge/memory-query.js "how does the auth module work"
node scripts/memory-bridge/memory-query.js "past database schema decisions" --max-results 10
node scripts/memory-bridge/memory-query.js "error handling patterns" --json
```

Tell Codex in its task prompt:
```
You can search institutional memory with:
  node /path/to/memory-query.js "your question"
Use this when you're unsure about architecture decisions or past patterns.
```

### The Workflow

```
Before Codex spawn:
  1. node preflight-context.js --task "..." --workdir <dir>   → writes CONTEXT.md
  2. codex --yolo exec "Build X. You can search memory with: node memory-query.js 'query'"

Result: Codex starts with context + can search on demand = institutional knowledge
```

### What CONTEXT.md Looks Like

```markdown
# CONTEXT

This context was pulled from your memory system before the coding agent started.

- Task: Build a fine-tuned Nemotron model training pipeline
- Agent memory searched: ops
- Search angles used: training pipeline | architecture decisions | implementation patterns
- Chunks included: 8

Use this as background context, not as an unquestioned source of truth.

## memory/2026-03-24-terpbot-235tps.md

### Lines 22-46 | relevance 0.424

Matched by: fine-tuned nemotron model

​```text
3. Merged LoRA fine-tune on B200 → quantized to Q4_K_M → uploaded to HF
4. Downloaded merged GGUF to 5090 → created terpbot:latest in Ollama
5. Result: 235 tok/s generation, 48.78 tok/s prompt processing
​```
```

The coding agent now knows your exact training pipeline, what worked, what didn't.

### Requirements

- Node.js 24+
- `openclaw` CLI in PATH
- Memory system configured (Qwen3-VL, nomic-embed-text, or any OpenClaw-compatible embedding provider)

### Installation

```bash
git clone https://github.com/OnlyTerp/memory-bridge.git
cd memory-bridge
node test.js  # verify
```

Or just copy `memory-query.js` and `preflight-context.js` into your workspace scripts directory.

### Integration with AGENTS.md

Add this to your coding workflow:

```markdown
### Code: Memory Bridge + Codex
STEP 1 — Preflight (ALWAYS before Codex):
  node scripts/memory-bridge/preflight-context.js --task "..." --workdir <dir>

STEP 2 — Spawn with memory access:
  Tell Codex: "Search memory with: node memory-query.js 'query'"

STEP 3 — Evaluate output (optional: Generator-Evaluator loop)
```

### Before/After

| Metric | Without Bridge | With Bridge |
|--------|---------------|-------------|
| Context on start | 0 vault chunks | 8-18 relevant chunks |
| Repeated mistakes | Frequent | Rare (past errors in context) |
| Architecture alignment | Guesses | Follows established patterns |
| Iteration rounds | 3-5 | 1-2 |
| First-attempt quality | ~60% | ~85% |

The bridge is the difference between "smart but amnesiac" and "smart with institutional knowledge."
