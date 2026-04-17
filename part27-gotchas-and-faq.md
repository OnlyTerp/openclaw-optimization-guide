# Part 27: Common Gotchas & FAQ

> New in the 2026.4.15 refresh. Every "I wasted a day on this" distilled into one page. Skim this before you debug; half your questions are answered here.

> **Read this if** something is broken, confusing, or behaving weirdly and you want to check the common-causes list before deep-diving.
> **Skip if** nothing is broken — come back when it is.

## Gotchas, Grouped By Symptom

### "memory_search returns nothing / takes 5 seconds"

| Cause | Fix |
|-------|-----|
| Cloud embedding provider set as primary | Switch to local Ollama (`qwen3-embedding:0.6b`). See [Part 10](./part10-state-of-the-art-embeddings.md). |
| Ollama not running | `ollama serve` (Linux/Mac) or start the Ollama app (Windows/Mac desktop). |
| Embedding model not pulled | `ollama pull qwen3-embedding:0.6b`. |
| Ollama on non-default port | Confirm `localhost:11434` is reachable. |
| Vault not indexed yet | Give it a cycle to finish background indexing, or trigger an index refresh. |
| GPU contention with an LLM | Move the embedding model to CPU, or run them on separate GPUs. See [Part 15](./part15-infrastructure-hardening.md). |

### "The agent keeps reading stale memory"

| Cause | Fix |
|-------|-----|
| MEMORY.md is too big, injecting hundreds of lines | Treat MEMORY.md as an index only, details in vault. See [Part 4](./README.md#part-4-memory-stop-forgetting-everything). |
| No dreaming / consolidation running | Enable built-in memory-core dreaming ([Part 22](./README.md#part-22-built-in-dreaming)). |
| Cron sessions piling up in memory/ | Clean up + enable session isolation. See [Part 3](./README.md#part-3-cron-session-bloat-the-hidden-killer). |
| Agent isn't calling `memory_search` proactively | Add the memory rule to SOUL.md/AGENTS.md. See [Part 4](./README.md#part-4-memory-stop-forgetting-everything). |

### "My agent is slow"

| Cause | Fix |
|-------|-----|
| SOUL.md / AGENTS.md / MEMORY.md too big (>5KB combined) | Trim. See [Part 1](./README.md#part-1-speed-stop-being-slow). |
| Context pruning disabled | `contextPruning: { mode: "cache-ttl", ttl: "5m" }`. See [Part 2](./README.md#part-2-context-engineering--the-discipline). |
| Reasoning mode on for trivial tasks | Turn reasoning off for the default model, on only for orchestration. See [Part 6](./README.md#part-6-models-what-to-actually-use). |
| Orchestrator doing work it should delegate | Add the sub-agent rules to AGENTS.md. See [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself). |
| Compaction model is Gemini Flash (rate-limited) | Switch compaction to Cerebras Qwen. See [Part 15](./part15-infrastructure-hardening.md). |
| Local model loaded but not used | `ollama ps` + `ollama stop <model>` for ones you're not using. |

### "Compaction crashes in a loop"

| Cause | Fix |
|-------|-----|
| Compaction model rate-limited | Set explicit compaction model (not Flash). [Part 15](./part15-infrastructure-hardening.md). |
| `reserveTokens` larger than model context window | Upgrade to 2026.4.15 (cap auto-applied) or manually set `reserveTokens` under the window. |
| Compaction set to a reasoning model | Use an instruct model for compaction — reasoning burns tokens you're trying to save. |

### "Gateway keeps restarting / port 18789 in use"

| Cause | Fix |
|-------|-----|
| Stale gateway process holding the port | Add cleanup to your startup script. See the [Gateway Crash Loop Fix](./part15-infrastructure-hardening.md#gateway-crash-loop-fix) in Part 15. |
| Auth token expired | Check the Canvas **Model Auth status card** (added 2026.4.15). Rotate the underlying credential, then refresh; the gateway's `models.authStatus` method picks it up without a full restart. |
| Config file has JSON syntax error after edit | `openclaw.json.clobbered.*` will exist — diff against your backup and fix. |

### "Sub-agent spawns suddenly require approval"

| Cause | Fix |
|-------|-----|
| Upgraded to 2026.3.31-beta.1+ and fail-closed defaults kicked in | Write an explicit approval policy. See [Part 24](./part24-task-brain-control-plane.md). |
| Worker is in a `execution.*: deny` scope | Broaden the worker's scope to match what you're actually asking it to do, or send lighter tasks. |
| Skill running in spawn uses a new category you haven't whitelisted | Add the category to the per-agent policy. |

### "ClawHub skill I installed is doing weird things"

| Cause | Fix |
|-------|-----|
| Skill was auto-updated to a malicious version | Disable `skills.autoUpdate`. Pin `--ref` to a known-good version. See [Part 23](./part23-clawhub-skills-marketplace.md). |
| Skill overrides your AGENTS.md rules | Uninstall. Report. |
| Skill makes network calls to unknown hosts | Uninstall immediately. Rotate any credentials the skill could read. |
| Typo-squatted skill (wrong author) | Uninstall. Install the correct one by exact author name. |

### "LightRAG returns empty / weird results"

| Cause | Fix |
|-------|-----|
| Knowledge graph has fewer than ~500 documents | Normal. LightRAG shines at scale. Keep writing. See [Part 18](./part18-lightrag-graph-rag.md). |
| File watcher not running | Start it. See [Part 21](./part21-realtime-knowledge-sync.md). |
| LightRAG service not reachable | Check the service is up, the port is right, and the config points at it. |
| Embeddings changed recently | Re-index — LightRAG needs a consistent embedding dimensionality. |

### "My expensive model keeps getting rate-limited"

| Cause | Fix |
|-------|-----|
| Using API keys instead of membership | Switch to OAuth if you have Pro/Max. See [Part 6](./README.md#part-6-models-what-to-actually-use). |
| No fallback model configured | Add 2-3 fallbacks. See [Part 6](./README.md#part-6-models-what-to-actually-use). |
| Orchestrator doing what workers should | See [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself). |
| Same key used for compaction + chat | Split compaction onto a different provider (Cerebras). |

### "Tool registration suddenly returns `400 invalid_request_error`"

| Cause | Fix |
|-------|-----|
| Client tool name normalize-collides with a built-in (`Browser`, `Exec`, or `exec` with trailing whitespace, etc.) | Rename. As of 2026.4.15 stable the gateway rejects these to prevent local-media trust inheritance. See [Part 15](./part15-infrastructure-hardening.md). |
| Two client tools in the same request normalize to the same name | Deduplicate; keep one, rename the other. |

### "My dreaming phase blocks disappeared from memory/YYYY-MM-DD.md"

| Cause | Fix |
|-------|-----|
| 2026.4.15 stable flipped `dreaming.storage.mode` default from `inline` → `separate` | They're now at `memory/dreaming/{light-sleep,rem-sleep}/YYYY-MM-DD.md`. If you want the old behavior, set `plugins.entries.memory-core.config.dreaming.storage.mode: "inline"` in memory-core config. See [Part 22](./README.md#part-22-built-in-dreaming) + [Part 26](./part26-migration-guide.md#path-5-v20264-15-beta-1-v20264-15-stable). |
| Scripts parsing the daily memory file for phase markers | Update to read the new `memory/dreaming/{phase}/` paths. |

### "`memory_get` is returning truncated content now"

| Cause | Fix |
|-------|-----|
| 2026.4.15 stable enabled default excerpt cap + continuation metadata | Follow the continuation cursor in the tool response to fetch the next chunk. Skills/hooks that assume a full-file return need a small cursor loop. See [Part 4](./README.md#part-4-memory-stop-forgetting-everything). |
| You meant to read the whole file, not the canonical index | Use a plain file-read tool, not `memory_get`. |

### "Skill 'lost context' after upgrading to 2026.4.15 stable"

| Cause | Fix |
|-------|-----|
| Default startup/skills prompt budgets were trimmed in the stable release | If the skill genuinely needed that context, spell it out explicitly in the skill's system prompt — don't rely on the default injection. |

### "Secrets showed up in a git commit"

| Cause | Fix |
|-------|-----|
| `.openclaw/` not in .gitignore | Add it. See [Part 15](./part15-infrastructure-hardening.md). |
| Credentials written into memory/ or session transcripts | Add the no-credentials rule to AGENTS.md. [Part 15](./part15-infrastructure-hardening.md). |
| Approval reviewer saw raw secrets pre-4.15 | Upgrade to 2026.4.15 (redaction) and rotate exposed keys. |

## FAQ

### Is any of this still relevant if I only run one agent?

Yes — Parts 1 through 10 are mostly single-agent. The orchestration, task brain, and skills parts are where multi-agent deployments pull ahead, but even a single-agent setup benefits from context hygiene, memory architecture, and proper approvals.

### Do I need all of LightRAG, Repowise, and memory-lancedb?

No. The minimum viable setup is memory-lancedb (vector search) plus the vault ([Part 9](./part9-vault-memory.md)). Add LightRAG ([Part 18](./part18-lightrag-graph-rag.md)) when you cross ~500 vault documents. Add Repowise ([Part 19](./part19-repowise-codebase-intelligence.md)) when you're pointing agents at real codebases, not just knowledge work.

### Should I enable ClawHub skills or stay stock?

Skills are genuinely useful, but the marketplace has a malware problem. Our recommendation: install **only** from trusted authors (preferably the official `openclaw-team/*` namespace), pin specific refs, disable auto-update. See [Part 23](./part23-clawhub-skills-marketplace.md) for the full install checklist.

### Local models: good idea or not?

Both. For the **orchestrator** you want a frontier model (Claude, GPT, Gemini Pro) — the quality difference is huge on planning. For **workers**, local models on a decent GPU are absolutely viable and save real money. See [Part 6](./README.md#part-6-models-what-to-actually-use) for tier-by-tier guidance.

### How do I know if I should use reasoning mode?

Turn it on for the orchestrator when tasks are ambiguous or multi-step. Turn it off for workers doing well-defined execution. Reasoning adds latency and cost; it shines on "what should we do" questions, not "go do this" tasks.

### Is it safe to run OpenClaw fully autonomous (no human in the loop)?

Not yet, and not with a broad approval policy. You can safely run a narrow-scope autonomous worker (read-only research, targeted code generation in a sandboxed repo, test running). Don't run autonomous workers with `write.network` or `control-plane.*` approvals set to `allow`. See [Part 24](./part24-task-brain-control-plane.md).

### Does this guide work outside Windows?

Yes. Most examples show both PowerShell and bash; the config files are identical. Setup scripts are provided as both `setup.ps1` and `setup.sh`. The Windows-specific gotcha to know is [Part 10](./part10-state-of-the-art-embeddings.md)'s embedding install path — go read it before you pull the big models.

### I've never used OpenClaw before — where do I start?

1. Read [Part 25 — Architecture Overview](./part25-architecture-overview.md) first (15 min).
2. Then the [Quick Checklist](./README.md#part-14-quick-checklist) in the README.
3. Then pick a pillar that matches what you care about (speed / memory / security / observability) and read the parts in it.
4. Don't try to read the whole guide in one sitting. It's a reference.

### I'm on v3.x — how much of this applies?

Very little. v4.0 was a rewrite. Start with [Part 26 — Migration Guide](./part26-migration-guide.md) — get to v4.0 first, then come back.

### What if I find something in this guide that's wrong?

Open a PR or an issue at <https://github.com/OnlyTerp/openclaw-optimization-guide>. See [CONTRIBUTING.md](./CONTRIBUTING.md).

### Can I use this guide's content in my own blog / talk / company docs?

The repo is MIT-licensed. Attribution is appreciated (link back, mention Terp AI Labs) but not legally required.

### How often does this guide get updated?

Continuously when OpenClaw ships something material. Check the version line at the top of the README — if it matches your OpenClaw version, you're current. If it's behind, open an issue.
