---
name: ralph-opencode-free-loop
description: Run an autonomous Open Ralph Wiggum coding loop using OpenCode Zen with free models and automatic fallback.
metadata:
  {
    "openclaw":
      {
        "emoji": "🔁",
        "homepage": "https://github.com/Th0rgal/open-ralph-wiggum",
        "requires": { "bins": ["opencode", "ralph", "git"] },
      },
  }
user-invocable: true
---

## What this skill does

This skill runs an autonomous **Ralph Wiggum** coding loop using the `ralph` CLI with OpenCode as the agent provider.

It repeatedly executes the same coding prompt until:

- The success criteria are met, OR
- The completion promise is printed, OR
- Max iterations are reached

The loop is optimized for **free OpenCode Zen models** and includes a fallback chain in case models are rate-limited, disabled, or removed.

---

## When to use

Use this skill when you want autonomous coding execution such as:

- Fixing failing tests
- Implementing scoped features
- Refactoring codebases
- Resolving lint/type errors
- Running build-fix loops
- Multi-iteration debugging

You MUST be inside a git repository before running Ralph.

---

## Free model fallback order

Always attempt models in this order:

1. `opencode/kimi-k2.5-free` ← Best coding performance (limited time free)
2. `opencode/minimax-m2.1-free`
3. `opencode/glm-4.7-free`
4. `opencode/big-pickle` ← Free stealth model fallback

If a model fails due to availability or quota, immediately retry using the next model without changing the prompt or loop parameters.

### Failure triggers for fallback

Fallback if you encounter errors like:

- model disabled
- model not found
- insufficient quota
- quota exceeded
- payment required
- rate limit
- provider unavailable

---

## How to run the loop

### Attempt #1 (primary model)

Run:

ralph "<TASK PROMPT>

Success criteria:

- <list verifiable checks>
- Build passes
- Tests pass

Completion promise:
<promise>COMPLETE</promise>" \
 --agent opencode \
 --model opencode/kimi-k2.5-free \
 --completion-promise "COMPLETE" \
 --max-iterations 20

---

### Attempt #2 (fallback)

If attempt #1 fails due to model issues, rerun with:

--model opencode/minimax-m2.1-free

---

### Attempt #3 (fallback)

If attempt #2 fails:

--model opencode/glm-4.7-free

---

### Attempt #4 (final fallback)

If attempt #3 fails:

--model opencode/big-pickle

---

## Tasks mode (for large projects)

For multi-step execution:

ralph "<BIG TASK PROMPT>" \
 --agent opencode \
 --model opencode/kimi-k2.5-free \
 --tasks \
 --max-iterations 50

Fallback model order still applies.

---

## Plugin troubleshooting

If OpenCode plugins interfere with loop execution, rerun with:

--no-plugins

---

## Sanity check available Zen models

If free model availability changes, check:

https://opencode.ai/zen/v1/models

Update fallback order if needed.

---

## Safety notes

- Always run inside a git repo
- Set iteration limits to avoid runaway loops
- Ensure prompts contain verifiable success criteria
- Review diffs before merging autonomous changes

---

## Example usage

Fix failing TypeScript errors:

ralph "Fix all TypeScript errors in the repo.

Success criteria:

- tsc passes
- Build succeeds

Completion promise:
<promise>COMPLETE</promise>" \
 --agent opencode \
 --model opencode/kimi-k2.5-free \
 --completion-promise "COMPLETE" \
 --max-iterations 20
