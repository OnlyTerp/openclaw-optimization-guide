# Codex Onboarding Addendum

> Read this if you are wiring Codex into the OpenClaw/Ralph workflow and want the missing onboarding checks that are easy to skip.

This addendum fills the gap between the OpenClaw Memory Bridge guidance in Part 13 and the current Codex onboarding behavior documented by OpenAI. It is deliberately additive: it does not change the preserved OpenClaw runtime, model routing, Task Brain approvals, templates, or server workspace snapshot.

## What Perplexity-style summaries usually miss

1. Codex instruction loading is scoped and ordered, not magic. Codex reads global guidance from the Codex home directory first, then walks from the Git/project root down to the current working directory. More specific files appear later and override earlier guidance. Source: https://developers.openai.com/codex/guides/agents-md
2. `AGENTS.override.md` wins over `AGENTS.md` at the same level. This is useful for temporary automation profiles, but dangerous if a stale override hides the real repo rules. Source: https://developers.openai.com/codex/guides/agents-md
3. Instruction loading has a byte cap. The current default is 32 KiB for project docs, so a huge root `AGENTS.md` can silently crowd out deeper guidance unless `project_doc_max_bytes` is raised or instructions are split into nested files. Source: https://developers.openai.com/codex/guides/agents-md
4. Codex builds its instruction chain once per run or TUI session. If instructions look stale, start a new run in the target directory instead of assuming a live reload happened. Source: https://developers.openai.com/codex/guides/agents-md
5. Codex shell sandboxing only covers Codex's own shell tool. MCP tools and other external tools need their own guardrails, approvals, and redaction because they are not automatically sandboxed by Codex. Source: https://openai.com/index/unrolling-the-codex-agent-loop/
6. Prompt caching rewards stable prefixes. Keep global and repo instructions stable at the beginning, and put task-specific details, user data, and volatile Memory Bridge output later. Source: https://openai.com/index/unrolling-the-codex-agent-loop/
7. Codex plan access, data controls, plugins, RBAC, and delegated cloud usage are admin surfaces, not just local CLI setup. Business and Enterprise/Edu workspaces should verify workspace controls before enabling teammate workflows. Source: https://help.openai.com/en/articles/11369540

## OpenClaw/Ralph onboarding checklist

Run this checklist before asking Codex to work inside an OpenClaw or Ralph-managed repository.

- Confirm the working directory is the intended Git root or a deliberately chosen subdirectory.
- Check for global `AGENTS.override.md` and repo-local `AGENTS.override.md` files before assuming `AGENTS.md` is active.
- Keep root guidance concise. If it approaches 32 KiB, move specialized rules into nested `AGENTS.md` files close to the files they govern.
- Put volatile run facts in the task prompt or generated context, not at the top of permanent instructions.
- Run `node scripts/lib/preflight-context.js .` before spawning Codex so Codex receives current repo facts without manually reading the whole repository.
- Tell Codex which verification command must pass and which files are preserve-only.
- Keep MCP and external tool permissions aligned with OpenClaw Task Brain approval categories; do not assume Codex sandbox settings protect every tool.
- For cloud or teammate onboarding, verify ChatGPT workspace controls, plugin controls, RBAC, and GitHub connection status before a task can push or open a PR.
- Ask Codex to report instruction sources at the start of the first task in a new environment. Treat a missing or unexpected source as an onboarding failure.

## Minimal task prompt for this repo

Use a prompt like this when handing a bounded task to Codex from this repository:

```text
You are working in openclaw-optimization-guide.
First, summarize the active instruction files you loaded.
Then read PROMPT.md, AGENTS.md, CLAUDE.md, SECURITY.md, IMPLEMENTATION_PLAN.md, and the files relevant to the requested task.
Do not modify configs/balanced.openclaw.json, templates/*, or server-config/workspace/*.
Before coding, run: node scripts/lib/preflight-context.js .
Make only additive or explicitly requested fixes.
Run the relevant tests and report exact commands plus results.
```

## Failure modes

- Wrong root: Codex starts under a subdirectory and misses root-level guidance. Restart with the intended `--cd` path.
- Hidden override: `AGENTS.override.md` masks `AGENTS.md`. Rename or remove the override if it is not intentional.
- Truncated guidance: instructions near the end of a large chain disappear. Split guidance by directory or raise `project_doc_max_bytes` in the Codex profile.
- Sandbox mismatch: a non-shell tool can perform actions outside Codex shell sandbox expectations. Enforce permissions in the tool server and OpenClaw approvals.
- Cache churn: putting changing context above stable guidance increases cache misses. Keep stable guidance first and generated context later.
