# Part 33: May 2026 Field Guide

> **Read this if** you last tuned OpenClaw around 2026.4.15/2026.4.29 and want the current tricks without re-reading every release note.
> **Skip if** you're pinned before 2026.4.15 and still need the basics — start with [Part 26 — Migration Guide](./part26-migration-guide.md).

OpenClaw's late-April and May releases changed the operator playbook in six places: providers, memory, messaging, browser/Codex automation, local runtime management, and plugin/security boundaries. This page is the catch-up map.

## Version Map

| Release | Why you care |
|---------|--------------|
| **2026.4.20** | Built-in session-store pruning, Kimi K2.6 as the bundled Moonshot default, tiered pricing in token reports, stronger default prompts. |
| **2026.4.22** | `/models add` and OpenAI Codex auth import landed, but both are now superseded or should be treated cautiously. |
| **2026.4.24-beta.1** | Google Meet, realtime voice consults, DeepSeek V4, browser coordinate clicks, 60s browser action budgets, per-profile headless overrides, manifest-backed model rows, `/models add` deprecation. |
| **2026.4.27 stable** | DeepInfra provider, Codex Computer Use setup/status/install commands, manifest-first plugin catalogs, Docker GPU passthrough, outbound proxy routing, non-image chat attachments. |
| **2026.4.29-beta.1** | Active-run steering, visible-reply enforcement, people-aware wiki metadata, Active Memory chat filters, partial recall on timeout, NVIDIA provider, Bedrock Opus 4.7 parity, OpenGrep scanning. |
| **2026.5.4–2026.5.7** | Early May hardening: provider manifest/runtime repairs, safer channel/session routing, pnpm 11 plugin support groundwork, and continued Codex app-server fixes. |
| **2026.5.9–2026.5.10 beta** | Externalized plugin/provider cones begin landing; Codex app-server migration bugs and Control UI session visibility improve. |
| **2026.5.12 stable** | Current stable baseline: leaner installs, Telegram resilience, safer plugin installs/updates, Codex app-server/runtime fallback improvements, Control UI/WebChat/TUI delivery fixes, ACP fallbacks, and gateway/browser/Slack/sandbox/transcript hardening. |
| **2026.5.14-beta.1** | Latest beta sweep: `/queue steer` default, `agents.defaults.runRetries`, Telnyx realtime calls, Codex app-server command fixes, bundled `codex-cli` backend removal/repair, WhatsApp status reactions, per-sender tool tiers, and nested sub-agent sessions in Control UI. |

If you want boring stability today, run **2026.5.12**. If you actively use mid-turn steering, Telnyx realtime voice, Codex migration repair, or per-sender tool tiers, test **2026.5.14-beta.1** on a copy of your profile first.

## 1. Stop Assuming Claude Subscription Usage

Older OpenClaw advice said "use Claude Pro/Max membership; don't pay API rates." That is no longer safe. Anthropic's April 4 cutoff moved many third-party OpenClaw users onto explicit paid provider routes.

Current operator default:

1. Put Opus/Sonnet behind a paid route you can see and budget.
2. Add at least two non-Anthropic fallbacks.
3. Put infrastructure work on cheap models.
4. Review token reports after one real day, not after a toy prompt.

Good fallback lanes in May:

- **DeepSeek V4 Flash** — new bundled onboarding default in 2026.4.24; use for cheap worker traffic.
- **Kimi K2.6** — new Moonshot default in 2026.4.20; use for research, media understanding, and sub-agents.
- **DeepInfra** — bundled provider in 2026.4.27; useful when you want model breadth without more first-party keys.
- **NVIDIA** — beta provider in 2026.4.29; useful if your org already buys NVIDIA hosted inference.
- **Cerebras** — still strong for fast infrastructure calls and LightRAG extraction.
- **Codex app-server on `openai/gpt-*` refs** — best for batch coding when your OpenAI/Codex auth route is healthy.

## 2. Treat Model Registration As Config, Not Chat

`/models add` was added in 2026.4.22, then deprecated in 2026.4.24. This is the important part: current OpenClaw is moving toward **manifest-backed model catalogs**. Provider plugins declare rows, aliases, suppressions, auth choices, and discovery behavior without loading their runtime.

Do this:

```text
/models       # inspect available rows and auth state
openclaw models list
edit provider/config deliberately
restart or refresh the gateway auth path if needed
```

Do **not** build runbooks that tell agents to call `/models add` mid-chat.

May 2026 add-on: provider manifests can now own more runtime setup. If a local backend needs a daemon, prefer provider-level `localService` metadata over "remember to start Ollama/vLLM in another terminal" runbooks:

```json5
{
  models: {
    providers: {
      "ollama-local": {
        type: "ollama",
        endpoint: "http://localhost:11434",
        localService: {
          command: "ollama serve",
          healthUrl: "http://localhost:11434/api/tags",
          readyTimeoutMs: 20000,
          idleStopMs: 900000
        }
      }
    }
  }
}
```

Why this matters:

- Model rows load faster.
- Provider aliases are easier to audit.
- Suppression rules prevent stale Codex/OpenAI-compatible rows from being selected when a runtime cannot actually serve them.
- Plugin startup gets cheaper because catalogs can be read without loading provider runtimes.
- Local model servers become explicit dependencies with health checks and idle shutdowns.

## 3. Use Active Memory Filters Before You Enable Broad Recall

Current memory builds make recall much more useful in real messaging environments:

- `allowedChatIds` / `deniedChatIds` let you scope Active Memory per conversation.
- Partial recall summaries are returned when the hidden memory sub-agent times out.
- People wiki metadata adds aliases, person cards, relationship graphs, privacy/provenance reports, evidence-kind drilldowns, and raw-claim search modes.
- `doctor.memory.remHarness` lets operator clients preview bounded REM output without mutation.

Recommended policy:

| Surface | Active Memory default |
|---------|-----------------------|
| Personal DM with owner | allow |
| Small work group where everyone expects memory | allow |
| Public/community channel | deny |
| Support inbox with sensitive user data | deny unless you have retention policy |
| One-off meeting/chat import | allow only for that chat ID |

The people wiki is powerful and easy to misuse. If the agent says something about a person, ask for provenance. Prefer "source evidence says..." over unaudited biographical summaries.

## 4. Turn On Visible-Reply Enforcement For Shared Channels

2026.4.29 adds `messages.visibleReplies`, with channel-specific overrides still available under `messages.groupChat.visibleReplies`. Use it when humans expect all visible output to go through the message tool instead of raw transcript text or partial side-channel replies.

Good default:

```json
{
  "messages": {
    "visibleReplies": true,
    "groupChat": {
      "visibleReplies": true
    }
  }
}
```

Pair it with active-run steering:

- Queue mode `steer` injects follow-ups at the next model boundary and is the default in 2026.5.14-beta.1.
- Use `/queue followup` for old "finish this run, then process the next message" behavior.
- Use `/queue collect` when users tend to send several small corrections that should become one later turn.
- Use `/queue interrupt` only when cancellation is safer than steering.
- Spawned sub-agent events now expose `spawnedBy`, so clients can route child-session updates without extra lookups.

This matters most in Slack, Telegram, Discord, Matrix, Teams, and other channels where a long-running agent can receive human corrections while it is still working.

Config shape:

```json5
{
  messages: {
    queue: {
      mode: "steer",
      byChannel: {
        telegram: { mode: "steer" },
        email: { mode: "collect" }
      }
    }
  }
}
```

## 5. Browser Automation Is Less Fragile Now

Current browser changes are practical:

- `openclaw browser click-coords` and viewport coordinate clicks help when selectors lie or overlays block target elements.
- `browser.actionTimeoutMs` defaults to a healthier 60s budget, so real browser waits stop failing at the client transport boundary.
- `browser.profiles.<name>.headless` lets one profile run headless without forcing every browser profile headless.
- Already-open Google Meet tabs can be recovered instead of duplicated.

Operator rule: use selectors when they are reliable; use coordinate clicks when the DOM is dynamic, canvas-based, or behind a shadow/overlay mess. Record the viewport assumption in the skill so future agents do not click blind.

## 6. Codex App-Server Is The Durable Path

2026.4.27 shipped Codex Computer Use setup/status/install commands:

```bash
openclaw codex computer-use status
openclaw codex computer-use install
```

Codex-mode desktop control now has marketplace discovery and fail-closed MCP checks before turns start. If the MCP server is missing, the run should fail closed instead of pretending desktop control works.

May 2026 changed the migration advice:

- Use canonical `openai/gpt-*` model refs such as `openai/gpt-5.5` for native Codex app-server runs.
- Treat `openai-codex` as an auth/profile surface, not a durable model prefix.
- The bundled `codex-cli` backend is removed in 2026.5.14-beta.1; legacy `codex-cli/*` refs should repair to the app-server route.
- Use `openclaw doctor --fix` when Codex OAuth/profile state is wedged.
- Keep Memory Bridge/`CONTEXT.md` for Codex workers; app-server routing fixes runtime plumbing, not institutional memory.

Use this for:

- UI test workers.
- Browser-heavy coding agents.
- Tasks where Codex owns the app-server thread but OpenClaw owns approvals, hooks, and memory.

Keep using [Part 13 — Memory Bridge](./part13-memory-bridge.md) when Codex needs your vault context.

## 7. Plugin Manifests Are The New Audit Surface

Recent plugin work moved metadata out of runtime code:

- `modelCatalog.aliases`
- `modelCatalog.suppressions`
- `setup.providers[].authMethods`
- `setup.providers[].envVars`
- `channelConfigs`
- runtime-dependency repair metadata
- descriptor-only setup via `setup.requiresRuntime: false`

When auditing a provider/plugin now, read the manifest first. The manifest tells you what models it claims, what auth methods it needs, which aliases it introduces, and which runtime dependencies it will repair. Runtime code still matters, but the manifest is the fast first pass.

May 2026 made this more important because more channel/provider cones are externalized. A lean core install is good; the tradeoff is that Bedrock, Slack, Anthropic Vertex, OpenShell sandbox, WhatsApp, and similar plugins now deserve first-class dependency review when you add them back.

## 8. Use `/context map` Before You Trim Blindly

Context debugging moved from vibes to inspection:

```text
/context list
/context detail
/context map
```

`/context map` persists a treemap of prompt contributors after a real Codex/OpenClaw run has produced context accounting. Use it before deleting useful memory or over-trimming skills. The usual surprises:

- Tool schemas dominate, not SOUL/MEMORY.
- Long skill examples cost more than their instructions.
- Re-injected workspace files beat conversation history.
- Group-channel history wrappers duplicate context when pending history is too generous.

If there is no cached run report yet, run one normal turn first; do not trust estimates as if they were measured prompt data.

## 9. Security Notes Worth Acting On

- **Outbound proxy routing** exists in 2026.4.27, but only with strict `http://` forward-proxy validation and loopback gateway bypass. Use it for corporate egress, not as a vague privacy toggle.
- **OpenGrep scanning** lands in 2026.4.29-beta.1. Add it to first-party plugin development once the rulepack stabilizes.
- **Docker GPU passthrough** is opt-in under `sandbox.docker.gpus`. Use it only when the host runtime supports `--gpus`.
- **OpenAI Codex auth import** briefly existed in 2026.4.22, then credentials migration was rolled back. Do not tell users to import ChatGPT/Codex OAuth into OpenClaw unless their exact build documents it.
- **Non-image chat attachments** now stage as agent-readable media paths in 2026.4.27. Still treat attachments as untrusted input.
- **Per-sender tool tiers** land in 2026.5.14-beta.1. Use `tools.toolsBySender` to strip `exec`, `write`, `edit`, and `apply_patch` from guest/public senders even when the agent itself is trusted.
- **Structured SecretRefs** replace raw provider key text in more plugin manifests. If a plugin still wants literal keys in config, treat that as a smell.
- **Schema stripping and requester-bound gateway approvals** are now part of the control-plane hardening path. Keep custom channel adapters honest about sender identity; never trust message text to declare who sent it.
- **Windows sandbox hardening** blocks home-root mounts. If your local automation assumed `C:\Users\<you>` was writable from sandboxed runs, narrow it to a workspace path.

Per-sender minimum:

```json5
{
  tools: {
    toolsBySender: {
      "*": { deny: ["exec", "process", "write", "edit", "apply_patch"] },
      "channel:discord:1234567890123": { alsoAllow: ["group:fs"] }
    }
  }
}
```

Keys are explicit sender identities from the channel adapter (`channel:<platform>:<id>`, `id:<id>`, `e164:<phone>`, `username:<handle>`, `name:<display-name>`, or `*`). Do not build a policy off display names parsed from chat text.

## The Newcomer Baseline

If someone finds this repo today and asks "what should I run?", tell them:

1. Install stable **2026.5.12** unless they specifically need 2026.5.14-beta.1 steering/voice/per-sender beta features.
2. Use `qwen3-embedding:0.6b` locally for embeddings.
3. Use Opus/Sonnet only behind explicit paid budget caps.
4. Put Kimi K2.6, DeepSeek V4 Flash, DeepInfra, or local models behind worker/fallback lanes.
5. Enable memory-core Dreaming; keep MEMORY.md as a pointer index.
6. Scope Active Memory per chat before enabling it broadly.
7. Keep ClawHub auto-update off and pin skill refs.
8. Use Task Brain semantic approvals and deny `control-plane.*` by default.
9. Use visible-reply enforcement and intentional queue modes in group/channel surfaces.
10. Audit manifests and per-sender tool policies before installing provider/plugins.
11. Use `/context map` after one real run before optimizing prompt bloat.
