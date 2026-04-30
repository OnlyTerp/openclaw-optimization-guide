# Part 33: Late-April 2026 Field Guide

> **Read this if** you last tuned OpenClaw around 2026.4.15 and want the current tricks without re-reading every release note.
> **Skip if** you're pinned before 2026.4.15 and still need the basics — start with [Part 26 — Migration Guide](./part26-migration-guide.md).

OpenClaw's late-April releases changed the operator playbook in five places: providers, memory, messaging, browser/Codex automation, and plugin security. This page is the catch-up map.

## Version Map

| Release | Why you care |
|---------|--------------|
| **2026.4.20** | Built-in session-store pruning, Kimi K2.6 as the bundled Moonshot default, tiered pricing in token reports, stronger default prompts. |
| **2026.4.22** | `/models add` and OpenAI Codex auth import landed, but both are now superseded or should be treated cautiously. |
| **2026.4.24-beta.1** | Google Meet, realtime voice consults, DeepSeek V4, browser coordinate clicks, 60s browser action budgets, per-profile headless overrides, manifest-backed model rows, `/models add` deprecation. |
| **2026.4.27 stable** | DeepInfra provider, Codex Computer Use setup/status/install commands, manifest-first plugin catalogs, Docker GPU passthrough, outbound proxy routing, non-image chat attachments. |
| **2026.4.29-beta.1** | Active-run steering, visible-reply enforcement, people-aware wiki metadata, Active Memory chat filters, partial recall on timeout, NVIDIA provider, Bedrock Opus 4.7 parity, OpenGrep scanning. |

If you want boring stability today, run **2026.4.27**. If you actively use memory-heavy messaging surfaces, test **2026.4.29-beta.1** in a separate profile first — the memory changes are worth it, but they're still beta.

## 1. Stop Assuming Claude Subscription Usage

Older OpenClaw advice said "use Claude Pro/Max membership; don't pay API rates." That is no longer safe. Anthropic's April 4 cutoff moved many third-party OpenClaw users onto explicit paid provider routes.

Current operator default:

1. Put Opus/Sonnet behind a paid route you can see and budget.
2. Add at least two non-Anthropic fallbacks.
3. Put infrastructure work on cheap models.
4. Review token reports after one real day, not after a toy prompt.

Good fallback lanes in late April:

- **DeepSeek V4 Flash** — new bundled onboarding default in 2026.4.24; use for cheap worker traffic.
- **Kimi K2.6** — new Moonshot default in 2026.4.20; use for research, media understanding, and sub-agents.
- **DeepInfra** — bundled provider in 2026.4.27; useful when you want model breadth without more first-party keys.
- **NVIDIA** — beta provider in 2026.4.29; useful if your org already buys NVIDIA hosted inference.
- **Cerebras** — still strong for fast infrastructure calls and LightRAG extraction.

## 2. Treat Model Registration As Config, Not Chat

`/models add` was added in 2026.4.22, then deprecated in 2026.4.24. This is the important part: late-April OpenClaw is moving toward **manifest-backed model catalogs**. Provider plugins declare rows, aliases, suppressions, auth choices, and discovery behavior without loading their runtime.

Do this:

```text
/models       # inspect available rows and auth state
openclaw models list
edit provider/config deliberately
restart or refresh the gateway auth path if needed
```

Do **not** build runbooks that tell agents to call `/models add` mid-chat.

Why this matters:

- Model rows load faster.
- Provider aliases are easier to audit.
- Suppression rules prevent stale Codex/OpenAI-compatible rows from being selected when a runtime cannot actually serve them.
- Plugin startup gets cheaper because catalogs can be read without loading provider runtimes.

## 3. Use Active Memory Filters Before You Enable Broad Recall

2026.4.29-beta.1 makes memory much more useful in real messaging environments:

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

- Queue mode `steer` injects follow-ups at the next model boundary.
- Legacy one-at-a-time behavior is still available as `queue`.
- Spawned sub-agent events now expose `spawnedBy`, so clients can route child-session updates without extra lookups.

This matters most in Slack, Telegram, Discord, Matrix, Teams, and other channels where a long-running agent can receive human corrections while it is still working.

## 5. Browser Automation Is Less Fragile Now

Late-April browser changes are practical:

- `openclaw browser click-coords` and viewport coordinate clicks help when selectors lie or overlays block target elements.
- `browser.actionTimeoutMs` defaults to a healthier 60s budget, so real browser waits stop failing at the client transport boundary.
- `browser.profiles.<name>.headless` lets one profile run headless without forcing every browser profile headless.
- Already-open Google Meet tabs can be recovered instead of duplicated.

Operator rule: use selectors when they are reliable; use coordinate clicks when the DOM is dynamic, canvas-based, or behind a shadow/overlay mess. Record the viewport assumption in the skill so future agents do not click blind.

## 6. Codex Computer Use Is Now A First-Class Setup

2026.4.27 ships Codex Computer Use setup/status/install commands:

```bash
openclaw codex computer-use status
openclaw codex computer-use install
```

Codex-mode desktop control now has marketplace discovery and fail-closed MCP checks before turns start. If the MCP server is missing, the run should fail closed instead of pretending desktop control works.

Use this for:

- UI test workers.
- Browser-heavy coding agents.
- Tasks where Codex owns the app-server thread but OpenClaw owns approvals, hooks, and memory.

Keep using [Part 13 — Memory Bridge](./part13-memory-bridge.md) when Codex needs your vault context.

## 7. Plugin Manifests Are The New Audit Surface

Late-April plugin work moved metadata out of runtime code:

- `modelCatalog.aliases`
- `modelCatalog.suppressions`
- `setup.providers[].authMethods`
- `setup.providers[].envVars`
- `channelConfigs`
- runtime-dependency repair metadata
- descriptor-only setup via `setup.requiresRuntime: false`

When auditing a provider/plugin now, read the manifest first. The manifest tells you what models it claims, what auth methods it needs, which aliases it introduces, and which runtime dependencies it will repair. Runtime code still matters, but the manifest is the fast first pass.

## 8. Security Notes Worth Acting On

- **Outbound proxy routing** exists in 2026.4.27, but only with strict `http://` forward-proxy validation and loopback gateway bypass. Use it for corporate egress, not as a vague privacy toggle.
- **OpenGrep scanning** lands in 2026.4.29-beta.1. Add it to first-party plugin development once the rulepack stabilizes.
- **Docker GPU passthrough** is opt-in under `sandbox.docker.gpus`. Use it only when the host runtime supports `--gpus`.
- **OpenAI Codex auth import** briefly existed in 2026.4.22, then credentials migration was rolled back. Do not tell users to import ChatGPT/Codex OAuth into OpenClaw unless their exact build documents it.
- **Non-image chat attachments** now stage as agent-readable media paths in 2026.4.27. Still treat attachments as untrusted input.

## The Newcomer Baseline

If someone finds this repo today and asks "what should I run?", tell them:

1. Install stable **2026.4.27** unless they specifically need 2026.4.29 memory beta features.
2. Use `qwen3-embedding:0.6b` locally for embeddings.
3. Use Opus/Sonnet only behind explicit paid budget caps.
4. Put Kimi K2.6, DeepSeek V4 Flash, DeepInfra, or local models behind worker/fallback lanes.
5. Enable memory-core Dreaming; keep MEMORY.md as a pointer index.
6. Scope Active Memory per chat before enabling it broadly.
7. Keep ClawHub auto-update off and pin skill refs.
8. Use Task Brain semantic approvals and deny `control-plane.*` by default.
9. Use visible-reply enforcement in group/channel surfaces.
10. Audit manifests before installing provider/plugins.
