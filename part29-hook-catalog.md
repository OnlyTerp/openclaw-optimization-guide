# Part 29: The Hook Catalog (Deterministic Enforcement)

> New in the April 2026 refresh. Hooks are the one enforcement layer an agent can't talk its way around — instructions are wishes, hooks are walls. This part ships **eight copy-paste hooks** that every production OpenClaw deployment should be running, plus the exit-code semantics that make them work.

> **Read this if** you depend on an agent not doing something (running a dangerous shell command, leaking a secret, blowing the budget, installing an unsigned skill) and "it's in AGENTS.md" isn't good enough.
> **Skip if** you're running a personal-dev single-user box and your blast radius is a laptop.

## Why Hooks Beat Instructions

An agent reading AGENTS.md is *advisory*. Hooks are *mandatory* — they run outside the model's control, at well-defined lifecycle events, and they can hard-block a tool call or session before it continues.

The distinction that most newcomers miss:

| Layer | Where it lives | What it can do | What the agent can do to it |
|-------|---------------|----------------|------------------------------|
| **Instruction** (SOUL/AGENTS.md) | Inside the prompt | Describe desired behavior | Ignore it, rationalize past it, forget it |
| **Skill** | Inside the tool graph | Provide new capabilities | Decide not to invoke it |
| **Hook** | Outside the model loop | Block, redact, log, transform | Nothing — the agent doesn't get a vote |

The practical rule from Amit Kothari's April 2026 post on hook debugging: *"If an instruction matters, it belongs in a hook. If a hook matters, its exit code matters more than its logic."* See *[What Is A Hook in Claude Code?](https://amitkoth.com/what-is-a-hook-claude-code/)* (Apr 11, 2026).

## Lifecycle Events & Exit Codes

Modern agent harnesses (OpenClaw, Claude Code, Cursor) converged on a similar lifecycle grammar over the past month. OpenClaw's event set tracks Claude Code's closely enough that hooks written for one port to the other with small adjustments. The events you actually use:

| Event | Fires when | Typical use |
|-------|-----------|-------------|
| **SessionStart** | Before the first turn | Inject context, enforce preconditions, set budgets |
| **SessionEnd** | On normal termination | Flush memory, write transcripts, capture learnings |
| **PreToolUse** | Before a tool call runs | Block dangerous calls, rewrite args, ask for approval |
| **PostToolUse** | After a tool call returns | Redact secrets, transform output, count tokens |
| **PreEdit** / **PostEdit** | Around file writes | Format on save, block writes outside scope |
| **Stop** | When the agent says "done" | Verify exit criteria (tests green, budget ok) |
| **Compact** | Before compaction | Decide what to keep, not the compaction model |
| **UserPromptSubmit** | On user message | Redact secrets from user input, inject context |

The April 2026 baseline is **18 events × 4 hook types** (`command`, `python`, `http`, `mcp`). Matt Arceneaux's *[Claude Code Hooks: The Complete Automation Guide](https://claudelab.net/en/articles/claude-code/claude-code-hooks-automation-master-guide)* (Apr 10, 2026) and the *[dev.to automation guide](https://dev.to/kfuras/claude-code-hooks-automate-your-coding-workflow-in-2026-3dkg)* (Apr 12, 2026) both land on essentially the same taxonomy.

Exit codes are the contract:

| Exit code | Meaning | What the agent sees |
|-----------|---------|---------------------|
| **0** | Allow | Tool call proceeds; stdout is injected as additional context |
| **1** | Error — continue | Tool call proceeds; stderr is surfaced as an error the agent can read and respond to |
| **2** | **Block** | Tool call is refused; stderr becomes the refusal message |
| **Other** | Treated as 1 | Don't rely on this |

> **Gotcha (Amit Kothari, Apr 11):** Most hook authors use `exit 1` for what they *mean* as "block" — and then spend a weekend wondering why the agent is blithely ignoring their "safety" hook. **`1` is soft; `2` is hard.** If you want the agent to stop, you need the `StopFailure` exit code, which in the April 2026 OpenClaw ships as `2`. Write a test that runs the hook with expected-block input and asserts `$? -eq 2`.

## The Eight Hooks Every Deployment Should Run

Each of the hooks below is a self-contained script. They assume a Unix-ish shell; PowerShell equivalents follow the same logic. Register each in `openclaw.json` under `hooks.<event>.<name>`.

### Hook 1 — `block-dangerous-shell`

**Event:** PreToolUse, tools `exec` / `bash` / `powershell`.
**What it blocks:** `rm -rf /`, `git reset --hard`, `git push --force` to protected branches, `curl | sh` patterns, `dd of=/dev/`.

```bash
#!/usr/bin/env bash
# hooks/block-dangerous-shell.sh
cmd="${OPENCLAW_TOOL_ARGS_COMMAND:-}"

deny_patterns=(
  'rm -rf /( |$)'                 # nuke root
  'rm -rf [~/]+( |$)'             # nuke home
  'git reset --hard'              # destroys WIP
  'git push.*--force.*(main|master|prod)'
  'curl[^|]*\| *(sh|bash)'        # curl | sh
  'dd .*of=/dev/'                 # disk destroyer
  ':\(\)\{ :\|:& \};:'            # forkbomb
)

for pat in "${deny_patterns[@]}"; do
  if [[ "$cmd" =~ $pat ]]; then
    echo "BLOCKED by block-dangerous-shell: matched /$pat/" >&2
    exit 2
  fi
done
exit 0
```

Wire it in:

```json
{
  "hooks": {
    "PreToolUse": {
      "block-dangerous-shell": {
        "match": { "tool": ["exec", "bash", "powershell"] },
        "command": "./hooks/block-dangerous-shell.sh"
      }
    }
  }
}
```

### Hook 2 — `secret-redact`

**Event:** PostToolUse (for output redaction) + UserPromptSubmit (for input redaction).
**What it does:** Rewrites any text matching known secret patterns to `[REDACTED:<kind>]` before the model sees it.

```python
#!/usr/bin/env python3
# hooks/secret-redact.py
import json, re, sys

PATTERNS = [
    ("aws_access_key",  r"AKIA[0-9A-Z]{16}"),
    ("aws_secret",      r"(?i)aws[_-]?secret[_-]?(access[_-]?)?key\s*[:=]\s*['\"]?([A-Za-z0-9/+=]{40})"),
    ("github_pat",      r"ghp_[A-Za-z0-9]{36,}"),
    ("openai_key",      r"sk-[A-Za-z0-9]{32,}"),
    ("anthropic_key",   r"sk-ant-[A-Za-z0-9_-]{40,}"),
    ("gcp_key",         r"AIza[0-9A-Za-z_-]{35}"),
    ("private_key",     r"-----BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY-----"),
    ("jwt",             r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"),
]

payload = json.load(sys.stdin)
for field in ("output", "prompt"):
    if field in payload and payload[field]:
        text = payload[field]
        for kind, pat in PATTERNS:
            text = re.sub(pat, f"[REDACTED:{kind}]", text)
        payload[field] = text
json.dump(payload, sys.stdout)
sys.exit(0)
```

Secret redaction is the single cheapest defense against the "my agent pasted my prod `AWS_SECRET_ACCESS_KEY` into a Slack message" class of incident. Run it on both sides of the boundary.

### Hook 3 — `cost-tripwire`

**Event:** SessionStart (set budget) + PostToolUse (enforce).
**What it does:** Tracks cumulative token spend per session, hard-blocks when the cap is hit.

```python
#!/usr/bin/env python3
# hooks/cost-tripwire.py
import json, os, sys
from pathlib import Path

try:
    SESSION_ID = os.environ["OPENCLAW_SESSION_ID"]
    STATE = Path(f"/tmp/openclaw-cost-{SESSION_ID}.json")
    CAP_USD = float(os.environ.get("OPENCLAW_SESSION_CAP_USD", "5.00"))

    payload = json.load(sys.stdin)
    usage = payload.get("usage", {})
    spend = usage.get("cost_usd", 0.0)

    total = json.loads(STATE.read_text())["total"] if STATE.exists() else 0.0
    total += spend
    STATE.write_text(json.dumps({"total": total}))

    if total >= CAP_USD:
        print(f"BLOCKED by cost-tripwire: session spend ${total:.2f} exceeded cap ${CAP_USD:.2f}", file=sys.stderr)
        sys.exit(2)

    if total >= 0.75 * CAP_USD:
        print(f"[cost-tripwire] WARNING: ${total:.2f} / ${CAP_USD:.2f} used", file=sys.stderr)

    sys.exit(0)
except Exception as e:
    # Fail CLOSED: a broken tripwire must block, not silently pass.
    print(f"BLOCKED by cost-tripwire: hook error ({e!r}) — refusing to run without cost tracking", file=sys.stderr)
    sys.exit(2)
```

Set `OPENCLAW_SESSION_CAP_USD=10.00` globally; override per-project via `.envrc`. Runaway sub-agent loops are the #1 source of surprise bills — a tripwire at 75% warning / 100% hard-stop catches them before the card gets hit.

### Hook 4 — `skill-install-deny`

**Event:** PreToolUse, tools matching `clawhub.install` / `skill.install`.
**What it does:** Blocks installation of skills outside an explicit allowlist.

```bash
#!/usr/bin/env bash
# hooks/skill-install-deny.sh
slug="${OPENCLAW_TOOL_ARGS_SLUG:-}"
ALLOWED=(
  "openclaw-team/*"
  "onlyterp/*"
  "your-org/*"
)

for pat in "${ALLOWED[@]}"; do
  if [[ "$slug" == $pat ]]; then exit 0; fi
done

echo "BLOCKED by skill-install-deny: $slug is not in the allowlist." >&2
echo "To override: install manually after reviewing diff + tool scope." >&2
exit 2
```

This is the structural fix for the ClawHavoc class of incident — not "review before install" (humans don't), but "the agent physically can't install anything outside a namespace you've whitelisted." See [Part 23](./part23-clawhub-skills-marketplace.md) for the full vetting checklist.

### Hook 5 — `dreaming-phase-gatekeeper`

**Event:** Stop (when the agent signals completion).
**What it does:** Before accepting "done", verify the current dreaming sweep's 3-phase state is coherent — no half-finished Deep phase, no orphan Light phase.

```bash
#!/usr/bin/env bash
# hooks/dreaming-phase-gatekeeper.sh
state="${OPENCLAW_VAULT:-.}/memory/.dreams/state.json"
[ ! -f "$state" ] && exit 0

last=$(jq -r '.lastSweep.phase // "none"' "$state")
status=$(jq -r '.lastSweep.status // "none"' "$state")

if [ "$status" = "in_progress" ]; then
  echo "BLOCKED: dreaming sweep is mid-$last; wait or force-resume." >&2
  exit 2
fi
exit 0
```

Catches the "agent declared done while memory-core is mid-consolidation" race. Rare, but corrupts MEMORY.md when it hits.

### Hook 6 — `tool-name-collision-alarm`

**Event:** SessionStart.
**What it does:** Asserts that no registered client tool normalize-collides with a built-in. This is the structural defense that 2026.4.15 stable added at the gateway; the hook is a belt-and-suspenders check you can run locally during development.

```python
#!/usr/bin/env python3
# hooks/tool-name-collision-alarm.py
import json, subprocess, sys, re

def normalize(name: str) -> str:
    return re.sub(r'[^a-z0-9]', '', name.lower())

tools = json.loads(subprocess.check_output(["openclaw", "tools", "list", "--json"]))
seen = {}
for t in tools:
    n = normalize(t["name"])
    if n in seen and t["source"] != seen[n]["source"]:
        print(f"BLOCKED: normalize-collision between "
              f"{seen[n]['source']}::{seen[n]['name']} and "
              f"{t['source']}::{t['name']}", file=sys.stderr)
        sys.exit(2)
    seen[n] = t
sys.exit(0)
```

The hole this closes: a malicious skill registers a tool called `exec_` that normalize-collides with the built-in `exec` and inherits its local-media trust level. 2026.4.15 stable rejects this at gateway registration; this hook fails loudly if you end up on a box that somehow bypassed it.

### Hook 7 — `auto-formatter`

**Event:** PostToolUse, tools matching `edit` / `write_file` / `patch`.
**What it does:** Runs the appropriate formatter on whatever the agent just wrote, then re-reads the file so the agent sees the formatted version.

```bash
#!/usr/bin/env bash
# hooks/auto-formatter.sh
path="${OPENCLAW_TOOL_ARGS_PATH:-}"
[ -z "$path" ] && exit 0

case "$path" in
  *.py)              ruff format "$path"       >/dev/null 2>&1 ;;
  *.ts|*.tsx|*.js)   prettier -w "$path"       >/dev/null 2>&1 ;;
  *.go)              gofmt -w "$path"          >/dev/null 2>&1 ;;
  *.rs)              rustfmt "$path"           >/dev/null 2>&1 ;;
  *.md)              markdownlint-cli2 --fix "$path" >/dev/null 2>&1 ;;
esac
exit 0
```

Never blocks — formatting disagreements should not fail a tool call. But it saves a round-trip of "the agent wrote unformatted code, the linter yelled, the agent re-read and reformatted."

### Hook 8 — `session-end-memory-flush`

**Event:** SessionEnd.
**What it does:** Appends a session-summary block to today's dreaming inbox so tomorrow's Deep phase has signal to score.

```bash
#!/usr/bin/env bash
# hooks/session-end-memory-flush.sh
inbox="${OPENCLAW_VAULT:-.}/memory/dreaming/inbox/$(date -u +%Y-%m-%d).md"
mkdir -p "$(dirname "$inbox")"

{
  echo ""
  echo "### session ${OPENCLAW_SESSION_ID} — $(date -uIseconds)"
  echo "**agent:** ${OPENCLAW_AGENT_ROLE:-main}"
  echo "**turns:** ${OPENCLAW_TURN_COUNT:-?}"
  echo "**tokens:** ${OPENCLAW_TOKEN_TOTAL:-?}"
  echo ""
  echo "${OPENCLAW_SESSION_SUMMARY:-(no summary provided)}"
} >> "$inbox"
exit 0
```

Coupled with the [Part 22](./README.md#part-22-built-in-dreaming) Deep-phase scoring, this is how you turn ephemeral session state into durable MEMORY.md entries without manually remembering to do anything.

## Wiring Them All Up

Reference block for `openclaw.json`:

```json5
{
  "hooks": {
    "SessionStart": {
      "cost-tripwire-init":      { "command": "./hooks/cost-tripwire.py" },
      "tool-collision-alarm":    { "command": "./hooks/tool-name-collision-alarm.py" }
    },
    "UserPromptSubmit": {
      "secret-redact-input":     { "command": "./hooks/secret-redact.py" }
    },
    "PreToolUse": {
      "block-dangerous-shell":   { "match": { "tool": ["exec","bash","powershell"] },
                                    "command": "./hooks/block-dangerous-shell.sh" },
      "skill-install-deny":      { "match": { "tool": ["clawhub.install","skill.install"] },
                                    "command": "./hooks/skill-install-deny.sh" }
    },
    "PostToolUse": {
      "secret-redact-output":    { "command": "./hooks/secret-redact.py" },
      "cost-tripwire-check":     { "command": "./hooks/cost-tripwire.py" },
      "auto-formatter":          { "match": { "tool": ["edit","write_file","patch"] },
                                    "command": "./hooks/auto-formatter.sh" }
    },
    "Stop": {
      "dreaming-phase-gate":     { "command": "./hooks/dreaming-phase-gatekeeper.sh" }
    },
    "SessionEnd": {
      "session-end-flush":       { "command": "./hooks/session-end-memory-flush.sh" }
    }
  }
}
```

Test every hook with a `--dry-run` flag before you ship it. A hook that throws because of a missing env var exits with code **1** (`Error — continue`) per the exit-code table above — which means every tool call **proceeds anyway** and your safety hook silently fails open. Catch exceptions at the top of each hook and `exit 2` explicitly if you want a hard block on error.

## Further Reading

- *[Claude Code Hooks: The Complete Automation Guide](https://claudelab.net/en/articles/claude-code/claude-code-hooks-automation-master-guide)* — Matt Arceneaux, Apr 10, 2026. The 18-event taxonomy this part follows.
- *[Claude Code Hooks: Automate Your Coding Workflow in 2026](https://dev.to/kfuras/claude-code-hooks-automate-your-coding-workflow-in-2026-3dkg)* — Kristoffer Furås, Apr 12, 2026. Practical examples with exit-code semantics.
- *[What Is A Hook in Claude Code?](https://amitkoth.com/what-is-a-hook-claude-code/)* — Amit Kothari, Apr 11, 2026. The exit-code debugging war story referenced above.
- *[agentpatterns.ai — Tool Engineering: Hooks & Lifecycle Events](https://agentpatterns.ai/tool-engineering/hooks-lifecycle-events/)* — Apr 15, 2026. Pattern-level framing of hooks as the deterministic enforcement layer.
- *[pydantic-ai #5046 — Hook MCP elicitation support](https://github.com/pydantic/pydantic-ai/issues/5046)* — Apr 13, 2026. The upstream discussion on hook-driven MCP elicitation that landed in March/April 2026.

## See Also

- [Part 15 — Infrastructure Hardening](./part15-infrastructure-hardening.md) — the gateway-level mitigations these hooks complement.
- [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md) — why `skill-install-deny` matters.
- [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md) — semantic approval categories, which hooks plug into.
- [Part 28 — Glossary](./part28-glossary-and-terminology.md) — definitions of hook event types, `StopFailure`, and related terms.
