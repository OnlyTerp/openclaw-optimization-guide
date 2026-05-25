# Part 33: Late-May 2026 Field Guide

> **Read this if** you last tuned OpenClaw around 2026.5.12/2026.5.14 and want the current tricks without re-reading every release note.
> **Skip if** you're pinned before 2026.4.15 and still need the basics — start with [Part 26 — Migration Guide](./part26-migration-guide.md).

OpenClaw's late-May releases changed the operator playbook in eight places: Gateway startup, provider routing, memory/session hygiene, shared-channel policy, browser/Codex automation, voice/meeting capture, plugin/security boundaries, and media handling. This page is the catch-up map.

## Version Map

| Release | Why you care |
|---------|--------------|
| **2026.4.20** | Built-in session-store pruning, Kimi K2.6 as the bundled Moonshot default, tiered pricing in token reports, stronger default prompts. |
| **2026.4.22** | `/models add` and OpenAI Codex auth import landed, but both are now superseded or should be treated cautiously. |
| **2026.4.24-beta.1** | Google Meet, realtime voice consults, DeepSeek V4, browser coordinate clicks, 60s browser action budgets, per-profile headless overrides, manifest-backed model rows, `/models add` deprecation. |
| **2026.4.27 stable** | DeepInfra provider, Codex Computer Use setup/status/install commands, manifest-first plugin catalogs, Docker GPU passthrough, outbound proxy routing, non-image chat attachments. |
| **2026.4.29-beta.1** | Active-run steering, visible-reply enforcement, people-aware wiki metadata, Active Memory chat filters, partial recall on timeout, NVIDIA provider, Bedrock Opus 4.7 parity, OpenGrep scanning. |
| **2026.5.12 stable** | Former May baseline: leaner installs, Telegram resilience, safer plugin installs/updates, Codex app-server/runtime fallback improvements, Control UI/WebChat/TUI delivery fixes, ACP fallbacks, and gateway/browser/Slack/sandbox/transcript hardening. |
| **2026.5.14-beta.1** | Queue-steering beta: `/queue steer` default, `agents.defaults.runRetries`, Telnyx realtime calls, Codex app-server command fixes, bundled `codex-cli` backend removal/repair, WhatsApp status reactions, per-sender tool tiers, and nested sub-agent sessions in Control UI. |
| **2026.5.16 beta train** | Per-agent bootstrap profiles, localized setup, Telegram ambient `room_event`, `openclaw cron run --wait`, xAI Grok OAuth, Codex context-engine thread projection, Codex MCP server scoping, and `codex.defaultToolsApprovalMode`. |
| **2026.5.18 stable** | Stable rollup after 5.12: Control UI/Mac app polish, realtime Android/Discord/OpenAI voice follow-ups, Telegram/Discord delivery repairs, Codex/OpenAI app-server context/MCP/tool progress fixes, plugin SDK hardening, provider routing fixes, Node 22.19 floor, Docker/Podman `OPENCLAW_IMAGE_APT_PACKAGES`, and broad security robustness. |
| **2026.5.20 stable** | Policy plugin lands (`openclaw policy check`, attestations, doctor lint/repair), Discord voice can follow configured users, bounded voice bootstrap context, per-agent `experimental.localModelLean`, xAI device-code OAuth, OpenRouter provider routing policy, stricter skill-file exec approvals, secret symlink fail-closed behavior, and plaintext-secret doctor warnings. |
| **2026.5.22 stable** | Current stable baseline: Gateway startup/perf metadata caching, external Meeting Notes plugin with Discord voice source, docs/config clarifications, sanitized secret/tool telemetry, generic embedding-provider plugin contract, bounded subagent bootstrap context, xAI/Grok web-search auth reuse, session-store helper modernization, protobuf advisory refresh, and plugin dispatch caching. |
| **2026.5.24-beta.1** | Latest beta sweep: iMessage thumb approval reactions, WebUI/Discord voice status/cancel/steer/follow-up controls, Discord wake-name gating, adaptive `agents.defaults.imageQuality`, meeting-notes startup cleanup, named Codex OAuth profile storage, image/Antigravity media guidance, and more Gateway hot-path caching. |

If you want boring stability today, run **2026.5.22**. If you actively use WebUI/Discord voice steering, iMessage approval reactions, adaptive image compression, or named Codex OAuth profile storage, test **2026.5.24-beta.1** on a copy of your profile first.

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
- OpenRouter can honor provider-level `params.provider` routing policy, with model/agent params overriding it.
- xAI/Grok can use device-code OAuth on remote/headless hosts instead of brittle localhost callback tunnels.

Late-May provider rule: every provider route needs **auth shape + routing policy + budget cap**. A model ref alone is not production config.

## 3. Gateway Startup Is Faster, But Audit What You Enabled

2026.5.18-5.24 moved a lot of startup work off the hot path:

- Channel catalogs and bundled-channel metadata are cached process-locally.
- Plugin metadata snapshots are reused by startup, config, model, channel, setup, and secret readers.
- Startup-idle plugin work, Gateway method handlers, and the embedded ACPX runtime lazy-load later.
- Plugin SDK public-surface alias maps are cached instead of walking the filesystem repeatedly.
- Gateway watch CPU profiles rotate so benchmarks do not accumulate unbounded artifacts.

Do not interpret faster startup as permission to enable everything. The SOTA setup is still:

```text
openclaw plugins list
openclaw models list
openclaw channels list
openclaw doctor
```

Then remove plugins/channels/providers that are not used. Faster unused code is still unused attack surface.

## 4. Use Active Memory Filters Before You Enable Broad Recall

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

Late-May session warning: long-running coding/ops agents can still accumulate huge JSONL transcripts and lose effective context when sessions are reset or compacted badly. Keep `compaction.maxActiveTranscriptBytes`, cron/session isolation, and explicit `/new` or rotation policy in your runbook. Treat "the gateway is faster now" and "my session memory is healthy" as separate checks.

## 5. Turn On Visible-Reply Enforcement For Shared Channels

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

- Queue mode `steer` injects follow-ups at the next model boundary and is the default in the current May line.
- Use `/queue followup` for old "finish this run, then process the next message" behavior.
- Use `/queue collect` when users tend to send several small corrections that should become one later turn.
- Use `/queue interrupt` only when cancellation is safer than steering.
- Spawned sub-agent events now expose `spawnedBy`, so clients can route child-session updates without extra lookups.
- For ambient Telegram/Discord rooms, use `messages.groupChat.ambientTurns: "room_event"` only when you want quiet room context; room events should speak visibly only through the message tool.

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

## 6. Add Policy Checks Before Shared Channels

2026.5.20 adds the bundled Policy plugin. Use it to make channel conformance visible instead of hoping config and docs match reality:

```bash
openclaw policy check
openclaw doctor
```

What to check:

- Channel allowlists match the people who can actually approve/run tools.
- Accepted attestations have not drifted.
- Doctor findings flag missing or unsafe channel policy.
- Opt-in repair is reviewed before it mutates config.

This complements Task Brain. Task Brain decides whether a tool/action is allowed; Policy checks whether the channel surface is configured to request actions safely.

## 7. Browser Automation Is Less Fragile Now

Current browser changes are practical:

- `openclaw browser click-coords` and viewport coordinate clicks help when selectors lie or overlays block target elements.
- `browser.actionTimeoutMs` defaults to a healthier 60s budget, so real browser waits stop failing at the client transport boundary.
- `browser.profiles.<name>.headless` lets one profile run headless without forcing every browser profile headless.
- Already-open Google Meet tabs can be recovered instead of duplicated.
- Browser snapshots now surface pending/recent modal dialogs and `openclaw browser dialog --dialog-id` can answer them.
- `openclaw browser evaluate --timeout-ms` lets long page functions extend evaluate/request budgets deliberately.

Operator rule: use selectors when they are reliable; use coordinate clicks when the DOM is dynamic, canvas-based, or behind a shadow/overlay mess. Record the viewport assumption in the skill so future agents do not click blind.

## 8. Codex App-Server Is The Durable Path

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
- Scope user MCP servers to specific OpenClaw agent ids with `mcp.servers.<id>.codex.agents`; empty or invalid scopes should fail closed.
- Set Codex native tool approval defaults explicitly with `codex.defaultToolsApprovalMode` (`auto`, `prompt`, or `approve`) instead of inheriting surprising defaults.
- On restricted senders, verify deny-all policies also disable native code mode, built-in environments, user MCP projection, dynamic tools, and Codex app defaults.
- Use named OAuth profiles (`openclaw models auth login --profile-id ...`) when one host runs multiple Codex/OpenAI auth lanes.

Use this for:

- UI test workers.
- Browser-heavy coding agents.
- Tasks where Codex owns the app-server thread but OpenClaw owns approvals, hooks, and memory.

Keep using [Part 13 — Memory Bridge](./part13-memory-bridge.md) when Codex needs your vault context.

## 9. Voice And Meeting Notes Are First-Class Inputs Now

The late-May voice work is not just "talk to the bot":

- Discord voice sessions can follow configured users into voice channels with allowed-channel checks and bounded reconciliation.
- Discord/OpenAI realtime follow-ups keep hearing turns while a consult is active.
- WebUI and Discord voice callers can ask active run status, cancel, steer, or queue follow-up work mid-consult.
- Discord voice bootstraps bounded `IDENTITY.md`, `USER.md`, and `SOUL.md` context by default; set `voice.realtime.bootstrapContextFiles: []` if that is too much.
- Discord wake-name gating can default to the agent name.
- Meeting Notes is now a source-only external plugin with auto-start capture config, manual transcript imports, read-only `openclaw meeting-notes` CLI access, and Discord voice as the first live source.

Operator rule: voice and meeting notes are memory inputs. Decide retention, transcript redaction, and which meetings are allowed before auto-capture. Do not pipe every voice room into durable memory by default.

## 10. Tune Media/Image Cost Deliberately

2026.5.24-beta.1 adds adaptive model-aware image compression with:

```json5
{
  agents: {
    defaults: {
      imageQuality: "balanced"
    }
  }
}
```

Use:

| Mode | Use when |
|------|----------|
| `token-efficient` | Screenshots, quick UI checks, cheap worker agents |
| `balanced` | Default for mixed browser/media work |
| `high-detail` | Visual debugging, charts, design review, OCR-heavy work |

Also note the media stack stopped auto-probing Gemini CLI and treats Antigravity CLI as a lower-priority image/video fallback after configured provider APIs. Do not rely on hidden CLI probes as your media strategy.

## 11. Plugin Manifests Are The New Audit Surface

Recent plugin work moved metadata out of runtime code:

- `modelCatalog.aliases`
- `modelCatalog.suppressions`
- `setup.providers[].authMethods`
- `setup.providers[].envVars`
- `channelConfigs`
- runtime-dependency repair metadata
- descriptor-only setup via `setup.requiresRuntime: false`
- `contracts.embeddingProviders`
- SDK source-provider contracts such as Meeting Notes

When auditing a provider/plugin now, read the manifest first. The manifest tells you what models it claims, what auth methods it needs, which aliases it introduces, and which runtime dependencies it will repair. Runtime code still matters, but the manifest is the fast first pass.

May 2026 made this more important because more channel/provider cones are externalized. A lean core install is good; the tradeoff is that Bedrock, Slack, Anthropic Vertex, OpenShell sandbox, WhatsApp, and similar plugins now deserve first-class dependency review when you add them back.

Generic `contracts.embeddingProviders` and `api.registerEmbeddingProvider(...)` make embeddings a plugin capability, not only memory-core internals. Keep local Ollama/Qwen as the default, but expect OpenAI-compatible explicit embedding providers to become cleaner.

## 12. Use `/context map` Before You Trim Blindly

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

## 13. Security Notes Worth Acting On

- **Outbound proxy routing** exists in 2026.4.27, but only with strict `http://` forward-proxy validation and loopback gateway bypass. Use it for corporate egress, not as a vague privacy toggle.
- **OpenGrep scanning** lands in 2026.4.29-beta.1. Add it to first-party plugin development once the rulepack stabilizes.
- **Docker GPU passthrough** is opt-in under `sandbox.docker.gpus`. Use it only when the host runtime supports `--gpus`.
- **OpenAI Codex auth import** briefly existed in 2026.4.22, then credentials migration was rolled back. Do not tell users to import ChatGPT/Codex OAuth into OpenClaw unless their exact build documents it.
- **Non-image chat attachments** now stage as agent-readable media paths in 2026.4.27. Still treat attachments as untrusted input.
- **Per-sender tool tiers** land in 2026.5.14-beta.1. Use `tools.toolsBySender` to strip `exec`, `write`, `edit`, and `apply_patch` from guest/public senders even when the agent itself is trusted.
- **Structured SecretRefs** replace raw provider key text in more plugin manifests. If a plugin still wants literal keys in config, treat that as a smell.
- **Schema stripping and requester-bound gateway approvals** are now part of the control-plane hardening path. Keep custom channel adapters honest about sender identity; never trust message text to declare who sent it.
- **Windows sandbox hardening** blocks home-root mounts. If your local automation assumed `C:\Users\<you>` was writable from sandboxed runs, narrow it to a workspace path.
- **Skill exec compatibility is gone.** Skill files must be loaded with the read tool; the old `cat SKILL.md && printf ...` allowlist path was removed.
- **Secret symlinks fail closed.** Credential loaders for Telegram, LINE, Zalo, IRC, and Nextcloud Talk reject symlinked secret files when `rejectSymlink: true` is used.
- **Plaintext secrets are doctor findings.** `openclaw doctor` warns on model provider API keys and sensitive provider headers stored literally in `openclaw.json`.
- **Approval reactions are convenience, not governance.** iMessage and WhatsApp thumbs are useful for `allow-once`/deny, but explicit approver allowlists and `/approve allow-always` discipline still matter.

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

1. Install stable **2026.5.22** unless they specifically need 2026.5.24-beta.1 voice steering, iMessage approval reactions, or image-quality controls.
2. Use `qwen3-embedding:0.6b` locally for embeddings.
3. Use Opus/Sonnet only behind explicit paid budget caps.
4. Put Kimi K2.6, DeepSeek V4 Flash, DeepInfra, or local models behind worker/fallback lanes.
5. Enable memory-core Dreaming; keep MEMORY.md as a pointer index.
6. Scope Active Memory per chat before enabling it broadly.
7. Keep ClawHub auto-update off and pin skill refs.
8. Use Task Brain semantic approvals and deny `control-plane.*` by default.
9. Run `openclaw policy check` and fix channel findings before inviting other users.
10. Use visible-reply enforcement and intentional queue modes in group/channel surfaces.
11. Audit manifests and per-sender tool policies before installing provider/plugins.
12. If you use voice/meetings, define transcript retention and redaction before enabling auto-capture.
13. Use `/context map` after one real run before optimizing prompt bloat.

## What To Delete From Old Runbooks

Delete or rewrite advice that says:

- "Use Claude Pro/Max subscription for OpenClaw."
- "Register models with `/models add` during setup."
- "Use `openai-codex/*` or `codex-cli/*` as durable model refs."
- "Enable Active Memory globally."
- "Let public channel users inherit the agent's tools."
- "Keep all provider/channel plugins bundled just in case."
- "Start Ollama manually and hope the agent remembers."
- "Selectors only; coordinate clicks are always bad."
- "A fast Gateway means session/transcript retention is solved."
- "Voice transcripts can go straight into memory by default."
- "One OpenRouter route is enough; provider routing policy is optional."
- "A Codex model ref alone proves MCP/tool policy is safe."
- "Image quality should always be high-detail."
