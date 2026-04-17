# Part 24: Task Brain Control Plane

> Added for OpenClaw 2026.4.15. Covers Task Brain, introduced in v2026.3.31-beta.1 and hardened across the 2026.4.x line in response to the March 2026 CVE wave.

> **Read this if** you're on OpenClaw v2026.3.31-beta.1 or later (you are, if you're up to date), run sub-agents, use approvals, or do anything in production.
> **Skip if** you're on a pre-Task-Brain build — but in that case you should upgrade first (see [Part 26](./part26-migration-guide.md)).

## What Task Brain Is

Before 2026.3.31-beta.1, OpenClaw had four separate ways to run something:

- Your interactive agent session
- ACP (Agent-Callable Procedure) invocations
- Cron jobs (v4.0 built-in cron)
- Sub-agent spawns

Each had its own execution path, its own audit trail (or lack of one), and its own approval semantics. Getting a complete picture of "what is this OpenClaw instance actually doing right now?" meant grepping four different log locations.

Task Brain unified all of it onto a **SQLite-backed task flow registry**. Every non-trivial action in OpenClaw — regardless of who kicked it off — is now a flow in one ledger. You see it with:

```bash
openclaw flows list
openclaw flows show <flow-id>
openclaw flows cancel <flow-id>
```

> The release notes call this the **task flow registry**. Internal design docs from earlier betas called it the "task ledger" / "tasks" — if you read anything from before April 2026, the nouns don't match, but the object model does. The published CLI as of 2026.4.15 is `openclaw flows`.

Think of it as the Kubernetes control plane, but for AI agent actions: unified lifecycle, heartbeat monitoring with automatic recovery of lost tasks, parent-record tracking so subtask results trace back to the originating conversation, and blocked-state persistence so tasks retry on the same flow instead of fragmenting.

## The February–March CVE Wave (Why This Matters)

Task Brain wasn't a gentle roadmap item. It shipped as the structural response to a cluster of CVEs disclosed against OpenClaw over February–March 2026. Headline entries included `CVE-2026-25253` (one-click RCE), `CVE-2026-25157` (command injection), `CVE-2026-25158` (path traversal), plus a WebSocket shared-auth scope escalation at **CVSS 9.9** ([nine CVEs in four days](https://www.tryopenclaw.ai/blog/openclaw-cve-flood-march-2026/) in mid-March alone). Peter Steinberger's [official release post](https://openclawai.io/blog/openclaw-task-brain-v2026-3-31-control-plane-security) described the v2026.3.31-beta.1 drop as "primarily about security hardening." The common thread across most of those CVEs:

- **Name-based allowlisting is not a security boundary.** The old approvals model let users write `approvals: { allow: ["bash", "exec"] }`. A malicious skill could register a new tool named `bash_v2` that did whatever it wanted — the allowlist matched on name, not intent.
- **No cross-surface enforcement.** A tool blocked in an interactive session was often still runnable via cron or sub-agent spawn, because each surface enforced approvals independently.
- **Approval prompts leaked credentials.** Covered in [Part 15](./part15-infrastructure-hardening.md) — 2026.4.15 redacts these now.

Task Brain replaces name-based allowlisting with **semantic approval categories** and enforces them at a single choke point every surface goes through.

## Semantic Approval Categories

Every tool invocation is now classified into one of a small fixed set of categories. The canonical ones:

| Category | Meaning | Examples |
|----------|---------|----------|
| `read-only.filesystem` | Reads from disk, no writes | `read_file`, `grep`, `memory_search` |
| `read-only.network` | Read-only network calls | `web.search`, `web.fetch`, API `GET`s |
| `execution.shell` | Runs shell commands | `exec`, `bash`, `powershell` |
| `execution.code` | Runs interpreter code | `python`, `node`, REPL tools |
| `write.filesystem` | Modifies files | `write_file`, `edit`, `patch` |
| `write.network` | Non-trivial network writes | API `POST`/`PUT`/`DELETE`, webhooks, email, tweet |
| `control-plane.secrets` | Reads/writes secrets | `secrets.get`, `secrets.set`, `secrets.reload` |
| `control-plane.tasks` | Controls other Task Brain tasks | spawn, cancel, approve, deny |
| `control-plane.skills` | Installs/removes/updates skills | ClawHub operations, see [Part 23](./part23-clawhub-skills-marketplace.md) |

**Categories are assigned by the tool's declared intent, not by name.** A skill can't sidestep `execution.shell` by registering a tool called `totally_not_bash` — it still runs through the shell executor, so Task Brain categorizes it as `execution.shell` regardless of the display name.

## The Default Policy We Recommend

```json5
{
  "approvals": {
    "read-only.*":        "allow",      // frictionless
    "execution.shell":    "ask",        // per-call approval
    "execution.code":     "ask",
    "write.filesystem":   "allow",      // inside repo scope; narrow if needed
    "write.network":      "ask",
    "control-plane.*":    "ask",        // never silent
    "control-plane.skills": "deny"      // explicitly install from CLI only
  }
}
```

Rules of thumb:

- **`read-only.*` \u2192 allow.** Agents need to read to be useful. Logging is fine, approval prompts on every file read are not.
- **`execution.*` \u2192 ask** (at least on first use, or by command signature). This is the one you'll actually approve/deny hundreds of times — the core agent behavior loop.
- **`write.network` \u2192 ask.** Tweeting, emailing, posting webhooks, API DELETEs. Asymmetric blast radius — one silent approve can send a message you can't recall.
- **`control-plane.*` \u2192 never `allow`.** This is the key structural change. If a skill is installing other skills, rotating secrets, or cancelling tasks on its own, that's the shape of a privilege-escalation attack. Keep these approval-required even if it's annoying.
- **`control-plane.skills` \u2192 deny.** Install skills from the CLI with a human in the loop. Don't let an agent install its own toolbelt autonomously.

## Per-Agent Trust Boundaries

You can set different approval policies per agent. The pattern we use on our 14-agent deployment:

```json5
{
  "agents": {
    "main-orchestrator": {
      "approvals": {
        "read-only.*": "allow",
        "execution.*": "ask",
        "write.network": "ask",
        "control-plane.*": "ask"
      }
    },
    "coding-worker": {
      "approvals": {
        "read-only.*": "allow",
        "execution.shell": "allow",       // spawn trusted, needs to run tests
        "execution.code": "allow",
        "write.filesystem": "allow",
        "write.network": "deny",           // workers should never post
        "control-plane.*": "deny"
      }
    },
    "research-worker": {
      "approvals": {
        "read-only.*": "allow",
        "write.*": "deny",                 // research only
        "execution.*": "deny",
        "control-plane.*": "deny"
      }
    }
  }
}
```

Narrow-scope workers get frictionless autonomy inside their scope and hard walls outside it. The orchestrator keeps humans in the loop on anything destructive. This is the CEO/COO/Worker model from [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself) but with enforcement, not honor system.

## Agent-Initiated Denies (new in v2026.3.31-beta.1)

Task Brain added the inverse of the approval flow: an agent can now **refuse to do something you asked it to do** and have that refusal be a first-class event.

```
[agent] I've been asked to rm -rf ~/.openclaw/. I'm denying this because
        it would destroy the auth profiles. Flagging as task 9a3f-....
[you]   openclaw flows show 9a3f
[you]   # confirm context, re-issue the request with explicit approval
```

This matters because:

1. Prompt injection attacks can come from anywhere — a compromised vault file, a malicious skill, a poisoned memory entry. An agent that's allowed to refuse is an agent that has a chance to push back on an injected instruction.
2. The refusal is logged. You get to see "the agent almost did X, but stopped." That's a signal you used to miss entirely.

Don't punish agent denies. If your agent is refusing too often, tighten your prompts / approvals — don't try to suppress the deny behavior itself.

## Fail-Closed Plugin Defaults

Another 2026.3.31-beta.1 hardening: plugins now default to **fail-closed**. Pre-Task-Brain, an unconfigured plugin might do "whatever the author thought reasonable." Now:

- An unconfigured approval policy \u2192 treated as `ask`, not `allow`.
- A plugin that can't reach its backend \u2192 the task is held, not silently run without protection.
- A category Task Brain doesn't recognize \u2192 `ask`, not pass-through.

This trades a bit of friction for "we don't have unintended silent bypasses." It's the right trade for a production setup.

## Reading Your Task Ledger

A weekly habit worth building:

```bash
# What's running right now? (stuck cron, forgotten spawn)
openclaw flows list --status running

# Dig into anything that looks odd
openclaw flows show <flow-id>

# Cancel runaway or orphaned flows
openclaw flows cancel <flow-id>
```

For longer-horizon auditing (7-day window, category filters, denied/approved breakdowns), subcommand flags have moved between betas — run `openclaw flows --help` against your installed version for the exact set. As of 2026.4.15 the published verbs are `list`, `show`, and `cancel`. Category filtering and denied-flow rollups are primarily visible through the **Control UI** (Canvas → Flows), not via CLI flags.

You'll find:

- Cron jobs that haven't done anything useful in weeks (delete them)
- Skills making network calls you didn't realize (revisit [Part 23](./part23-clawhub-skills-marketplace.md))
- `control-plane.*` events clustered on a single skill (investigate hard)
- Denied tasks with interesting reasons (that's your agent catching prompt injection — good)

## OpenClaw vs. Cloud-Sandbox Delegation (Twill / Amika)

**Callout added in the April 2026 refresh.** Two YC-backed services that launched on cloud-sandbox agent delegation landed this week:

- **[Twill.ai](https://news.ycombinator.com/item?id=47720418)** (YC S25, HN thread Apr 11, 2026) — run the agent on their sandbox instead of your laptop. Their pitch: agents shouldn't have shell access to your primary environment; delegate the whole session to an ephemeral cloud VM.
- **[Amika](https://www.youtube.com/watch?v=OZzdBNBXxSU)** (Apr 13, 2026, YouTube walkthrough) — similar model, different operator experience. Focuses on "give the agent a container, not your dev box."

This is a real architectural choice. Here's the positioning an OpenClaw operator should know:

| Dimension | OpenClaw + Task Brain | Twill / Amika (cloud sandbox) |
|-----------|------------------------|--------------------------------|
| **Where the agent runs** | On-prem, your box / server / worktree | Their cloud, ephemeral VM per session |
| **Data residency** | Yours. Everything stays local. | Theirs. Your code/secrets transit their infrastructure. |
| **Setup cost** | Configure approvals, hooks, memory. This guide. | `pip install` + credit card. |
| **Trust model** | You enforce approvals + hooks; agent has full local blast radius | They enforce sandbox boundaries; agent blast radius = their VM |
| **Cost model** | Your infra + your model tokens | Their infra markup + your model tokens |
| **Audit trail** | `openclaw flows list`, your logs | Their dashboard. You may or may not get the raw log. |
| **Customizability** | Full — every part of this guide | Fixed to what their UI exposes |
| **Offline / air-gapped** | Works | Does not |

**The OpenClaw answer to cloud-sandbox delegation:** Task Brain's semantic approval categories + the [Part 29 hook catalog](./part29-hook-catalog.md) + [Part 15 worktrees](./part15-infrastructure-hardening.md) give you the same blast-radius containment without shipping your codebase to a third party. If you need harder isolation than worktrees (container-per-agent, VM-per-agent), pair with Docker/Firecracker — the hooks and approvals still apply unchanged.

**When cloud sandboxes genuinely win:** one-off workloads where you don't want to stand up local infrastructure at all, or environments where "agent on dev laptop" is a compliance non-starter. For a team running OpenClaw seriously, the on-prem path is the one this guide is written for.

---

## The Task Brain Checklist

- [ ] Running OpenClaw 2026.3.31-beta.1 or later (Task Brain is mandatory from here)
- [ ] Approval policy set at the root with `read-only.* \u2192 allow`, `control-plane.* \u2192 ask or deny`
- [ ] No `execution.*` policies wider than the agent actually needs
- [ ] Per-agent scopes configured for worker agents (narrower than the orchestrator)
- [ ] `control-plane.skills` explicitly `deny` for all agents (install from CLI only)
- [ ] `openclaw flows list` reviewed weekly — watch for stuck, denied, or orphaned flows (Canvas Flows panel gives the richer view)
- [ ] Approval prompts show redacted secrets (2026.4.15 — see [Part 15](./part15-infrastructure-hardening.md))
- [ ] Agents are not punished for denying — denies are logged and used as signal
- [ ] Unused plugins removed (fail-closed defaults apply, but unused surface is still surface)

Task Brain doesn't make OpenClaw bulletproof. It makes it **auditable and enforceable**, which is the minimum a multi-agent deployment needs. If you're running more than one agent, or letting any agent do anything in production that isn't read-only, you want this configured deliberately — not left at defaults.
