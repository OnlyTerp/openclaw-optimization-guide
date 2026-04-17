# Part 24: Task Brain Control Plane

> Added for OpenClaw 2026.4.15-beta.1. Covers Task Brain, introduced in v2026.3.31-beta.1 and hardened across the 2026.4.x line in response to the March 2026 CVE wave.

## What Task Brain Is

Before 2026.3.31-beta.1, OpenClaw had four separate ways to run something:

- Your interactive agent session
- ACP (Agent-Callable Procedure) invocations
- Cron jobs (v4.0 built-in cron)
- Sub-agent spawns

Each had its own execution path, its own audit trail (or lack of one), and its own approval semantics. Getting a complete picture of "what is this OpenClaw instance actually doing right now?" meant grepping four different log locations.

Task Brain unified all of it. Every non-trivial action in OpenClaw \u2014 regardless of who kicked it off \u2014 is now a **task** in a single ledger. You can see it with:

```bash
openclaw tasks list
openclaw tasks show <task-id>
openclaw tasks audit --since 24h
```

Think of it as the Kubernetes control plane, but for AI agent actions: unified lifecycle, unified auth, unified observability.

## The March CVE Wave (Why This Matters)

Task Brain wasn't a gentle roadmap item. It shipped as the structural response to nine security CVEs published against OpenClaw in March 2026. The common thread across most of them:

- **Name-based allowlisting is not a security boundary.** The old approvals model let users write `approvals: { allow: ["bash", "exec"] }`. A malicious skill could register a new tool named `bash_v2` that did whatever it wanted \u2014 the allowlist matched on name, not intent.
- **No cross-surface enforcement.** A tool blocked in an interactive session was often still runnable via cron or sub-agent spawn, because each surface enforced approvals independently.
- **Approval prompts leaked credentials.** Covered in [Part 15](./part15-infrastructure-hardening.md) \u2014 2026.4.15-beta.1 redacts these now.

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

**Categories are assigned by the tool's declared intent, not by name.** A skill can't sidestep `execution.shell` by registering a tool called `totally_not_bash` \u2014 it still runs through the shell executor, so Task Brain categorizes it as `execution.shell` regardless of the display name.

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
- **`execution.*` \u2192 ask** (at least on first use, or by command signature). This is the one you'll actually approve/deny hundreds of times \u2014 the core agent behavior loop.
- **`write.network` \u2192 ask.** Tweeting, emailing, posting webhooks, API DELETEs. Asymmetric blast radius \u2014 one silent approve can send a message you can't recall.
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

Narrow-scope workers get frictionless autonomy inside their scope and hard walls outside it. The orchestrator keeps humans in the loop on anything destructive. This is the CEO/COO/Worker model from [Part 5](./README.md#part-5-orchestration) but with enforcement, not honor system.

## Agent-Initiated Denies (new in v2026.3.31-beta.1)

Task Brain added the inverse of the approval flow: an agent can now **refuse to do something you asked it to do** and have that refusal be a first-class event.

```
[agent] I've been asked to rm -rf ~/.openclaw/. I'm denying this because
        it would destroy the auth profiles. Flagging as task 9a3f-....
[you]   openclaw tasks show 9a3f
[you]   openclaw tasks approve 9a3f --reason "confirmed, starting fresh"
```

This matters because:

1. Prompt injection attacks can come from anywhere \u2014 a compromised vault file, a malicious skill, a poisoned memory entry. An agent that's allowed to refuse is an agent that has a chance to push back on an injected instruction.
2. The refusal is logged. You get to see "the agent almost did X, but stopped." That's a signal you used to miss entirely.

Don't punish agent denies. If your agent is refusing too often, tighten your prompts / approvals \u2014 don't try to suppress the deny behavior itself.

## Fail-Closed Plugin Defaults

Another 2026.3.31-beta.1 hardening: plugins now default to **fail-closed**. Pre-Task-Brain, an unconfigured plugin might do "whatever the author thought reasonable." Now:

- An unconfigured approval policy \u2192 treated as `ask`, not `allow`.
- A plugin that can't reach its backend \u2192 the task is held, not silently run without protection.
- A category Task Brain doesn't recognize \u2192 `ask`, not pass-through.

This trades a bit of friction for "we don't have unintended silent bypasses." It's the right trade for a production setup.

## Reading Your Task Ledger

A weekly habit worth building:

```bash
# What did this instance do this week?
openclaw tasks audit --since 7d | less

# Anything denied recently? (injection tells)
openclaw tasks audit --since 7d --status denied

# Anything still running? (stuck cron, forgotten spawn)
openclaw tasks list --status running

# What's my highest-privilege recent activity?
openclaw tasks audit --since 7d --category "control-plane.*"
```

You'll find:

- Cron jobs that haven't done anything useful in weeks (delete them)
- Skills making network calls you didn't realize (revisit [Part 23](./part23-clawhub-skills-marketplace.md))
- `control-plane.*` events clustered on a single skill (investigate hard)
- Denied tasks with interesting reasons (that's your agent catching prompt injection \u2014 good)

## The Task Brain Checklist

- [ ] Running OpenClaw 2026.3.31-beta.1 or later (Task Brain is mandatory from here)
- [ ] Approval policy set at the root with `read-only.* \u2192 allow`, `control-plane.* \u2192 ask or deny`
- [ ] No `execution.*` policies wider than the agent actually needs
- [ ] Per-agent scopes configured for worker agents (narrower than the orchestrator)
- [ ] `control-plane.skills` explicitly `deny` for all agents (install from CLI only)
- [ ] `openclaw tasks audit --since 7d` reviewed at least weekly
- [ ] Approval prompts show redacted secrets (2026.4.15-beta.1 \u2014 see [Part 15](./part15-infrastructure-hardening.md))
- [ ] Agents are not punished for denying \u2014 denies are logged and used as signal
- [ ] Unused plugins removed (fail-closed defaults apply, but unused surface is still surface)

Task Brain doesn't make OpenClaw bulletproof. It makes it **auditable and enforceable**, which is the minimum a multi-agent deployment needs. If you're running more than one agent, or letting any agent do anything in production that isn't read-only, you want this configured deliberately \u2014 not left at defaults.
